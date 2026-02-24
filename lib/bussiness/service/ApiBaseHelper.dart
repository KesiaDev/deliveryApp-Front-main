import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:dio/dio.dart';

/// Stream controller para eventos de autenticação (401)
final _authErrorController = StreamController<bool>.broadcast();

/// Stream de erros de autenticação (401)
/// 
/// Escute este stream para detectar quando o usuário precisa fazer login novamente
Stream<bool> get authErrorStream => _authErrorController.stream;

class ApiBaseHelper {
  // static String baseUrl = "https://uber.appminhaescola.com.br/BemWS/ws";
  static String baseUrl = "https://api.foolentregas.com.br/v1";
  //static String baseUrl = "http://192.168.1.104:8080/v1";

  static bool isBluetoohPareado = false;
  static bool isPipAtivado = false;
  static bool buscaNotificacoesChamado = false;
  static StreamController streamController = StreamController<bool>.broadcast();

  static Usuario? userSessao = new Usuario();

  static const int IND_TIP_PERFIL_1_MOTORISTA = 1;
  static const int IND_TIP_PERFIL_2_EMPRESA = 2;
  static const int IND_TIP_PERFIL_99_ADMIN_SISTEMA = 99;

  static double lat = 0;
  static double long = 0;

  static const int IND_STATUS_CORRIDA_0_NOVA_CORRIDA = 0;
  //Motorista aceita
  static const int IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA = 1;
  //Empresa dá o inicio da corrida/motorista tbm
  static const int IND_STATUS_CORRIDA_2_EM_ANDAMENTO = 2;
  //Motorista conclui
  static const int IND_STATUS_CORRIDA_3_CONCLUIDA = 3;
  static const int IND_STATUS_CORRIDA_4_CANCELADA = 4;

  static const int IND_TIPO_CARTAO = 1;
  static const int IND_TIPO_DINHEIRO = 2;
  static const int IND_TIPO_PIX = 3;

  static const String GEO_KEY = "AIzaSyBJ-GzLkdL3BUc9TJd1ZdrDdF_NV8Y9JN8";

  static Dio? _dioInstance;

  /// Obtém instância do Dio com interceptors configurados
  static Dio get dio {
    if (_dioInstance == null) {
      _dioInstance = Dio(_createBaseOptions());
      _dioInstance!.interceptors.add(_createLoggingInterceptor());
      _dioInstance!.interceptors.add(_createAuthInterceptor());
      _dioInstance!.interceptors.add(_createErrorInterceptor());
    }
    return _dioInstance!;
  }

  /// Atualiza o token de autenticação
  static void updateAuthToken(String? token) {
    if (_dioInstance != null) {
      _dioInstance!.options.headers[HttpHeaders.authorizationHeader] =
          token != null ? "Bearer $token" : "";
    }
  }

  /// Cria as opções base do Dio
  static BaseOptions _createBaseOptions() {
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        HttpHeaders.contentTypeHeader: "application/json",
        HttpHeaders.authorizationHeader:
            (userSessao?.jwt != null ? "Bearer ${userSessao!.jwt}" : ""),
      },
    );
  }

  /// Interceptor para logging de requisições/respostas
  static Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        Logger.logRequest(
          method: options.method,
          url: '${options.baseUrl}${options.path}',
          headers: options.headers,
          queryParams: options.queryParameters,
          body: options.data,
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        Logger.logResponse(
          method: response.requestOptions.method,
          url: '${response.requestOptions.baseUrl}${response.requestOptions.path}',
          statusCode: response.statusCode ?? 0,
          headers: response.headers.map,
          body: response.data,
        );
        handler.next(response);
      },
      onError: (error, handler) {
        Logger.logError(
          error,
          meta: {
            'url': '${error.requestOptions.baseUrl}${error.requestOptions.path}',
            'method': error.requestOptions.method,
          },
          tag: 'HTTP_ERROR',
        );
        handler.next(error);
      },
    );
  }

  /// Interceptor para tratamento de erros 401 (autenticação)
  static Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          Logger.logWarn(
            'Sessão expirada - emitindo evento de logout',
            tag: 'AUTH_INTERCEPTOR',
          );
          _authErrorController.add(true);
        }
        handler.next(error);
      },
    );
  }

  /// Interceptor para converter erros em ApiException
  static Interceptor _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        // O erro já vem como DioException do Dio 5.x
        // Não precisamos converter novamente, apenas passar adiante
        handler.next(error);
      },
    );
  }

  /// Opções base (mantido para compatibilidade)
  static BaseOptions get options => _createBaseOptions();

  static setBuscaNovosChamados(bool novo) {
    streamController.sink.add(novo);
  }

  static String getDtaFormatada(DateTime? dta) {
    if (dta != null) {
      DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
      return formatter.format(dta);
    }
    return "";
  }

  static String getDtaFormatadaSemHora(DateTime? dta) {
    if (dta != null) {
      DateFormat formatter = DateFormat('dd/MM/yyyy');
      return formatter.format(dta);
    }
    return "";
  }

  static String getDtaFormatadaSemHoraApi(DateTime? dta) {
    if (dta != null) {
      DateFormat formatter = DateFormat('yyyy/MM/dd');
      return formatter.format(dta);
    }
    return "";
  }

  /// Find the first date of the week which contains the provided date.
  static DateTime findFirstDateOfTheWeek(DateTime dateTime) {
    return dateTime.subtract(Duration(days: dateTime.weekday - 1));
  }

  /// Find last date of the week which contains provided date.
  static DateTime findLastDateOfTheWeek(DateTime dateTime) {
    return dateTime
        .add(Duration(days: DateTime.daysPerWeek - dateTime.weekday));
  }

  static DateTime findFirstDateOfTheMonth(DateTime dateTime) {
    return new DateTime(dateTime.year, dateTime.month, 1);
  }

  /// The last day of a given month
  static DateTime lastDayOfMonth(DateTime date) {
    return new DateTime(date.year, date.month + 1, 0);
  }
}
