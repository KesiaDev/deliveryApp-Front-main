import 'dart:io';
import 'package:dio/dio.dart';

/// Exceção customizada para erros de API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;
  final dynamic originalError;
  final dynamic responseData; // Mudei para dynamic para aceitar String ou Map

  ApiException({
    required this.message,
    this.statusCode,
    this.endpoint,
    this.originalError,
    this.responseData,
  });

  /// Cria uma ApiException a partir de um DioError
  factory ApiException.fromDioError(DioException error) {
    String message;
    int? statusCode;
    dynamic responseData; // Mudei para dynamic para aceitar String ou Map

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Tempo de conexão expirado. Verifique sua internet.';
        break;
      case DioExceptionType.badResponse:
        statusCode = error.response?.statusCode;
        
        // Aceita String ou Map - tratamento seguro
        final rawData = error.response?.data;
        if (rawData != null) {
          // Se for String, mantém como String
          if (rawData is String) {
            responseData = rawData;
          } 
          // Se for Map, converte para Map<String, dynamic>
          else if (rawData is Map) {
            responseData = Map<String, dynamic>.from(rawData);
          } 
          // Qualquer outro tipo, converte para String
          else {
            responseData = rawData.toString();
          }
        } else {
          responseData = null;
        }
        
        // Tentar extrair mensagem da API primeiro
        final apiMessage = _extractErrorMessage(rawData);
        
        if (statusCode == 400) {
          // Erro 400 (Bad Request) - geralmente é erro de validação ou dados inválidos
          message = apiMessage ?? 'Dados inválidos. Verifique as informações e tente novamente.';
        } else if (statusCode == 401) {
          message = apiMessage ?? 'E-mail ou senha inválidos. Verifique suas credenciais.';
        } else if (statusCode == 403) {
          message = apiMessage ?? 'Acesso negado. Você não tem permissão para esta ação.';
        } else if (statusCode == 404) {
          message = apiMessage ?? 'Recurso não encontrado. Verifique a URL da API.';
        } else if (statusCode == 500) {
          message = apiMessage ?? 'Erro interno do servidor. Tente novamente mais tarde.';
        } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          message = apiMessage ?? 'Erro na requisição (${statusCode}). Verifique os dados enviados.';
        } else {
          message = apiMessage ?? 'Erro na requisição (${statusCode ?? 'desconhecido'})';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Requisição cancelada.';
        break;
      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          message = 'Sem conexão com a internet. Verifique sua rede.';
        } else {
          message = 'Erro desconhecido. Tente novamente.';
        }
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      endpoint: error.requestOptions.path,
      originalError: error,
      responseData: responseData,
    );
  }

  /// Extrai mensagem de erro do response da API
  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    
    if (data is Map) {
      return data['message'] as String? ?? 
             data['error'] as String? ?? 
             data['mensagem'] as String? ??
             data['msg'] as String?;
    }
    
    // Se for String direto, retorna ela
    if (data is String) {
      // Remove aspas se houver
      return data.trim().replaceAll('"', '').replaceAll("'", '');
    }
    
    return null;
  }

  /// Verifica se é um erro de autenticação (401)
  bool get isUnauthorized => statusCode == 401;

  /// Verifica se é um erro de permissão (403)
  bool get isForbidden => statusCode == 403;

  /// Verifica se é um erro de servidor (5xx)
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Verifica se é um erro de cliente (4xx)
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;

  @override
  String toString() => message;
}

