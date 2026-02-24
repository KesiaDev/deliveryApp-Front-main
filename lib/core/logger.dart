import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:delivery_front/core/log_config.dart';

/// Sistema centralizado de logging do aplicativo
/// 
/// Fornece métodos para logar informações, warnings e erros
/// com suporte opcional a Sentry e mascaramento de dados sensíveis.
class Logger {
  Logger._();

  /// Loga uma mensagem informativa
  static void logInfo(
    String message, {
    Map<String, dynamic>? meta,
    String? tag,
  }) {
    if (LogConfig.minLevel.index > LogLevel.info.index) return;

    final maskedMeta = LogConfig.maskSensitive(meta);
    final logTag = tag ?? 'INFO';

    if (LogConfig.enableConsoleLog) {
      if (kDebugMode) {
        dev.log(
          message,
          name: logTag,
          error: maskedMeta?.isNotEmpty == true ? maskedMeta : null,
        );
      } else {
        print('[$logTag] $message');
        if (maskedMeta?.isNotEmpty == true) {
          print('Meta: $maskedMeta');
        }
      }
    }

    // TODO: Integrar com Sentry quando habilitado
    if (LogConfig.enableSentry && !kDebugMode) {
      // Sentry.captureMessage(message, level: SentryLevel.info);
    }
  }

  /// Loga um aviso
  static void logWarn(
    String message, {
    Map<String, dynamic>? meta,
    String? tag,
  }) {
    if (LogConfig.minLevel.index > LogLevel.warning.index) return;

    final maskedMeta = LogConfig.maskSensitive(meta);
    final logTag = tag ?? 'WARN';

    if (LogConfig.enableConsoleLog) {
      if (kDebugMode) {
        dev.log(
          message,
          name: logTag,
          level: 900, // Warning level
          error: maskedMeta?.isNotEmpty == true ? maskedMeta : null,
        );
      } else {
        print('[$logTag] $message');
        if (maskedMeta?.isNotEmpty == true) {
          print('Meta: $maskedMeta');
        }
      }
    }

    // TODO: Integrar com Sentry quando habilitado
    if (LogConfig.enableSentry && !kDebugMode) {
      // Sentry.captureMessage(message, level: SentryLevel.warning);
    }
  }

  /// Loga um erro com stack trace opcional
  static void logError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? meta,
    String? tag,
    String? message,
  }) {
    if (LogConfig.minLevel.index > LogLevel.error.index) return;

    final maskedMeta = LogConfig.maskSensitive(meta);
    final logTag = tag ?? 'ERROR';
    final errorMessage = message ?? error.toString();

    if (LogConfig.enableConsoleLog) {
      if (kDebugMode) {
        dev.log(
          errorMessage,
          name: logTag,
          error: error,
          stackTrace: LogConfig.includeStackTrace ? stackTrace : null,
        );
        if (maskedMeta?.isNotEmpty == true) {
          dev.log('Meta: $maskedMeta', name: logTag);
        }
      } else {
        print('[$logTag] $errorMessage');
        if (LogConfig.includeStackTrace && stackTrace != null) {
          print('Stack: $stackTrace');
        }
        if (maskedMeta?.isNotEmpty == true) {
          print('Meta: $maskedMeta');
        }
      }
    }

    // TODO: Integrar com Sentry quando habilitado
    if (LogConfig.enableSentry && !kDebugMode) {
      // Sentry.captureException(
      //   error,
      //   stackTrace: stackTrace,
      //   hint: Hint.withMap(maskedMeta ?? {}),
      // );
    }
  }

  /// Loga uma requisição HTTP (sem dados sensíveis)
  static void logRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParams,
    dynamic body,
    String? tag,
  }) {
    if (LogConfig.minLevel.index > LogLevel.debug.index) return;

    final maskedHeaders = LogConfig.maskSensitive(headers);
    final maskedBody = body is Map ? LogConfig.maskSensitive(body as Map<String, dynamic>?) : body;
    
    Logger.logInfo(
      '$method $url',
      meta: {
        'headers': maskedHeaders,
        'queryParams': queryParams,
        'body': maskedBody,
      },
      tag: tag ?? 'HTTP_REQUEST',
    );
  }

  /// Loga uma resposta HTTP
  static void logResponse({
    required String method,
    required String url,
    required int statusCode,
    Map<String, dynamic>? headers,
    dynamic body,
    String? tag,
  }) {
    if (LogConfig.minLevel.index > LogLevel.debug.index) return;

    final maskedHeaders = LogConfig.maskSensitive(headers);
    final maskedBody = body is Map ? LogConfig.maskSensitive(body as Map<String, dynamic>?) : body;
    
    final level = statusCode >= 400 ? LogLevel.error : LogLevel.info;
    final logMethod = level == LogLevel.error ? Logger.logError : Logger.logInfo;
    
    logMethod(
      '$method $url - Status: $statusCode',
      meta: {
        'headers': maskedHeaders,
        'body': maskedBody,
      },
      tag: tag ?? 'HTTP_RESPONSE',
    );
  }
}

