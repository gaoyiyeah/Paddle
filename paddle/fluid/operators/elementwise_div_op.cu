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

#define EIGEN_USE_GPU
#include "paddle/fluid/operators/elementwise_div_op.h"
#include "paddle/fluid/platform/float16.h"

namespace ops = paddle::operators;
namespace plat = paddle::platform;

REGISTER_OP_CUDA_KERNEL(
    elementwise_div,
    ops::ElementwiseDivKernel<paddle::platform::CUDADeviceContext, float>,
    ops::ElementwiseDivKernel<paddle::platform::CUDADeviceContext, double>,
    ops::ElementwiseDivKernel<paddle::platform::CUDADeviceContext, int>,
    ops::ElementwiseDivKernel<paddle::platform::CUDADeviceContext, int64_t>,
    ops::ElementwiseDivKernel<paddle::platform::CUDADeviceContext,
                              plat::float16>);
REGISTER_OP_CUDA_KERNEL(
    elementwise_div_grad,
    ops::ElementwiseDivGradKernel<paddle::platform::CUDADeviceContext, float>,
    ops::ElementwiseDivGradKernel<paddle::platform::CUDADeviceContext, double>,
    ops::ElementwiseDivGradKernel<paddle::platform::CUDADeviceContext, int>,
    ops::ElementwiseDivGradKernel<paddle::platform::CUDADeviceContext, int64_t>,
    ops::ElementwiseDivGradKernel<paddle::platform::CUDADeviceContext,
                                  plat::float16>);
