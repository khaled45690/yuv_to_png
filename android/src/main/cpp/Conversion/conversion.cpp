
#include "conversion.h"

OutputpngImageStruct
yuv_to_png(uint8_t *ydata, int32_t yRowStride, uint8_t *udata, int32_t uRowStride, int32_t uPixelStride, uint8_t *vdata, int32_t vRowStride, int32_t width, int32_t height, bool isFrontCamera)
{
  int size_dest = width * height * 4;
  uint8_t *rawRGB = (uint8_t *)malloc(size_dest);
  libyuv::Android420ToARGB(ydata, yRowStride, udata, uRowStride, vdata, vRowStride, uPixelStride, rawRGB, width * 4, width, height);
  cv::Size actual_size(width, height);
  cv::Mat rawRGBMat(actual_size, CV_8UC4, rawRGB);
  if (isFrontCamera)
    cv::flip(rawRGBMat, rawRGBMat, 1);
  cv::rotate(rawRGBMat, rawRGBMat, cv::ROTATE_90_CLOCKWISE);
  std::vector<uchar> outputImage;
  cv::imencode(".png", rawRGBMat, outputImage);
  free(rawRGB);
  rawRGBMat.release();
  OutputpngImageStruct pngImage;

  // Initialize the fields
  pngImage.data = outputImage.data();
  pngImage.length = outputImage.size();
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
  libyuv::NV21ToARGB(src_y, width, src_vu, width, rawRGB, width * 4, width, height);

  cv::Size actual_size(width, height);
  cv::Mat rawRGBMat(actual_size, CV_8UC4, rawRGB);
  if (isFrontCamera)
    cv::flip(rawRGBMat, rawRGBMat, 1);
  cv::rotate(rawRGBMat, rawRGBMat, cv::ROTATE_90_CLOCKWISE);
  std::vector<uchar> outputImage;
  cv::imencode(".png", rawRGBMat, outputImage);
  free(rawRGB);
  rawRGBMat.release();
  OutputpngImageStruct pngImage;

  // Initialize the fields
  pngImage.data = outputImage.data();
  pngImage.length = outputImage.size();
  return pngImage;
}
