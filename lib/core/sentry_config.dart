import 'package:flutter/foundation.dart';

/// Configuração e inicialização do Sentry (opcional)
/// 
/// Para ativar o Sentry:
/// 1. Adicione a dependência no pubspec.yaml:
///    dependencies:
///      sentry_flutter: ^7.0.0
/// 
/// 2. Defina a variável de ambiente SENTRY_DSN no seu .env ou via --dart-define
/// 
/// 3. Chame SentryConfig.initialize() no main.dart antes de runApp()
class SentryConfig {
  SentryConfig._();

  static bool _isInitialized = false;

  /// Inicializa o Sentry se a DSN estiver configurada
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// await SentryConfig.initialize(
  ///   dsn: const String.fromEnvironment('SENTRY_DSN'),
  /// );
  /// ```
  static Future<void> initialize({String? dsn}) async {
    if (_isInitialized) return;
    
    // Se não houver DSN ou estiver em debug, não inicializa
    if (dsn == null || dsn.isEmpty || kDebugMode) {
      return;
    }

    try {
      // Descomente quando adicionar sentry_flutter:
      // await SentryFlutter.init(
      //   (options) {
      //     options.dsn = dsn;
      //     options.tracesSampleRate = 0.2; // 20% das transações
      //     options.environment = kReleaseMode ? 'production' : 'staging';
      //   },
      //   appRunner: () {
      //     // App será iniciado aqui
      //   },
      // );
      
      _isInitialized = true;
    } catch (e) {
      // Falha silenciosa - app continua funcionando sem Sentry
      debugPrint('Erro ao inicializar Sentry: $e');
    }
  }

  /// Verifica se o Sentry está inicializado
  static bool get isInitialized => _isInitialized;
}

