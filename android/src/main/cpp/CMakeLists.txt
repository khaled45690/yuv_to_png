
# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.18.1)

# Declares and names the project.

project("yuv_to_png")
add_compile_options(-fno-strict-aliasing)
#project("opencv")
#
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/OpenCV/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/Libyuv/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/libconversion/include)
add_library(libyuv SHARED IMPORTED)
add_library(libopencv SHARED IMPORTED)
add_library(libconversion SHARED IMPORTED)
set_target_properties(libyuv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/Libyuv/${ANDROID_ABI}/libyuv.so)
set_target_properties(libopencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/SharedLib/OpenCV/${ANDROID_ABI}/libopencv_java4.so)
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