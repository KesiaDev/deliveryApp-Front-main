import 'package:delivery_front/core/errors/api_exception.dart';
import 'package:delivery_front/core/logger.dart';
import 'package:dio/dio.dart';

/// Handler centralizado para tratamento de erros
class ErrorHandler {
  ErrorHandler._();

  /// Trata um erro e retorna uma mensagem amigável para o usuário
  static String handleError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    // Loga o erro
    Logger.logError(
      error,
      stackTrace: stackTrace,
      meta: context,
      tag: 'ErrorHandler',
    );

    // Converte para ApiException se necessário
    final apiException = _convertToApiException(error);

    // Retorna mensagem amigável
    return apiException.message;
  }

  /// Converte diferentes tipos de erro para ApiException
  static ApiException _convertToApiException(Object error) {
    if (error is ApiException) {
      return error;
    }

    if (error is DioException) {
      return ApiException.fromDioError(error);
    }

    // Erro genérico
    return ApiException(
      message: _getFriendlyMessage(error),
      originalError: error,
    );
  }

  /// Retorna mensagem amigável para erros genéricos
  static String _getFriendlyMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socket') || errorString.contains('network') || 
        errorString.contains('connection')) {
      return 'Sem conexão com a internet. Verifique sua rede.';
    }

    if (errorString.contains('timeout')) {
      return 'Tempo de conexão expirado. Tente novamente.';
    }

    if (errorString.contains('format') || errorString.contains('json') ||
        errorString.contains('type') || errorString.contains('cast')) {
      return 'Erro ao processar resposta do servidor. Verifique se a API está funcionando.';
    }

    if (errorString.contains('null') || errorString.contains('no such method')) {
      return 'Erro ao processar dados do usuário. Tente novamente.';
    }

    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'E-mail ou senha inválidos. Verifique suas credenciais.';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Acesso negado. Verifique suas permissões.';
    }

    if (errorString.contains('500') || errorString.contains('server')) {
      return 'Erro no servidor. Tente novamente mais tarde.';
    }

    // Log do erro completo para debug
    Logger.logError(
      error,
      tag: 'ErrorHandler._getFriendlyMessage',
      message: 'Erro não mapeado: ${error.toString()}',
    );

    return 'Erro ao fazer login. Verifique suas credenciais e conexão.';
  }
}

