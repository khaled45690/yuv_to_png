
#include "conversion.h"
#include <chrono>  // For timing
#include <android/log.h>
#define STB_IMAGE_WRITE_IMPLEMENTATION  
#include "stb_image_write.h"

OutputpngImageStruct
yuv_to_png(uint8_t *ydata, int32_t yRowStride, uint8_t *udata, int32_t uRowStride, int32_t uPixelStride, uint8_t *vdata, int32_t vRowStride, int32_t width, int32_t height, bool isFrontCamera)
{
  auto start = std::chrono::high_resolution_clock::now();
  int size_dest = width * height * 4;
  uint8_t *rawRGB = (uint8_t *)malloc(size_dest);
  libyuv::Android420ToABGR(ydata, yRowStride, udata, uRowStride, vdata, vRowStride, uPixelStride, rawRGB, width * 4, width, height);
  int rotated_width = height;  
  int rotated_height = width;  
  uint8_t *rotatedRGB = (uint8_t *)malloc(size_dest);
  if (isFrontCamera){
    libyuv::ARGBRotate(rawRGB, width * 4 , rotatedRGB, rotated_width * 4 , width, -height , libyuv::RotationMode::kRotate270);
}else{
   libyuv::ARGBRotate(rawRGB, width * 4 , rotatedRGB, rotated_width * 4 , width, height , libyuv::RotationMode::kRotate90);
}

  std::vector<uint8_t> png_data;
  
  stbi_write_png_to_func(
      [](void* context, void* data, int size) {
          auto* vec = static_cast<std::vector<uint8_t>*>(context);
          vec->insert(vec->end(), (uint8_t*)data, (uint8_t*)data + size);
      },
      &png_data,
      rotated_width,     
      rotated_height,     
      4,                  
      rotatedRGB,         
      rotated_width * 4   
  );
  
OutputpngImageStruct pngImage;
  // Initialize the fields
  pngImage.data = png_data.data();
  pngImage.length = png_data.size();
  free(rawRGB);
  free(rotatedRGB);
  return pngImage;
}



OutputpngImageStruct
nv21_to_png(uint8_t *ydata, int32_t yRowStride, int32_t width, int32_t height, bool isFrontCamera)
{

  int size_dest = width * height * 4;
  uint8_t *rawRGB = (uint8_t *)malloc(size_dest);
  int uv_width = width / 2; // Chroma subsampling in NV21
  int uv_height = height / 2;

  const uint8_t *src_y = ydata; // Pointer to Y plane
  const uint8_t *src_vu = ydata + width * height;
  libyuv::NV21ToABGR(src_y, width, src_vu, width, rawRGB, width * 4, width, height);
  int rotated_width = height;  
  int rotated_height = width;  
  uint8_t *rotatedRGB = (uint8_t *)malloc(size_dest);
  if (isFrontCamera){
    libyuv::ARGBRotate(rawRGB, width * 4 , rotatedRGB, rotated_width * 4 , width, -height , libyuv::RotationMode::kRotate270);
}else{
   libyuv::ARGBRotate(rawRGB, width * 4 , rotatedRGB, rotated_width * 4 , width, height , libyuv::RotationMode::kRotate90);
}

  std::vector<uint8_t> png_data;
  
  stbi_write_png_to_func(
      [](void* context, void* data, int size) {
          auto* vec = static_cast<std::vector<uint8_t>*>(context);
          vec->insert(vec->end(), (uint8_t*)data, (uint8_t*)data + size);
      },
      &png_data,
      rotated_width,     
      rotated_height,     
      4,                  
      rotatedRGB,         
      rotated_width * 4   
  );
  
OutputpngImageStruct pngImage;
  // Initialize the fields
  pngImage.data = png_data.data();
  pngImage.length = png_data.size();
  free(rawRGB);
  free(rotatedRGB);
  return pngImage;
}
