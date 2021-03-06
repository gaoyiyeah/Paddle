/* Copyright (c) 2016 PaddlePaddle Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#include "paddle/fluid/operators/math/cross_entropy.h"
#include "paddle/fluid/platform/cuda_device_function.h"
#include "paddle/fluid/platform/cuda_primitives.h"
#include "paddle/fluid/platform/float16.h"

namespace paddle {
namespace operators {
namespace math {

template <typename T>
HOSTDEVICE T log(const T& val) {
  return std::log(val);
}

template <>
HOSTDEVICE platform::float16 log(const platform::float16& val) {
  // strage bug, hlog is not exists.
  return static_cast<float16>(0);
  // half tmp = static_cast<half>(val);
  // return static_cast<platform::float16>(hlog(tmp));
}

namespace {
template <typename T>
__global__ void CrossEntropyKernel(T* Y, const T* X, const int64_t* label,
                                   const int N, const int D) {
  for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < N;
       i += blockDim.x * gridDim.x) {
    PADDLE_ASSERT(label[i] >= 0 && label[i] < D);
    Y[i] = -math::TolerableValue<T>()(log(X[i * D + label[i]]));
  }
}

template <typename T>
__global__ void SoftCrossEntropyKernel(T* Y, const T* X, const T* label,
                                       const int class_num) {
  int tid = threadIdx.x;
  T val(0);

  int idx = blockIdx.x * class_num + tid;
  int end = blockIdx.x * class_num + class_num;
  for (; idx < end; idx += blockDim.x) {
    val += math::TolerableValue<T>()(log(X[idx])) * label[idx];
  }

  val = paddle::platform::reduceSum(val, tid, blockDim.x);
  if (threadIdx.x == 0) {
    Y[blockIdx.x] = -val;
  }
}
}  // namespace

using Tensor = framework::Tensor;

template <typename T>
class CrossEntropyFunctor<platform::CUDADeviceContext, T> {
 public:
  void operator()(const platform::CUDADeviceContext& ctx,
                  framework::Tensor* out, const framework::Tensor* prob,
                  const framework::Tensor* labels, bool softLabel) {
    const T* prob_data = prob->data<T>();
    T* loss_data = out->mutable_data<T>(ctx.GetPlace());

    int batch_size = prob->dims()[0];
    int class_num = prob->dims()[1];

    if (softLabel) {
      const T* label_data = labels->data<T>();
      int block = class_num > 512
                      ? 512
                      : pow(2, static_cast<int>(std::log2(class_num)));

      SoftCrossEntropyKernel<T><<<batch_size, block, 0, ctx.stream()>>>(
          loss_data, prob_data, label_data, class_num);
    } else {
      const int64_t* label_data = labels->data<int64_t>();
      int block = 512;
      int grid = (batch_size + block - 1) / block;
      CrossEntropyKernel<T><<<grid, block, 0, ctx.stream()>>>(
          loss_data, prob_data, label_data, batch_size, class_num);
    }
  }
};

template class CrossEntropyFunctor<platform::CUDADeviceContext, float>;
template class CrossEntropyFunctor<platform::CUDADeviceContext, double>;
template class CrossEntropyFunctor<platform::CUDADeviceContext,
                                   platform::float16>;
}  // namespace math
}  // namespace operators
}  // namespace paddle
