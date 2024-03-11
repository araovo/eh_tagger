import 'package:eh_tagger/src/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.tap(find.byIcon(Icons.book));
    await tester.pump();
  });
}
