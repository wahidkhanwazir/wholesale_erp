import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wholesale_app/app.dart';

void main() {
  testWidgets('GarmentFlowApp smoke test loads dashboard', (
    WidgetTester tester,
  ) async {
    // Configure desktop viewport for desktop ERP
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const GarmentFlowApp());
    await tester.pumpAndSettle();

    // Verify that the ERP brand name and dashboard elements are displayed
    expect(find.text('GarmentFlow ERP'), findsWidgets);
    expect(find.text("Today's Sales"), findsOneWidget);
    expect(find.text('Customer Receivables'), findsOneWidget);
    expect(find.text('Supplier Payables'), findsOneWidget);
  });
}
