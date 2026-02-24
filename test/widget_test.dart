// Teste básico de smoke do AppWidget
//
// Verifica que o app inicia corretamente sem erros

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_front/core/app_widget.dart';

void main() {
  testWidgets('AppWidget inicia sem erros', (WidgetTester tester) async {
    // Build app e aguarda primeiro frame
    await tester.pumpWidget(const AppWidget());
    await tester.pump();

    // Verifica que o MaterialApp foi criado
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
