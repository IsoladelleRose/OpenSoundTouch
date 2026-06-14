import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App boots and shows speakers screen', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenSoundTouchApp());
    await tester.pump();
    expect(find.text('OpenSoundTouch'), findsOneWidget);
  });
}
