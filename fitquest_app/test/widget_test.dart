import 'package:flutter_test/flutter_test.dart';
import 'package:fitquest_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FitQuestApp());
    expect(find.text('FITQUEST'), findsOneWidget);
  });
}
