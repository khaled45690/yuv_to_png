# YUV to PNG Example App

This example demonstrates the GPU-accelerated YUV to RGB/PNG conversion with real-time performance metrics.

## Features

### 🎮 GPU vs CPU Toggle

Switch between GPU-accelerated and CPU-based conversion in real-time to compare performance.

### 📊 Live Performance Metrics

- **Current conversion time** (ms)
- **Average conversion time** across all frames
- **Frame counter** to track processing
- **Color-coded display**: Green for GPU, Orange for CPU

### 🎥 Camera Format Support

- **YUV420** - Planar format (Camera2 API)
- **NV21** - Semi-planar format (Legacy Camera API)

## UI Overview

### Top Left Panel (Performance Stats)

```
Mode: GPU
GPU: 3ms (avg: 2.8ms)
Frames: 120
```

### Bottom Controls

- **GPU/CPU Button** - Toggle conversion method
- **Format Radio Buttons** - Select camera format (YUV420/NV21)

## Usage

### Run the App

```bash
cd example
flutter pub get
flutter run
```

### Test Performance

1. **Start with GPU** (default)
   - Watch the metrics: Should show ~2-5ms for 1080p
2. **Switch to CPU**
   - Tap the GPU/CPU button
   - Metrics reset and show CPU performance
   - Should show ~15-25ms for 1080p
3. **Compare Speedup**
   - Note the average times
   - GPU should be 5-8x faster

### Change Camera Format

- Select **YUV420** for Camera2 format
- Select **NV21** for legacy format
- Performance is similar for both on GPU

## Code Structure

### Main Components

#### Performance Tracking Variables

```dart
bool useGpu = true;          // GPU/CPU mode
int lastCpuTime = 0;         // Last CPU conversion time
int lastGpuTime = 0;         // Last GPU conversion time
double avgCpuTime = 0;       // Average CPU time
double avgGpuTime = 0;       // Average GPU time
int frameCount = 0;          // Frame counter
```

#### Conversion Logic

```dart
if (useGpu) {
  // GPU: Returns RGB888
  ConversionResult result = YuvToPng.yuvToRgbGpu(image);
  lastGpuTime = result.msTaken;
  avgGpuTime = (avgGpuTime * (frameCount - 1) + result.msTaken) / frameCount;
} else {
  // CPU: Returns PNG
  ConversionResult result = YuvToPng.yuvToPngTimed(image);
  lastCpuTime = result.msTaken;
  avgCpuTime = (avgCpuTime * (frameCount - 1) + result.msTaken) / frameCount;
}
```

## Expected Performance

### 1080p (1920×1080)

| Method  | Time (ms) | FPS     | Output |
| ------- | --------- | ------- | ------ |
| GPU     | 2-5       | 200-500 | RGB888 |
| CPU     | 15-25     | 40-66   | PNG    |
| Speedup | **5-8x**  |         |        |

### 720p (1280×720)

| Method  | Time (ms) | FPS      | Output |
| ------- | --------- | -------- | ------ |
| GPU     | 1-3       | 333-1000 | RGB888 |
| CPU     | 8-15      | 66-125   | PNG    |
| Speedup | **6-10x** |          |        |

## Key Differences

### GPU Mode

- ✅ 5-8x faster
- ✅ Zero CPU load (runs on GPU)
- ✅ Returns RGB888 raw data
- ⚠️ Requires OpenGL ES 3.0
- ⚠️ Image display not shown (for performance testing)

### CPU Mode

- ✅ Returns PNG (compressed)
- ✅ Works on all devices
- ✅ Image displayed on screen
- ⚠️ 5-8x slower
- ⚠️ High CPU load

## Troubleshooting

### GPU shows 0ms or crashes

**Solution**: Device doesn't support OpenGL ES 3.0

```bash
# Check device support
adb shell dumpsys SurfaceFlinger | grep GLES
```

### No performance difference

**Solution**: Check you're in release mode

```bash
flutter run --release
```

### High GPU times

**Solution**: Resolution may be too high

- Try lower resolution: `ResolutionPreset.medium` or `ResolutionPreset.low`

## Logs

Monitor conversion in real-time:

```bash
# Watch GPU logs
adb logcat | grep YUV_GL

# Example output:
# D/YUV_GL: OpenGL ES 3.0 context created successfully
# D/YUV_GL: GPU conversion complete: 1080x1920 RGB888, 6220800 bytes, 3ms
```

## Performance Tips

### For Best Results

1. **Use Release Build**: `flutter run --release`
2. **Warm Up**: First few frames may be slower
3. **Steady State**: Average after 30+ frames is most accurate
4. **Background Apps**: Close other apps for consistent metrics

### Frame Sampling

The app processes every 6th frame to prevent UI freezing:

```dart
if (counter > 5 && controller != null) {
  counter = 0;
  // Process frame
}
```

Adjust this value to process more/fewer frames.

## Advanced Usage

### Custom Performance Test

```dart
void runPerformanceTest(CameraImage image) async {
  // Test GPU
  final gpuResults = <int>[];
  for (int i = 0; i < 100; i++) {
    final result = YuvToPng.yuvToRgbGpu(image);
    gpuResults.add(result.msTaken);
  }

  // Test CPU
  final cpuResults = <int>[];
  for (int i = 0; i < 100; i++) {
    final result = YuvToPng.yuvToPngTimed(image);
    cpuResults.add(result.msTaken);
  }

  // Calculate statistics
  final avgGpu = gpuResults.reduce((a, b) => a + b) / gpuResults.length;
  final avgCpu = cpuResults.reduce((a, b) => a + b) / cpuResults.length;

  print('GPU Average: ${avgGpu.toStringAsFixed(2)}ms');
  print('CPU Average: ${avgCpu.toStringAsFixed(2)}ms');
  print('Speedup: ${(avgCpu / avgGpu).toStringAsFixed(1)}x');
}
```

## Architecture

```
Camera Frame (YUV)
    ↓
Toggle: GPU or CPU?
    ↓
GPU Path (useGpu=true)          CPU Path (useGpu=false)
    ↓                               ↓
YuvToPng.yuvToRgbGpu()         YuvToPng.yuvToPngTimed()
    ↓                               ↓
RGB888 + timing                 PNG + timing
    ↓                               ↓
Update GPU metrics              Update CPU metrics
    ↓                               ↓
Skip display                    Display image
```

## Testing

Run unit tests:

```bash
cd example
flutter test
```

Tests verify:

- ConversionResult structure
- Timing field presence
- GPU/CPU flag correctness

## Next Steps

1. **Add PNG encoding for GPU path** - Use `image` package to encode RGB888
2. **Persistent GPU context** - Reuse OpenGL context for 2x speedup
3. **Batch processing** - Process multiple frames in one GPU call
4. **ML Integration** - Pass RGB888 directly to TensorFlow Lite

## Dependencies

```yaml
dependencies:
  yuv_to_png: ^1.0.0
  camera: ^0.11.0
  image: ^4.0.0 # For PNG encoding
```

## License

See parent package LICENSE file.
