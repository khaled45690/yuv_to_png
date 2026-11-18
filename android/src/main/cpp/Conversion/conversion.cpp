
#include "conversion.h"
#include <chrono>  // For timing
#include <cstdlib>
#include <cstring>
#include <vector>
#include <android/log.h>
#define STB_IMAGE_WRITE_IMPLEMENTATION  
#include "stb_image_write.h"

// Encodes tightly packed RGBA pixels as PNG into a malloc'd buffer owned by the
// caller (release with free_png_buffer). On failure data is nullptr, length 0.
static OutputpngImageStruct encode_png(const uint8_t *rgba, int width, int height)
{
  OutputpngImageStruct result = {nullptr, 0};
  std::vector<uint8_t> png_data;

  int ok = stbi_write_png_to_func(
      [](void *context, void *data, int size) {
        auto *vec = static_cast<std::vector<uint8_t> *>(context);
        vec->insert(vec->end(), (uint8_t *)data, (uint8_t *)data + size);
      },
      &png_data,
      width,
      height,
      4,
      rgba,
      width * 4);
  if (!ok || png_data.empty())
    return result;

  // png_data is destroyed when this function returns, so hand out a copy.
  uint8_t *out = (uint8_t *)malloc(png_data.size());
  if (out == nullptr)
    return result;
  memcpy(out, png_data.data(), png_data.size());
  result.data = out;
  result.length = (int32_t)png_data.size();
  return result;
}

void free_png_buffer(uint8_t *data)
{
  free(data);
}

OutputpngImageStruct
yuv_to_png(uint8_t *ydata, int32_t yRowStride, uint8_t *udata, int32_t uRowStride, int32_t uPixelStride, uint8_t *vdata, int32_t vRowStride, int32_t width, int32_t height, bool isFrontCamera)
{
  OutputRgbImageStruct rgb = yuv_to_rgb(ydata, yRowStride, udata, uRowStride, uPixelStride, vdata, vRowStride, width, height, isFrontCamera);
  if (rgb.data == nullptr)
    return OutputpngImageStruct{nullptr, 0};
  OutputpngImageStruct png = encode_png(rgb.data, rgb.width, rgb.height);
  free_rgb_buffer(rgb.data);
  return png;
}

OutputpngImageStruct
nv21_to_png(uint8_t *ydata, int32_t yRowStride, int32_t width, int32_t height, bool isFrontCamera)
{
  if (width <= 0 || height <= 0)
    return OutputpngImageStruct{nullptr, 0};

  const size_t size_dest = (size_t)width * (size_t)height * 4;
  uint8_t *rawRGB = (uint8_t *)malloc(size_dest);
  uint8_t *rotatedRGB = (uint8_t *)malloc(size_dest);
  if (rawRGB == nullptr || rotatedRGB == nullptr)
  {
    free(rawRGB);
    free(rotatedRGB);
    return OutputpngImageStruct{nullptr, 0};
  }

  const uint8_t *src_y = ydata;                  // Y plane
  const uint8_t *src_vu = ydata + width * height; // interleaved VU plane
  int status = libyuv::NV21ToABGR(src_y, width, src_vu, width, rawRGB, width * 4, width, height);

  const int rotated_width = height;
  if (status == 0)
  {
    if (isFrontCamera)
      status = libyuv::ARGBRotate(rawRGB, width * 4, rotatedRGB, rotated_width * 4, width, -height, libyuv::RotationMode::kRotate270);
    else
      status = libyuv::ARGBRotate(rawRGB, width * 4, rotatedRGB, rotated_width * 4, width, height, libyuv::RotationMode::kRotate90);
  }
  free(rawRGB);

  OutputpngImageStruct png = {nullptr, 0};
  if (status == 0)
    png = encode_png(rotatedRGB, rotated_width, width);
  free(rotatedRGB);
  return png;
}

// Converts an Android YUV_420_888 camera frame to a rotated RGBA8888 buffer
// (bytes are R, G, B, A with A = 255). No PNG encoding is performed.
// The returned buffer is allocated with malloc and must be released with
// free_rgb_buffer(). On failure `data` is nullptr and `length` is 0.
OutputRgbImageStruct
yuv_to_rgb(uint8_t *ydata, int32_t yRowStride, uint8_t *udata, int32_t uRowStride, int32_t uPixelStride, uint8_t *vdata, int32_t vRowStride, int32_t width, int32_t height, bool isFrontCamera)
{
  OutputRgbImageStruct result = {nullptr, 0, 0, 0};
  if (width <= 0 || height <= 0)
    return result;

  const size_t size_dest = (size_t)width * (size_t)height * 4;
  uint8_t *rawRGB = (uint8_t *)malloc(size_dest);
  uint8_t *rotatedRGB = (uint8_t *)malloc(size_dest);
  if (rawRGB == nullptr || rotatedRGB == nullptr)
  {
    free(rawRGB);
    free(rotatedRGB);
    return result;
  }

  // libyuv "ABGR" is the byte order R, G, B, A in memory.
  int status = libyuv::Android420ToABGR(ydata, yRowStride, udata, uRowStride, vdata, vRowStride, uPixelStride, rawRGB, width * 4, width, height);

  // The camera sensor is landscape: rotate to portrait (width and height swap).
  const int rotated_width = height;
  const int rotated_height = width;
  if (status == 0)
  {
    if (isFrontCamera)
    {
      // A negative height flips the source vertically (mirror for the selfie camera).
      status = libyuv::ARGBRotate(rawRGB, width * 4, rotatedRGB, rotated_width * 4, width, -height, libyuv::RotationMode::kRotate270);
    }
    else
    {
      status = libyuv::ARGBRotate(rawRGB, width * 4, rotatedRGB, rotated_width * 4, width, height, libyuv::RotationMode::kRotate90);
    }
  }

  free(rawRGB);
  if (status != 0)
  {
    free(rotatedRGB);
    return result;
  }

  result.data = rotatedRGB;
  result.length = (int32_t)size_dest;
  result.width = rotated_width;
  result.height = rotated_height;
  return result;
}

void free_rgb_buffer(uint8_t *data)
{
  free(data);
}
