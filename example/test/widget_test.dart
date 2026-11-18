import 'package:flutter_test/flutter_test.dart';
import 'package:yuv_to_png_example/main.dart';

void main() {
  testWidgets('shows the controls and warns when there is no camera', (
    tester,
  ) async {
    await tester.pumpWidget(const YuvLabApp(cameras: []));

    expect(find.text('YUV Lab'), findsWidgets);
    expect(find.text('Native PNG'), findsOneWidget);
    expect(find.text('Raw RGB'), findsOneWidget);
    expect(find.text('RGB → PNG (Dart)'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('No camera found on this device'), findsOneWidget);
  });

  testWidgets('NV21 falls back to the native PNG pipeline', (tester) async {
    await tester.pumpWidget(const YuvLabApp(cameras: []));
    await tester.tap(find.text('NV21'));
    await tester.pumpAndSettle();
    expect(find.text('Raw RGB is available for YUV420 only.'), findsOneWidget);
  });
}
