/// Configuração de níveis de log do aplicativo
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Configuração global de logging
class LogConfig {
  LogConfig._();

  /// Nível mínimo de log a ser exibido
  static LogLevel minLevel = LogLevel.debug;

  /// Se deve logar no console (debug)
  static bool enableConsoleLog = true;

  /// Se deve enviar logs para Sentry (produção)
  static bool enableSentry = false;

  /// Se deve incluir stack traces em logs de erro
  static bool includeStackTrace = true;

  /// Se deve mascarar dados sensíveis nos logs
  static bool maskSensitiveData = true;

  /// Campos que devem ser mascarados nos logs
  static const List<String> sensitiveFields = [
    'password',
    'senha',
    'token',
    'jwt',
    'authorization',
    'cpf',
    'cnpj',
    'cartao',
    'cvv',
  ];

  /// Mascara dados sensíveis em um mapa
  static Map<String, dynamic> maskSensitive(Map<String, dynamic>? data) {
    if (data == null || !maskSensitiveData) return data ?? {};
    
    final masked = Map<String, dynamic>.from(data);
    for (final field in sensitiveFields) {
      if (masked.containsKey(field)) {
        masked[field] = '***MASKED***';
      }
    }
    return masked;
  }
}

