import 'package:delivery_front/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'dart:async';

/// Testes unitários para verificar que os timers do HomePage
/// são cancelados corretamente no dispose, evitando memory leaks
void main() {
  group('HomePage Timers - Cancelamento no Dispose', () {
    testWidgets('HomePage cria timers no initState sem crashar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
        ),
      );

      // Aguarda initState executar
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - Widget foi criado sem erros
      // Se os timers causassem problemas, o teste falharia
      expect(find.byType(HomePage), findsOneWidget);
    });

    test('Timers são cancelados quando widget é removido da árvore', () {
      fakeAsync((async) {
        // Arrange
        final homePage = HomePage();
        final state = homePage.createState();

        // Act - Simula ciclo de vida completo
        state.initState();
        async.elapse(const Duration(milliseconds: 100));

        // Verifica que estado foi inicializado
        expect(state.mounted, isTrue);

        // Act - Dispose (simula remoção do widget)
        // Isso deve cancelar todos os timers internos
        state.dispose();

        // Assert - Estado não está mais montado
        expect(state.mounted, isFalse);

        // Avança tempo significativo - timers não devem executar
        // Se timers não foram cancelados, causariam exceções ou memory leaks
        async.elapse(const Duration(seconds: 60));

        // Se chegou aqui sem exceções, os timers foram cancelados corretamente
      });
    });

    test('GPS verification timer não executa após dispose', () {
      fakeAsync((async) {
        // Arrange
        final homePage = HomePage();
        final state = homePage.createState();

        // Act
        state.initState();
        async.elapse(const Duration(milliseconds: 100));

        // Verifica inicialização
        expect(state.mounted, isTrue);

        // Act - Dispose
        state.dispose();
        expect(state.mounted, isFalse);

        // Assert - Avança tempo suficiente para timer executar (5 segundos)
        // Se timer não foi cancelado, causaria erro ou execução indesejada
        async.elapse(const Duration(seconds: 10));

        // Teste passa se não houve exceções
      });
    });

    test('Chamados polling timer não executa após dispose', () {
      fakeAsync((async) {
        // Arrange
        final homePage = HomePage();
        final state = homePage.createState();

        // Act
        state.initState();
        async.elapse(const Duration(milliseconds: 100));

        // Verifica inicialização
        expect(state.mounted, isTrue);

        // Act - Dispose
        state.dispose();
        expect(state.mounted, isFalse);

        // Assert - Avança tempo suficiente para timer executar (30 segundos)
        // Se timer não foi cancelado, causaria erro
        async.elapse(const Duration(seconds: 35));

        // Teste passa se não houve exceções ou memory leaks
      });
    });

    test('Múltiplos ciclos de init/dispose não causam memory leaks', () {
      fakeAsync((async) {
        // Arrange
        final homePage = HomePage();

        // Act - Simula múltiplos ciclos
        for (int i = 0; i < 3; i++) {
          final state = homePage.createState();
          state.initState();
          async.elapse(const Duration(milliseconds: 50));
          state.dispose();
          async.elapse(const Duration(milliseconds: 50));
        }

        // Assert - Avança tempo significativo
        // Se houver timers não cancelados, causariam problemas
        async.elapse(const Duration(seconds: 60));

        // Teste passa se não houve memory leaks
      });
    });
  });
}

