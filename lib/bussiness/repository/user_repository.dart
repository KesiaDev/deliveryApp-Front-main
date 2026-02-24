import 'dart:convert';
import 'dart:developer';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/shared/components/customException.dart';
import 'package:delivery_front/shared/models/DadosCorrida.dart';
import 'package:delivery_front/shared/models/SaldosCorrida.dart';
import 'package:delivery_front/shared/models/cadastroCemRequest.dart';
import 'package:delivery_front/shared/models/consultaRequest.dart';
import 'package:delivery_front/shared/models/loginRequest.dart';
import 'package:delivery_front/shared/models/recuperacao_senha_request.dart';
import 'package:delivery_front/shared/models/alteracao_senha_request.dart';
import 'package:delivery_front/shared/models/motorista/lista_cem.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_motoristas_proximos.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes_motorista.dart';
import 'package:delivery_front/shared/models/motorista/models/motoristas_proximos.dart';
import 'package:delivery_front/shared/models/motorista/motorista_cem.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class UserRepository {
  final _dio = ApiBaseHelper.dio;

  Future<Usuario> autenticaUser(
      String? email, String? senha, LoginRequest login) async {
    print('🟢 [LOGIN] ===== INÍCIO DO LOGIN =====');
    print('🟢 [LOGIN] Email recebido: "${login.email}"');
    print('🟢 [LOGIN] Email length: ${login.email.length}');
    print('🟢 [LOGIN] Email tem espaços? ${login.email.contains(" ")}');
    print('🟢 [LOGIN] Senha length: ${login.senha.length}');
    print('🟢 [LOGIN] Fazendo requisição POST para /public/login...');
    final jsonToSend = login.toJson();
    print('🟢 [LOGIN] JSON sendo enviado: ${json.encode(jsonToSend)}');
    print('🟢 [LOGIN] Username no JSON: "${jsonToSend["username"]}"');
    print('🟢 [LOGIN] Password no JSON: ${jsonToSend["password"] != null ? "*** (${jsonToSend["password"].toString().length} chars)" : "null"}');
    
    try {
      print('🟢 [LOGIN] Aguardando resposta da API...');
      final response = await _dio.post(
        "/public/login",
        data: json.encode(login.toJson()),
      );
      
      print('🟢 [LOGIN] ✅ Resposta recebida! Status: ${response.statusCode}');
      print('🟢 [LOGIN] Response.data tipo: ${response.data.runtimeType}');
      print('🟢 [LOGIN] Response.data é null? ${response.data == null}');

      // Verifica se response.data é válido
      if (response.data == null) {
        throw ApiException(
          message: 'Resposta vazia do servidor. Tente novamente.',
        );
      }

      // Tenta fazer o parse do JSON
      Usuario usuario;
      try {
        // PRINT DIRETO PARA LOGCAT - sempre aparece
        print('🔵 [LOGIN] Iniciando parse da resposta. Tipo: ${response.data.runtimeType}');
        
        // Normaliza o response.data para Map<String, dynamic>
        Map<String, dynamic> jsonData;
        if (response.data is Map<String, dynamic>) {
          jsonData = response.data as Map<String, dynamic>;
          print('🔵 [LOGIN] response.data é Map<String, dynamic>');
        } else if (response.data is Map) {
          jsonData = Map<String, dynamic>.from(response.data as Map);
          print('🔵 [LOGIN] response.data é Map (convertido)');
        } else if (response.data is String) {
          try {
            jsonData = json.decode(response.data as String) as Map<String, dynamic>;
            print('🔵 [LOGIN] response.data é String (decodificado)');
          } catch (e) {
            print('🔴 [LOGIN] ERRO ao decodificar JSON string: $e');
            throw Exception('Erro ao decodificar JSON string: $e');
          }
        } else {
          print('🔴 [LOGIN] Formato inválido: ${response.data.runtimeType}');
          throw Exception('Formato de resposta inválido: ${response.data.runtimeType}');
        }
        
        // PRINT das chaves do JSON
        print('🔵 [LOGIN] Chaves do JSON: ${jsonData.keys.toList()}');
        print('🔵 [LOGIN] Tem jwt: ${jsonData.containsKey('jwt')}, Tem tipPerfil: ${jsonData.containsKey('tipPerfil')}, Tem codUsuario: ${jsonData.containsKey('codUsuario')}');
        
        // Log da estrutura recebida para debug
        Logger.logInfo(
          'Estrutura JSON recebida do login',
          meta: {
            'email': login.email,
            'keys': jsonData.keys.toList(),
            'hasJwt': jsonData.containsKey('jwt'),
            'hasTipPerfil': jsonData.containsKey('tipPerfil'),
            'hasCodUsuario': jsonData.containsKey('codUsuario'),
          },
          tag: 'UserRepository.autenticaUser.parse',
        );
        
        print('🔵 [LOGIN] Chamando Usuario.fromJson...');
        usuario = Usuario.fromJson(jsonData);
        print('✅ [LOGIN] Usuario.fromJson concluído com sucesso');
      } catch (parseError, parseStackTrace) {
        // PRINT DIRETO DO ERRO - sempre aparece no Logcat
        print('🔴 [LOGIN] ERRO NO PARSE!');
        print('🔴 [LOGIN] Tipo do erro: ${parseError.runtimeType}');
        print('🔴 [LOGIN] Mensagem: ${parseError.toString()}');
        print('🔴 [LOGIN] Tipo do response.data: ${response.data.runtimeType}');
        
        // Tenta mostrar preview dos dados
        try {
          if (response.data != null) {
            final dataStr = response.data.toString();
            final preview = dataStr.length > 300 ? dataStr.substring(0, 300) + '...' : dataStr;
            print('🔴 [LOGIN] Preview dos dados: $preview');
          }
        } catch (e) {
          print('🔴 [LOGIN] Não foi possível mostrar preview dos dados');
        }
        
        // Log mais detalhado do erro
        final errorDetails = {
          'endpoint': '/public/login',
          'email': login.email,
          'responseDataType': response.data.runtimeType.toString(),
          'errorType': parseError.runtimeType.toString(),
          'errorMessage': parseError.toString(),
        };
        
        // Adiciona dados da resposta se possível
        try {
          if (response.data != null) {
            final dataStr = response.data.toString();
            errorDetails['responseDataPreview'] = dataStr.length > 500 
                ? dataStr.substring(0, 500) + '...' 
                : dataStr;
          }
        } catch (e) {
          errorDetails['responseDataError'] = 'Não foi possível serializar response.data';
        }
        
        Logger.logError(
          parseError,
          stackTrace: parseStackTrace,
          meta: errorDetails,
          tag: 'UserRepository.autenticaUser.parse',
        );
        
        // Mensagem de erro mais específica
        String errorMessage = 'Erro ao processar resposta do servidor. Verifique se a API está funcionando.';
        if (parseError.toString().contains('null') || parseError.toString().contains('NoSuchMethodError')) {
          errorMessage = 'Dados incompletos recebidos do servidor. Tente novamente.';
        } else if (parseError.toString().contains('type') || parseError.toString().contains('cast')) {
          errorMessage = 'Formato de dados inválido recebido do servidor.';
        }
        
        print('🔴 [LOGIN] Lançando ApiException com mensagem: $errorMessage');
        throw ApiException(
          message: errorMessage,
          originalError: parseError,
        );
      }
      
      // Verifica se o login foi bem-sucedido
      // Para login, se temos JWT e status 200, consideramos sucesso mesmo se indSucesso for 0
      print('🟢 [LOGIN] Verificando resultado do login...');
      print('🟢 [LOGIN] indSucesso: ${usuario.indSucesso}');
      print('🟢 [LOGIN] jwt: ${usuario.jwt != null ? "presente" : "ausente"}');
      print('🟢 [LOGIN] codUsuario: ${usuario.codUsuario}');
      print('🟢 [LOGIN] tipPerfil: ${usuario.indTipo}');
      
      // Se temos JWT e codUsuario, o login foi bem-sucedido (status 200 já confirma isso)
      // Apenas verifica indSucesso se não tivermos JWT
      if (usuario.jwt == null || usuario.jwt!.isEmpty) {
        // Sem JWT, verifica indSucesso
        if (usuario.indSucesso != null && usuario.indSucesso == 0) {
          String errorMsg = usuario.desMsgErro ?? 'E-mail ou senha inválidos. Verifique suas credenciais.';
          print('🔴 [LOGIN] Login falhou: Sem JWT e indSucesso = 0');
          print('🔴 [LOGIN] Mensagem de erro: $errorMsg');
          Logger.logWarn(
            'Login falhou: indSucesso = 0 e sem JWT',
            meta: {'email': login.email, 'indSucesso': usuario.indSucesso, 'desMsgErro': usuario.desMsgErro},
            tag: 'UserRepository.autenticaUser',
          );
          throw ApiException(
            message: errorMsg,
            statusCode: 401,
          );
        }
      } else {
        // Temos JWT, login foi bem-sucedido
        print('✅ [LOGIN] Login bem-sucedido! JWT presente.');
      }

      // Atualiza token no ApiBaseHelper
      if (usuario.jwt != null) {
        ApiBaseHelper.updateAuthToken(usuario.jwt);
      }

      Logger.logInfo(
        'Login realizado com sucesso',
        meta: {'email': login.email, 'tipoUsuario': usuario.indTipo},
        tag: 'UserRepository',
      );

      return usuario;
    } on ApiException catch (e) {
      print('🔴 [LOGIN] ApiException capturada: ${e.message}');
      rethrow;
    } on DioException catch (e) {
      print('🔴 [LOGIN] DioException capturada!');
      print('🔴 [LOGIN] Tipo: ${e.type}');
      print('🔴 [LOGIN] Mensagem: ${e.message}');
      print('🔴 [LOGIN] Status Code: ${e.response?.statusCode}');
      
      // Extrai mensagem da resposta da API se disponível
      String? apiErrorMessage;
      if (e.response != null && e.response?.data != null) {
        print('🔴 [LOGIN] Response data: ${e.response?.data}');
        print('🔴 [LOGIN] Response data tipo: ${e.response?.data.runtimeType}');
        
        // Tenta extrair mensagem de erro da API
        if (e.response?.data is String) {
          apiErrorMessage = e.response?.data as String;
          // Remove aspas e espaços extras
          apiErrorMessage = apiErrorMessage.trim().replaceAll('"', '').replaceAll("'", '');
          print('🔴 [LOGIN] Mensagem extraída (String): $apiErrorMessage');
        } else if (e.response?.data is Map) {
          final data = e.response?.data as Map;
          apiErrorMessage = data['message'] as String? ?? 
                           data['mensagem'] as String? ?? 
                           data['error'] as String? ??
                           data['msg'] as String?;
          print('🔴 [LOGIN] Mensagem extraída (Map): $apiErrorMessage');
        }
      }
      
      Logger.logError(
        e,
        meta: {
          'endpoint': '/public/login', 
          'email': login.email,
          'apiErrorMessage': apiErrorMessage,
          'statusCode': e.response?.statusCode,
        },
        tag: 'UserRepository.autenticaUser',
      );
      
      // Se for 401, usa a mensagem da API se disponível, senão usa mensagem padrão
      if (e.response?.statusCode == 401) {
        final finalMessage = apiErrorMessage ?? 'E-mail ou senha inválidos. Verifique suas credenciais.';
        print('🔴 [LOGIN] Lançando ApiException 401 com mensagem: $finalMessage');
        throw ApiException(
          message: finalMessage,
          statusCode: 401,
          originalError: e,
          responseData: e.response?.data,
        );
      }
      
      throw ApiException.fromDioError(e);
    } catch (e, stackTrace) {
      print('🔴 [LOGIN] Erro genérico capturado!');
      print('🔴 [LOGIN] Tipo: ${e.runtimeType}');
      print('🔴 [LOGIN] Mensagem: ${e.toString()}');
      
      Logger.logError(
        e,
        stackTrace: stackTrace,
        meta: {'endpoint': '/public/login'},
        tag: 'UserRepository.autenticaUser',
      );
      throw ApiException(
        message: 'Erro ao realizar login. Tente novamente.',
        originalError: e,
      );
    }
  }

  Future<List<Cem>?> buscaCemMotorista(int codMotorista) async {
    final response =
        await _dio.post("/api/buscacems", data: {"codMotorista": codMotorista});
    // ignore: deprecated_member_use
    List<Cem> listResponse = [];
    MotoristaCem retorno = MotoristaCem.fromJson(response.data);
    if (retorno.listaCem != null)
      return retorno.listaCem;
    else
      listResponse;
    // List<Cem> listResponse = [];
    // Cem cem1 = Cem(
    //     codCem: 1,
    //     codUsuario: 244,
    //     desNome: "Wagner",
    //     indAguardandoAutorizacao: true,
    //     indAtivo: 1);
    // listResponse.add(cem1);

    // Cem cem2 = Cem(
    //     codCem: 2,
    //     codUsuario: 44,
    //     desNome: "Carolina",
    //     indAguardandoAutorizacao: false,
    //     indAtivo: 0);
    // listResponse.add(cem2);

    // Cem cem3 = Cem(
    //     codCem: 3,
    //     codUsuario: 4444,
    //     desNome: "Eduardo",
    //     indAguardandoAutorizacao: true,
    //     indAtivo: 1);
    // listResponse.add(cem3);
    // return listResponse;
  }

  Future<void> updateCem(Cem cemUpdate, int codMotorista) async {
    int indAguardandoAutorizacao = 0;

    indAguardandoAutorizacao = cemUpdate.indAguardandoAutorizacao ? 1 : 0;

    final response = await _dio.post("/api/ativar", data: {
      "codCem": cemUpdate.codCem,
      "codMotorista": codMotorista,
      "indStatus": indAguardandoAutorizacao
    });
    // ignore: deprecated_member_use
  }

  Future<List<SolicitacaoMotorista>> buscaSolicitacoesMotorista(
      int codMotorista,
      {int tipStatus = 0}) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";

    final response = await _dio
        .get("/private/corridas/motorista/${codMotorista}/${tipStatus}");

    List<SolicitacaoMotorista> listResponse = [];
    ListaSolicitacoesMotorista retorno =
        ListaSolicitacoesMotorista.fromJson(response.data);
    if (retorno.listaSolicitacoes != null) return retorno.listaSolicitacoes!;

    // ignore: deprecated_member_use
    // List<SolicitacaoMotorista> listResponse = [];
    // SolicitacaoMotorista cem1 = SolicitacaoMotorista(
    //     codUsuario: 244, dtaSolicitacao: "21/01/2021", indFinalizado: 0);
    // listResponse.add(cem1);

    // SolicitacaoMotorista cem2 = SolicitacaoMotorista(
    //     codUsuario: 25, dtaSolicitacao: "21/01/2020", indFinalizado: 1);
    // listResponse.add(cem2);

    // SolicitacaoMotorista cem3 = SolicitacaoMotorista(
    //     codUsuario: 25, dtaSolicitacao: "20/01/2020", indFinalizado: 1);
    // listResponse.add(cem3);
    return listResponse;
  }

  Future<List<SolicitacaoMotorista>> buscaSolicitacoesEmpresa(int codMotorista,
      {int tipStatus = -1, ConsultaRequest? req, bool isAdm = false}) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";

    Map<String, dynamic>? queryParameters = Map<String, dynamic>();

    if (req != null) {
      if (req.dtaIni != null) {
        queryParameters.putIfAbsent("dtaIni",
            () => ApiBaseHelper.getDtaFormatadaSemHoraApi(req.dtaIni));
      }

      if (req.dtaFim != null) {
        queryParameters.putIfAbsent("dtaFim",
            () => ApiBaseHelper.getDtaFormatadaSemHoraApi(req.dtaFim));
      }

      if (req.inInfro != null) {
        queryParameters.putIfAbsent("inInfo", () => req.inInfro);
      }
    }

    List<SolicitacaoMotorista> listResponse = [];
    if (isAdm) {
      final response = await _dio.get("/private/corridas/empresa/admin/all",
          queryParameters: queryParameters);

      ListaSolicitacoesMotorista retorno =
          ListaSolicitacoesMotorista.fromJson(response.data);
      if (retorno.listaSolicitacoes != null) return retorno.listaSolicitacoes!;
    } else {
      final response = await _dio.get(
          "/private/corridas/empresa/${codMotorista}/${tipStatus}",
          queryParameters: queryParameters);

      ListaSolicitacoesMotorista retorno =
          ListaSolicitacoesMotorista.fromJson(response.data);
      if (retorno.listaSolicitacoes != null) return retorno.listaSolicitacoes!;
    }

    return listResponse;
  }

  Future<List<SolicitacaoMotorista>> buscaNovasSolicitacoesMotorista(
      int codUsuario) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    final response = await _dio.get("/private/corridas/usuario/${codUsuario}");

    List<SolicitacaoMotorista> listResponse = [];
    ListaSolicitacoesMotorista retorno =
        ListaSolicitacoesMotorista.fromJson(response.data);
    if (retorno.listaSolicitacoes != null) return retorno.listaSolicitacoes!;

    // ignore: deprecated_member_use
    // List<SolicitacaoMotorista> listResponse = [];
    // SolicitacaoMotorista cem1 = SolicitacaoMotorista(
    //     codUsuario: 244, dtaSolicitacao: "21/01/2021", indFinalizado: 0);
    // listResponse.add(cem1);

    // SolicitacaoMotorista cem2 = SolicitacaoMotorista(
    //     codUsuario: 25, dtaSolicitacao: "21/01/2020", indFinalizado: 1);
    // listResponse.add(cem2);

    // SolicitacaoMotorista cem3 = SolicitacaoMotorista(
    //     codUsuario: 25, dtaSolicitacao: "20/01/2020", indFinalizado: 1);
    // listResponse.add(cem3);
    return listResponse;
  }

  Future<void> chamaPedidoDeSocorro(
      Usuario motorista, double desLatitude, double desLongitude) async {
    final response = await _dio.post("/chamados/criarchamado", data: {
      "codMotorista": motorista.codUsuario,
      "desLatitude": desLatitude,
      "desLongitude": desLongitude
    });
    // ignore: deprecated_member_use
  }

  Future<void> chamaNovaCorrida(
      Usuario motorista, SolicitacaoMotorista sol) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";

    sol.codEmpresa = motorista.usuarioResp!.empresas!.first.codEmpresa;

    DbEmpresasByCodEmpresa emp =
        DbEmpresasByCodEmpresa(codEmpresa: sol.codEmpresa);

    sol.dbEmpresasByCodEmpresa = emp;

    final response =
        await _dio.post("/private/corridas/create", data: sol.toJson());
    // ignore: deprecated_member_use
  }

  Future<void> logoff(int codUsuario) async {
    try {
      final response =
          await _dio.post("/api/logoff", data: {"codUsuario": codUsuario});
    } on Exception catch (e) {
      print("erro");
    }
    // ignore: deprecated_member_use
  }

  Future<void> updateLocalizacaoMotorista(
      Usuario motorista, double desLatitude, double desLongitude) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    final response = await _dio.post(
      "/private/user/${motorista.codUsuario}/atualizarlocal/$desLatitude/$desLongitude",
    );

    // final response = await _dio.post("/private/user/${motorista.codUsuario}/atualizarlocal/${desLatitude}/${desLongitude}", data: {
    //   "codMotorista": motorista.codUsuario,
    //   "desLatitude": desLatitude,
    //   "desLongitude": desLongitude,
    // });
    // ignore: deprecated_member_use
  }

  Future<List<MotoristasProximos>> buscaMotoristaProximos(
      Usuario motorista) async {
    final response = await _dio.post("/api/buscarmotoristasproximos",
        data: {"codMotorista": motorista.codUsuario});

    List<MotoristasProximos> listResponse = [];
    ListaMotoristaProximos retorno =
        ListaMotoristaProximos.fromJson(response.data);
    if (retorno.listaSolicitacoes != null) return retorno.listaSolicitacoes!;

    return listResponse;
    // ignore: deprecated_member_use
  }

  Future<List<MotoristasProximos>> buscaMotoristaProximosCem(
      Usuario motorista) async {
    final response = await _dio.post("/api/buscarmotoristasparacem",
        data: {"codCem": motorista.codUsuario});

    List<MotoristasProximos> listResponse = [];
    ListaMotoristaProximos retorno =
        ListaMotoristaProximos.fromJson(response.data);
    if (retorno.listaSolicitacoes != null) return retorno.listaSolicitacoes!;

    return listResponse;
    // ignore: deprecated_member_use
  }

  Future<Usuario> registraCem(
      String? email, String? senha, CadastroCemRequest login,
      {Usuario? userInsert}) async {
    Usuario? user = ApiBaseHelper.userSessao;

    if (userInsert != null) {
      log("entrei");
    } else {
      if (user != null) {
        if (user.indTipo == 1) {
          if (login.codCem == null) login.indAdicaoMotoristaCem = 1;
          //login.codCem = user.codCem;
          login.codMotorista = user.codUsuario;
          //login.emailMotoristaAmigo = user.desEmail!;
        } else if (user.indTipo == 2) {
          login.codMotorista = user.codUsuario;
          // login.indAdicaoMotoristaCem = 1;
          //  login.codCem = user.codUsuario;
          //login.email = user.usuario!;
        }
      }
    }
    try {
      print('🟢 [CADASTRO] Fazendo requisição POST para /public/criarUsuario...');
      final jsonToSend = userInsert?.toJson();
      print('🟢 [CADASTRO] JSON sendo enviado: ${json.encode(jsonToSend)}');
      print('🟢 [CADASTRO] Email no JSON: ${jsonToSend?["usuario"]}');
      print('🟢 [CADASTRO] Senha no JSON: ${jsonToSend?["senha"] != null ? "***" : "null"}');
      print('🟢 [CADASTRO] usuarioResp.usuario: ${jsonToSend?["usuarioResp"]?["usuario"]}');
      print('🟢 [CADASTRO] usuarioResp.senha: ${jsonToSend?["usuarioResp"]?["senha"] != null ? "***" : "null"}');
      
      final response = await _dio.post(
        "/public/criarUsuario",
        data: json.encode(jsonToSend),
      );
      
      print('🟢 [CADASTRO] Resposta recebida! Status: ${response.statusCode}');
      print('🟢 [CADASTRO] Response.data tipo: ${response.data.runtimeType}');
      
      var retorno;
      
      // Normaliza response.data para Map se necessário
      Map<String, dynamic> jsonData;
      if (response.data is Map<String, dynamic>) {
        jsonData = response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        jsonData = Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String) {
        try {
          jsonData = json.decode(response.data as String) as Map<String, dynamic>;
        } catch (e) {
          print('🔴 [CADASTRO] Erro ao decodificar JSON string: $e');
          throw Exception('Erro ao processar resposta do servidor: formato inválido');
        }
      } else {
        throw Exception('Formato de resposta inválido: ${response.data.runtimeType}');
      }
      
      print('🟢 [CADASTRO] Fazendo parse do JSON...');
      print('🟢 [CADASTRO] JSON completo recebido: ${json.encode(jsonData)}');
      retorno = Usuario.fromJson(jsonData);
      
      print('🟢 [CADASTRO] Parse concluído!');
      print('🟢 [CADASTRO] indSucesso: ${retorno.indSucesso}');
      print('🟢 [CADASTRO] desMsgErro: ${retorno.desMsgErro}');
      print('🟢 [CADASTRO] codUsuario: ${retorno.codUsuario}');
      print('🟢 [CADASTRO] desNome: ${retorno.desNome}');
      
      if (retorno.indSucesso == 0) {
        String message = retorno.desMsgErro ?? 'Erro ao efetuar cadastro';
        print('🔴 [CADASTRO] Cadastro falhou: $message');
        print('🔴 [CADASTRO] Mensagem de erro da API: ${retorno.desMsgErro ?? "Não informada"}');
        print('🔴 [CADASTRO] Dados enviados:');
        print('   - Email: ${email}');
        print('   - Nome: ${userInsert?.desNome ?? "N/A"}');
        print('   - CPF: ${userInsert?.usuarioResp?.motoristas?.first.desCpfCnpj ?? "N/A"}');
        print('   - Placa: ${userInsert?.usuarioResp?.motoristas?.first.desPlaca ?? "N/A"}');
        print('   - Tipo Moto: ${userInsert?.usuarioResp?.motoristas?.first.desTipoMoto ?? "N/A"}');
        print('   - CNH anexada: ${userInsert?.usuarioResp?.motoristas?.first.desCarteira != null && userInsert!.usuarioResp!.motoristas!.first.desCarteira!.isNotEmpty}');
        print('   - Endereço completo: ${userInsert?.usuarioResp?.motoristas?.first.enderecos?.isNotEmpty ?? false}');
        
        // Melhora a mensagem de erro se for genérica
        if (message == 'Erro ao efetuar cadastro' || message.isEmpty) {
          message = 'Erro ao efetuar cadastro. Verifique se todos os campos foram preenchidos corretamente, especialmente: CPF, CNH, Placa, Modelo e Endereço completo.';
        }
        
        throw new CustomException(message: message);
      }
      
      print('✅ [CADASTRO] Cadastro realizado com sucesso!');
      return retorno;
    } on DioException catch (e) {
      print('🔴 [CADASTRO] DioException capturada!');
      print('🔴 [CADASTRO] Tipo: ${e.type}');
      print('🔴 [CADASTRO] Status Code: ${e.response?.statusCode}');
      print('🔴 [CADASTRO] Response data: ${e.response?.data}');
      
      Logger.logError(
        e,
        meta: {'endpoint': '/public/criarUsuario', 'email': email},
        tag: 'UserRepository.registraCem',
      );
      throw ApiException.fromDioError(e);
    } catch (e, stackTrace) {
      print('🔴 [CADASTRO] Erro genérico: ${e.toString()}');
      Logger.logError(
        e,
        stackTrace: stackTrace,
        meta: {'endpoint': '/public/criarUsuario'},
        tag: 'UserRepository.registraCem',
      );
      
      if (e is CustomException) {
        rethrow;
      }
      
      throw ApiException(
        message: 'Erro ao efetuar cadastro. Tente novamente.',
        originalError: e,
      );
    }

    //return Usuario.fromJson(response.data);
  }

  Future<Usuario> registraMotorista(
      String? email, String? senha, CadastroCemRequest login) async {
    Usuario? user = ApiBaseHelper.userSessao;
    if (user != null) {
      if (user.indTipo == 2) {
        login.indAdicaoMotoristaCem = 1;
        login.codMotorista = user.codUsuario;
        login.emailMotoristaAmigo = user.usuario!;
        login.codCem = user.codUsuario;
      } else if (user.indTipo == 1) {
        login.codMotorista = user.codUsuario;
      }
    }

    final response = await _dio.post(
      "/api/cadastro_motorista",
      data: json.encode(login.toJson()),
    );
    var retorno;
    // if (login.senha == "1234") {
    //   retorno = Usuario(
    //       codUsuario: 1,
    //       desSenha: "senha",
    //       desModelo: "Clio",
    //       desPlaca: "IPF-0855",
    //       desNome: "Wagner Almeida",
    //       codMotorista: 1,
    //       codCem: 3,
    //       desCpf: "425.525.333-45",
    //       desEmail: "wagner@appminhaescola.com",
    //       indTipo: 2,
    //       indSucesso: 0,
    //       desMsgErro: "erro cadastar");

    //   if (retorno.indSucesso == 0) {
    //     String message = retorno.desMsgErro;
    //     throw new CustomException(message: '$message');
    //   }
    // }

    retorno = Usuario.fromJson(response.data);
    if (retorno.indSucesso == 0) {
      String message = retorno.desMsgErro ?? 'Erro ao efetuar cadastro';
      throw new CustomException(message: message);
    } else {
      if (user != null) {
        // if (user.indTipo == 1) {
        //   user.desCor = login.cor;
        //   user.desNome = login.nome;
        //   user.desModelo = login.carro;
        //   user.desEmail = login.email;
        //   user.desPlaca = login.placa;
        // }
      }
    }
    return retorno;

    //return Usuario.fromJson(response.data);
  }

  Future<List<MotoristasProximos>> buscaMotoristaCemProximos(
      Usuario motorista) async {
    final response = await _dio.post("/api/buscarmotoristasparacem",
        data: {"codCem": motorista.codUsuario});

    List<MotoristasProximos> listResponse = [];
    ListaMotoristaProximos retorno =
        ListaMotoristaProximos.fromJson(response.data);
    if (retorno.listaSolicitacoes != null) return retorno.listaSolicitacoes!;

    // MotoristasProximos cem1 = MotoristasProximos(
    //     codMotorista: 2,
    //     desLatitude: -29.1860583,
    //     desLongitude: -51.2377713,
    //     desModelo: "a",
    //     desNome: "wagner",
    //     desPlaca: "ipf",
    //     dthUltLocal: "21/06/2020");
    // listResponse.add(cem1);

    // MotoristasProximos cem2 = MotoristasProximos(
    //     codMotorista: 5,
    //     desLatitude: -29.1744604,
    //     desLongitude: -51.2147667,
    //     desModelo: "a",
    //     desNome: "wagner",
    //     desPlaca: "ipf",
    //     dthUltLocal: "21/06/2020");
    // listResponse.add(cem2);

    // MotoristasProximos cem3 = MotoristasProximos(
    //     codMotorista: 3,
    //     desLatitude: -29.2860583,
    //     desLongitude: -51.2377713,
    //     desModelo: "a",
    //     desNome: "wagner",
    //     desPlaca: "ipf",
    //     dthUltLocal: "21/06/2020");
    // listResponse.add(cem3);

    // MotoristasProximos cem4 = MotoristasProximos(
    //     codMotorista: 7,
    //     desLatitude: -29.1860583,
    //     desLongitude: -51.2377713,
    //     desModelo: "a",
    //     desNome: "wagner",
    //     desPlaca: "ipf",
    //     dthUltLocal: "21/06/2020");
    // listResponse.add(cem4);

    // MotoristasProximos cem5 = MotoristasProximos(
    //     codMotorista: 9,
    //     desLatitude: -29.1860583,
    //     desLongitude: -51.2377713,
    //     desModelo: "a",
    //     desNome: "wagner",
    //     desPlaca: "ipf",
    //     dthUltLocal: "21/06/2020");
    // listResponse.add(cem5);

    return listResponse;
    // ignore: deprecated_member_use
  }

  Future<void> finalizarChamado(int numSeqChamado, int indStatusCorrida, {String? motivoCancelamento}) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    
    // Se for cancelamento e tiver motivo, envia no body
    if (indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA && motivoCancelamento != null) {
      final response = await _dio.post(
        "/private/corridas/corrida/$numSeqChamado/$indStatusCorrida",
        data: {
          'desMotivoCancelamento': motivoCancelamento,
        },
      );
    } else {
      final response = await _dio
          .post("/private/corridas/corrida/$numSeqChamado/$indStatusCorrida");
    }
    // ignore: deprecated_member_use
  }

  Future<void> aceitarCorrida(int numSeqChamado, int indStatusCorrida) async {
    Usuario? user = ApiBaseHelper.userSessao;
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    final response = await _dio.post(
        "/private/corridas/motorista/${user!.usuarioResp!.motoristas!.first.codMotorista}/corrida/${numSeqChamado}/${indStatusCorrida}");
    // ignore: deprecated_member_use
    if (response.data != null &&
        response.data.toString().contains("outro motorista")) {
      throw PlatformException(
          code: "1",
          message:
              "Corrida já aceita por outro motorista, aguarde uma próxima");
    }
  }

  Future<List<SolicitacaoMotorista>> buscaSolicitacoesCem(int codMotorista,
      {bool indBuscaChamadosRaio = false}) async {
    final response = await _dio.post("/chamados/buscapainelchamados", data: {
      "codCem": codMotorista,
      "indBuscaChamadosRaio": indBuscaChamadosRaio,
    });

    List<SolicitacaoMotorista> listResponse = [];
    ListaSolicitacoesMotorista retorno =
        ListaSolicitacoesMotorista.fromJson(response.data);
    if (retorno.listaSolicitacoes != null) return retorno.listaSolicitacoes!;

    // ignore: deprecated_member_use
    // List<SolicitacaoMotorista> listResponse = [];
    // SolicitacaoMotorista cem1 = SolicitacaoMotorista(
    //     codUsuario: 244, dtaSolicitacao: "21/01/2021", indFinalizado: 0);
    // listResponse.add(cem1);

    // SolicitacaoMotorista cem2 = SolicitacaoMotorista(
    //     codUsuario: 25, dtaSolicitacao: "21/01/2020", indFinalizado: 1);
    // listResponse.add(cem2);

    // SolicitacaoMotorista cem3 = SolicitacaoMotorista(
    //     codUsuario: 25, dtaSolicitacao: "20/01/2020", indFinalizado: 1);
    // listResponse.add(cem3);
    return listResponse;
  }

  Future<List<DadosCorridas>> buscaTotaisCorridas(
      {int? codEmpresa,
      int? codMotorista,
      DateTime? dtaIni,
      DateTime? dtaFim,
      bool? isAdm}) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";

    Map<String, dynamic>? queryParameters = Map<String, dynamic>();

    if (dtaIni != null) {
      queryParameters.putIfAbsent(
          "dtaIni", () => ApiBaseHelper.getDtaFormatadaSemHoraApi(dtaIni));
    }
    if (dtaFim != null) {
      queryParameters.putIfAbsent(
          "dtaFim", () => ApiBaseHelper.getDtaFormatadaSemHoraApi(dtaFim));
    }
    if ((isAdm != null && !isAdm) || isAdm == null) {
      if (codEmpresa != null) {
        final response = await _dio.get(
            "/private/corridas/corrida/totais/${codEmpresa}",
            queryParameters: queryParameters);

        List<DadosCorridas> listResponse = [];
        if (response != null && response.data != null)
          listResponse = dadosCorridasFromJson(json.encode(response.data));

        if (listResponse != null) return listResponse;
      }

      if (codMotorista != null) {
        final response = await _dio.get(
            "/private/corridas/corrida/motorista/totais/${codMotorista}",
            queryParameters: queryParameters);

        List<DadosCorridas> listResponse = [];

        listResponse = dadosCorridasFromJson(response.data);

        if (listResponse != null) return listResponse;
      }
    } else {
      // Admin: busca todos os dados com parâmetros de data
      final response = await _dio.get(
          "/private/corridas/corrida/admin/totais/all",
          queryParameters: queryParameters);

      List<DadosCorridas> listResponse = [];

      if (response != null && response.data != null) {
        listResponse = dadosCorridasFromJson(json.encode(response.data));
      }

      if (listResponse != null) return listResponse;
    }

    List<DadosCorridas> listResponse = [];

    return listResponse;
  }

  Future<List<SaldosCorrida>> buscaSaldosCorridas(
      {int? codEmpresa,
      int? codMotorista,
      DateTime? dtaIni,
      DateTime? dtaFim,
      bool? isAdm}) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";

    Map<String, dynamic>? queryParameters = Map<String, dynamic>();

    if (dtaIni != null) {
      queryParameters.putIfAbsent(
          "dtaIni", () => ApiBaseHelper.getDtaFormatadaSemHoraApi(dtaIni));
    }
    if (dtaFim != null) {
      queryParameters.putIfAbsent(
          "dtaFim", () => ApiBaseHelper.getDtaFormatadaSemHoraApi(dtaFim));
    }

    // Se for admin, tenta buscar todos os saldos
    if (isAdm == true) {
      try {
        final response = await _dio.get(
            "/private/corridas/corrida/admin/valores/all",
            queryParameters: queryParameters);

        List<SaldosCorrida> listResponse = [];
        if (response != null && response.data != null) {
          listResponse = saldosCorridaFromJson(json.encode(response.data));
        }
        if (listResponse != null) return listResponse;
      } catch (e) {
        // Se a rota admin não existir, retorna lista vazia sem erro
        return [];
      }
    }

    if (codEmpresa != null) {
      final response = await _dio.get(
          "/private/corridas/corrida/valores/empresa/${codEmpresa}",
          queryParameters: queryParameters);

      List<SaldosCorrida> listResponse = [];
      if (response != null && response.data != null)
        listResponse = saldosCorridaFromJson(json.encode(response.data));

      if (listResponse != null) return listResponse;
    }

    if (codMotorista != null) {
      final response = await _dio.get(
          "/private/corridas/corrida/valores/motorista/${codMotorista}",
          queryParameters: queryParameters);

      List<SaldosCorrida> listResponse = [];

      if (response != null && response.data != null) {
        listResponse = saldosCorridaFromJson(json.encode(response.data));
      }

      if (listResponse != null) return listResponse;
    }

    List<SaldosCorrida> listResponse = [];

    return listResponse;
  }

  Future<void> atualizaStatusOnOff(UsuarioResp motorista, int indStatus) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    final response = await _dio.post(
      "/private/user/status/${motorista.codUsuario}/$indStatus",
    );

    // final response = await _dio.post("/private/user/${motorista.codUsuario}/atualizarlocal/${desLatitude}/${desLongitude}", data: {
    //   "codMotorista": motorista.codUsuario,
    //   "desLatitude": desLatitude,
    //   "desLongitude": desLongitude,
    // });
    // ignore: deprecated_member_use
  }

  Future<void> realizaPagamentoMotorista(
      String numSeqChamado, int codMotorista) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";

    final response = await _dio.post(
        "/private/corridas/corridas/valores/pagamento/${codMotorista}/${numSeqChamado}");
    // ignore: deprecated_member_use
  }

  Future<void> realizaConfirmaRecebimentoEstabelecimento(
      String numSeqChamado, int codEmpresa) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";

    final response = await _dio.post(
        "/private/corridas/corridas/valores/recebimento/${codEmpresa}/${numSeqChamado}");
    // ignore: deprecated_member_use
  }

  Future<Usuario> atualizaUser(
      String? email, String? senha, CadastroCemRequest login,
      {Usuario? userInsert}) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    final response = await _dio.post(
      "/private/user/atualizaUser",
      data: json.encode(userInsert?.usuarioResp?.toJson()),
    );
    var retorno;
    // if (login.senha == "1234") {
    //   retorno = Usuario(
    //       codUsuario: 1,
    //       desSenha: "senha",
    //       desModelo: "Clio",
    //       desPlaca: "IPF-0855",
    //       desNome: "Wagner Almeida",
    //       codMotorista: 1,
    //       codCem: 3,
    //       desCpf: "425.525.333-45",
    //       desEmail: "wagner@appminhaescola.com",
    //       indTipo: 2,
    //       indSucesso: 0,
    //       desMsgErro: "erro cadastar");

    //   if (retorno.indSucesso == 0) {
    //     String message = retorno.desMsgErro;
    //     throw new CustomException(message: '$message');
    //   }
    // }

    retorno = Usuario.fromJson(response.data);
    if (retorno.indSucesso == 0) {
      String message = retorno.desMsgErro ?? 'Erro ao atualizar cadastro';
      throw new CustomException(message: message);
    }
    return retorno;

    //return Usuario.fromJson(response.data);
  }

  Future<void> atualizaConfigSys(ConfigSys config) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    // ignore: deprecated_member_use

    final response = await _dio.post(
      "/private/sys/edit",
      data: json.encode(config.toJson()),
    );
  }

  Future<ConfigSys> buscaConfigSys() async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    // ignore: deprecated_member_use

    final response = await _dio.get("/private/sys/config");

    ConfigSys listResponse = new ConfigSys();

    listResponse = ConfigSys.fromJson(response.data);
    return listResponse;
  }

  Future<double?> buscaVlrTaxa(double kmCorrida) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    // ignore: deprecated_member_use

    final response = await _dio.get("/private/sys/vlrTaxa/$kmCorrida");

    double? retorno = response.data as double?;
    return retorno;
  }

  Future<double?> buscaConfigTaxas() async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    // ignore: deprecated_member_use

    final response = await _dio.get("/private/sys/vlrTaxa/findAll");
  }

  /// Solicita recuperação de senha via email
  Future<void> solicitarRecuperacaoSenha(RecuperacaoSenhaRequest request) async {
    try {
      final response = await _dio.post(
        "/public/recuperar-senha",
        data: json.encode(request.toJson()),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          message: response.data?['message'] ?? 'Erro ao solicitar recuperação de senha',
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 
                     'Erro ao solicitar recuperação de senha. Verifique seu email.';
      throw ApiException(
        message: message,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(
        message: 'Erro inesperado ao solicitar recuperação de senha',
        originalError: e,
      );
    }
  }

  /// Altera a senha do usuário logado
  Future<void> alterarSenha(AlteracaoSenhaRequest request) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    
    try {
      final response = await _dio.post(
        "/private/usuario/alterar-senha",
        data: json.encode(request.toJson()),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          message: response.data?['message'] ?? 'Erro ao alterar senha',
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 
                     'Erro ao alterar senha. Verifique se a senha atual está correta.';
      throw ApiException(
        message: message,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(
        message: 'Erro inesperado ao alterar senha',
        originalError: e,
      );
    }
  }
}
