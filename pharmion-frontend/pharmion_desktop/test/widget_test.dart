import 'package:flutter_test/flutter_test.dart';
import 'package:pharmion_desktop/main.dart';

void main() {
  testWidgets('Pharmion smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PharmionApp());
  });
}