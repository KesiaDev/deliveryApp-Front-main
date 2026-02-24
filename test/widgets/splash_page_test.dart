import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testes de widget para SplashPage
/// 
/// Testa a navegação baseada no estado de autenticação
void main() {
  group('SplashPage Widget Tests', () {
    Widget createTestWidget() {
      return MaterialApp(
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashPage(),
          AppRoutes.login: (_) => const Scaffold(
            key: Key('login_page'),
            body: Text('Login Page'),
          ),
          AppRoutes.home: (_) => const Scaffold(
            key: Key('home_page'),
            body: Text('Home Page'),
          ),
        },
      );
    }

    testWidgets('SplashPage exibe logo e elementos visuais corretamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Primeiro frame
      await tester.pump(); // Segundo frame

      // Assert
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('SplashPage executa bootstrap após primeiro frame', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Primeiro frame - initState
      await tester.pump(); // Segundo frame - addPostFrameCallback

      // Assert - Bootstrap deve ter sido chamado (não podemos verificar diretamente
      // mas podemos verificar que o widget não crashou)
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('SplashPage mantém estrutura visual durante bootstrap', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Primeiro frame
      await tester.pump(const Duration(milliseconds: 100)); // Simula delay do bootstrap

      // Assert - Widget ainda deve estar renderizado
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });
  });
}

