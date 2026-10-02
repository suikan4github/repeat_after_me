// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repeat_after_me/main.dart';

void main() {
  testWidgets('shows the audio library and search empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Your audio library'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('No audio files yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No matches found'), findsOneWidget);
  });
}
