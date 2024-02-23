
# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.18.1)

# Declares and names the project.


project("yuv_to_png")
add_compile_options(-fno-strict-aliasing)

# to check if the lib files doesn't exist
if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/OpenCV/${ANDROID_ABI}/libopencv_java4.so) 
# will download the files
file(DOWNLOAD
https://raw.githubusercontent.com/khaled45690/yuv_to_png/main/android/src/main/cpp/src/SharedLib/OpenCV/${ANDROID_ABI}/libopencv_java4.so
${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/OpenCV/${ANDROID_ABI}/libopencv_java4.so
    SHOW_PROGRESS
)
endif()
# to check if the lib files doesn't exist
if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/Libyuv/${ANDROID_ABI}/libyuv.so) 
# will download the files
file(DOWNLOAD
https://raw.githubusercontent.com/khaled45690/yuv_to_png/main/android/src/main/cpp/src/SharedLib/Libyuv/${ANDROID_ABI}/libyuv.so
${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/Libyuv/${ANDROID_ABI}/libyuv.so
    SHOW_PROGRESS
)
endif()
# to check if the lib files doesn't exist
if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/libconversion/${ANDROID_ABI}/libconversion.so) 
# will download the files
file(DOWNLOAD
https://raw.githubusercontent.com/khaled45690/yuv_to_png/main/android/src/main/cpp/src/SharedLib/libconversion/${ANDROID_ABI}/libconversion.so
${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/libconversion/${ANDROID_ABI}/libconversion.so
    SHOW_PROGRESS
)
endif()
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/OpenCV/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/Libyuv/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/libconversion/include)
add_library(libyuv SHARED IMPORTED)
add_library(libopencv SHARED IMPORTED)
add_library(libconversion SHARED IMPORTED)
set_target_properties(libyuv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/Libyuv/${ANDROID_ABI}/libyuv.so)
set_target_properties(libopencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/OpenCV/${ANDROID_ABI}/libopencv_java4.so)
# ExternalProject_Add(
#     bunny
#     PREFIX "demo"
#     URL http://graphics.stanford.edu/pub/3Dscanrep/bunny.tar.gz
#     URL_HASH SHA512=59e7b43db838dbe6f02fda5e844d18e190d32d2ca1a83dc9f6b1aaed43e0340fc1e8ecabed6fffdac9f85bd34e7e93b5d8a17283d59ea3c14977a0372785d2bd
#     CONFIGURE_COMMAND ""
#     BUILD_COMMAND ""
#     INSTALL_COMMAND ""
# )
set_target_properties(libconversion PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/libconversion/${ANDROID_ABI}/libconversion.so)



add_library( # Sets the name of the library.
        yuv_to_png

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
        yuv_to_png.cpp
        )




find_library( # Sets the name of the path variable.
              log-lib

              # Specifies the name of the NDK library that
              # you want CMake to locate.
              log )

# Specifies libraries CMake should link to your target library. You
# can link multiple libraries, such as libraries you define in this
# build script, prebuilt third-party libraries, or system libraries.

target_link_libraries( # Specifies the target library.
                        yuv_to_png
                       # Links the target library to the log library
                       # included in the NDK.
                        android
                        mediandk
                        libopencv
                        libyuv
                        libconversion
                       ${log-lib} )