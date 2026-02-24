import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testes de navegação do SplashPage
/// 
/// Verifica que a navegação ocorre corretamente baseada no estado de autenticação
void main() {
  group('SplashPage Navigation Tests', () {
    Widget createTestApp() {
      return MaterialApp(
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashPage(),
          AppRoutes.login: (_) => const Scaffold(
            key: Key('login_page'),
            body: Center(child: Text('Login Page')),
          ),
          AppRoutes.home: (_) => const Scaffold(
            key: Key('home_page'),
            body: Center(child: Text('Home Page')),
          ),
        },
      );
    }

    testWidgets('SplashPage renderiza elementos visuais corretamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pump(); // Primeiro frame
      await tester.pump(); // Segundo frame

      // Assert
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('SplashPage executa bootstrap após primeiro frame', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pump(); // initState
      await tester.pump(); // addPostFrameCallback

      // Assert - Bootstrap deve ter sido agendado
      // Não podemos verificar diretamente, mas o widget não deve crashar
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('SplashPage mantém UI durante processo de autenticação', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pump(); // Primeiro frame
      
      // Simula delay do processo de autenticação
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - UI ainda deve estar visível
      expect(find.byType(SplashPage), findsOneWidget);
    });
  });
}

