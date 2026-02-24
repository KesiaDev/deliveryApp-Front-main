import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Teste de integração do fluxo de autenticação
/// 
/// Testa a navegação completa do SplashPage baseado no estado de autenticação
void main() {
  group('Fluxo de Autenticação', () {
    testWidgets('Fluxo completo: Splash -> Login quando não autenticado', (WidgetTester tester) async {
      // Arrange - Cria app com rotas configuradas
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashPage(),
            AppRoutes.login: (_) => const Scaffold(
              key: Key('login_page'),
              body: Text('Login'),
            ),
            AppRoutes.home: (_) => const Scaffold(
              key: Key('home_page'),
              body: Text('Home'),
            ),
          },
        ),
      );

      // Act - Aguarda inicialização e navegação
      await tester.pump(); // Primeiro frame
      await tester.pumpAndSettle(const Duration(seconds: 3)); // Aguarda bootstrap

      // Assert - Deve estar na página de login
      // Nota: Este teste pode falhar se o mock não estiver configurado corretamente
      // Em um ambiente real, você mockaria o LoginController
      expect(find.byKey(const Key('login_page')).hitTestable(), findsAny);
    });
  });
}

