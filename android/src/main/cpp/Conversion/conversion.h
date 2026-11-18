#include <string>
#include <stdint.h>
#include <cstdio>
#include <chrono>
#include "libyuv/rotate.h"
#include "libyuv.h"

struct OutputpngImageStruct
{
  uint8_t *data;
  int32_t length;
};

OutputpngImageStruct
yuv_to_png(uint8_t *ydata, int32_t yRowStride, uint8_t *udata, int32_t uRowStride, int32_t uPixelStride, uint8_t *vdata, int32_t vRowStride, int32_t width, int32_t height, bool isFrontCamera);



OutputpngImageStruct
nv21_to_png(uint8_t *ydata, int32_t yRowStride, int32_t width, int32_t height, bool isFrontCamera);

// Raw RGBA8888 image (4 bytes per pixel, rows are tightly packed).
// `data` is owned by the caller and must be released with free_rgb_buffer().
struct OutputRgbImageStruct
{
  uint8_t *data;
  int32_t length;
  int32_t width;
  int32_t height;
};

OutputRgbImageStruct
yuv_to_rgb(uint8_t *ydata, int32_t yRowStride, uint8_t *udata, int32_t uRowStride, int32_t uPixelStride, uint8_t *vdata, int32_t vRowStride, int32_t width, int32_t height, bool isFrontCamera);

void free_rgb_buffer(uint8_t *data);

// Releases a buffer returned in OutputpngImageStruct::data.
void free_png_buffer(uint8_t *data);
