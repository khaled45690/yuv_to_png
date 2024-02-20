//
// Created by khaled on 7/3/2022.
//
#include <string>
#include <stdint.h>
#include <cstdio>
#include <chrono>

#include "libconversion.h"

extern "C" __attribute__((visibility("default"))) __attribute__((used))
OutputpngImageStruct
yuvToPng(uint8_t *ydata, int32_t yRowStride, uint8_t *udata, int32_t uRowStride, int32_t uPixelStride, uint8_t *vdata, int32_t vRowStride, int32_t width, int32_t height, bool isFrontCamera)
{
  return yuv_to_png(ydata, yRowStride, udata,  uRowStride,  uPixelStride, vdata,  vRowStride,  width,  height, isFrontCamera);
}


extern "C" __attribute__((visibility("default"))) __attribute__((used))
OutputpngImageStruct nv21ToPng(uint8_t *ydata, int32_t yRowStride, int32_t width, int32_t height, bool isFrontCamera)
{
  return  nv21_to_png(ydata, yRowStride, width, height, isFrontCamera);
}
