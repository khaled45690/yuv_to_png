# yuv_to_png

A new Flutter plugin project that converts YUV image data to PNG image. 

## Overview

This package provides a Flutter plugin to convert YUV image data into PNG image format. 

## Usage

To use this plugin:

1. install and import the plugin
2. Call `YuvToPng.yuvToPng` method passing the CameraImage variable
3. it will handle the conversion and identification of the image formate and returns a `Uint8List` containing PNG image data

For example:

```dart
    Uint8List png = YuvToPng.yuvToPng(cameraImage,
    lensDirection: lensDirection);
```

if there is an error you can use the next function to check if 
the image data is corrupted or not

```dart
        await precacheImage(Image.memory(imagedata).image, context,
        onError: (exception, stackTrace) {
      print('Failed to load image: $exception');
      imageRendered = false;
    });

```

if image data is corrupted you could simply use recurssion untill
we get correct image data

The PNG data can then be used to display the image in Flutter using `Image.memory()` or as shown in the example application.
## Optional
if you feel like buying me a coffe this will help me add more functions in the future like
- image cropping
- InputImage datatype to png

here is my wallet address for USDT Tron network

```dart
        TNQU1HjLtKyUHkQZpipkFWFPBHyWL7bjrs
    
```
here is my wallet address for Bitcoin network
```dart
        1AEabtDkpUS11gnBAnhJYLtkLPxeUYzT48
    
```

## Note

please note that lensDirection effect the image rotation correction which might effect the image orientation if neglected


It includes platform-specific implementation code for Android only as this from my knowledge happens only in Android systems . 

The plugin takes in CameraImage image data in both yuv240 and nv21 and returns a PNG image in uint8;ist . This allows you to process camera frames, video frames etc captured natively in YUV format and convert them to PNG that can be displayed in Flutter when needed.


if you have further questions feel free to connect and ask me on   <a href="https://www.linkedin.com/in/khaled-saad-3b94b817b/"><img src="https://raw.githubusercontent.com/edent/SuperTinyIcons/master/images/svg/linkedin.svg" width="20" height="20"></a>







