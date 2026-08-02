import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webalert/app.dart';

void main() {
  testWidgets('App boots to splash screen without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const WeBAlertApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('WeBAlert'), findsWidgets);
  });
}
