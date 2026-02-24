import 'dart:async';
import 'dart:convert';

import 'package:delivery_front/bussiness/repository/user_repository.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/shared/models/DadosCorrida.dart';
import 'package:delivery_front/shared/models/SaldosCorrida.dart';
import 'package:delivery_front/shared/models/cadastroCemRequest.dart';
import 'package:delivery_front/shared/models/consultaRequest.dart';
import 'package:delivery_front/shared/models/loginRequest.dart';
import 'package:delivery_front/shared/models/recuperacao_senha_request.dart';
import 'package:delivery_front/shared/models/alteracao_senha_request.dart';
import 'package:delivery_front/shared/models/motorista/lista_cem.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/models/motorista/models/motoristas_proximos.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/shared/services/local_storage_service.dart';
import 'package:flutter/services.dart';

class UserService {
  UserRepository _userRepository = UserRepository();
  final _userDataController = StreamController<Usuario>();

  StreamSink<Usuario> get chuckDataSink => _userDataController.sink;

  Stream<Usuario> get chuckDataStream => _userDataController.stream;

  void dispose() {
    _userDataController.close();
  }

  Future<Usuario?> login(LoginRequest login) async {
    try {
      final result = await _userRepository.autenticaUser(null, null, login);
      return result;
    } on ApiException catch (e) {
      Logger.logError(
        e,
        meta: {'email': login.email},
        tag: 'UserService.login',
      );
      rethrow;
    } catch (e, stackTrace) {
      Logger.logError(
        e,
        stackTrace: stackTrace,
        meta: {'email': login.email},
        tag: 'UserService.login',
      );
      throw ApiException(
        message: ErrorHandler.handleError(e, stackTrace: stackTrace),
        originalError: e,
      );
    }
  }

  login2(LoginRequest login) async {
    Usuario result = await _userRepository.autenticaUser(null, null, login);
    chuckDataSink.add(result);
  }

  Future<Usuario?> getCurrentUser() async {
    final userJson = await LocalStorageService.getString('current_user');
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final res = jsonDecode(userJson);
        return Usuario.fromJson(res);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<double?> getLatitude() async {
    return await LocalStorageService.getDouble('latitude');
  }

  Future<double?> getLongitude() async {
    return await LocalStorageService.getDouble('longitude');
  }

  Future<void> updateLatitudeLongitude(
      double latitude, double longitude) async {
    await LocalStorageService.setDouble('latitude', latitude);
    await LocalStorageService.setDouble('longitude', longitude);
  }

  Future<void> saveLocalDB(Usuario user) async {
    await LocalStorageService.setString(
        'current_user', jsonEncode(user.toJson()));
    ApiBaseHelper.userSessao = user;
  }

  Future<void> logoffLocalDB() async {
    try {
      if (ApiBaseHelper.userSessao?.codUsuario != null) {
        await _userRepository.logoff(ApiBaseHelper.userSessao!.codUsuario!);
      }
    } on ApiException catch (e) {
      Logger.logWarn(
        'Erro ao fazer logoff no servidor: ${e.message}',
        tag: 'UserService.logoffLocalDB',
      );
    } on PlatformException catch (e) {
      Logger.logError(
        e,
        meta: {'message': e.message},
        tag: 'UserService.logoffLocalDB',
      );
    } catch (e, stackTrace) {
      Logger.logError(
        e,
        stackTrace: stackTrace,
        tag: 'UserService.logoffLocalDB',
      );
    } finally {
      await LocalStorageService.remove('current_user');
      ApiBaseHelper.userSessao = Usuario();
      ApiBaseHelper.updateAuthToken(null);
    }
  }

  Future<List<Cem>?> fetchCemMotorista() async {
    var retorno = await getCurrentUser();
    if (retorno != null) {
      // List<Cem> lista =
      //     (await _userRepository.buscaCemMotorista(retorno.codMotorista!))!;
      // return lista;
    }
    return null;
  }

  Future<void> updateStatusCem(Cem cemAtualizacao) async {
    var retorno = await getCurrentUser();
    // await _userRepository.updateCem(cemAtualizacao, retorno!.codMotorista!);
  }

  Future<List<SolicitacaoMotorista>?> fetchSolicitacoesMotorista(
      {int indBuscaChamadosRaio = 0, bool isAdm = false}) async {
    var retorno = await getCurrentUser();
    if (retorno != null) {
      if (retorno.indTipo == 1) {
        List<SolicitacaoMotorista> lista =
            await _userRepository.buscaSolicitacoesMotorista(
                retorno.usuarioResp!.motoristas!.first.codMotorista!,
                tipStatus: indBuscaChamadosRaio);
        return lista;
      } else if (retorno.indTipo == 2) {
        // List<SolicitacaoMotorista> lista =
        //     await _userRepository.buscaSolicitacoesCem(retorno.codCem!,
        //         indBuscaChamadosRaio: indBuscaChamadosRaio);
        // return lista;
      }
    }
    return null;
  }

  Future<List<SolicitacaoMotorista>?> fetchSolicitacoesEmpresa(
      {int indBuscaChamadosRaio = 0,
      ConsultaRequest? req,
      bool isAdm = false}) async {
    var retorno = await getCurrentUser();
    if (isAdm) {
      List<SolicitacaoMotorista> lista =
          await _userRepository.buscaSolicitacoesEmpresa(-1,
              tipStatus: indBuscaChamadosRaio, req: req);
      return lista;
    } else {
      if (retorno != null) {
        if (retorno.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA) {
          List<SolicitacaoMotorista> lista =
              await _userRepository.buscaSolicitacoesEmpresa(
                  retorno.usuarioResp!.empresas!.first.codEmpresa!,
                  tipStatus: indBuscaChamadosRaio,
                  req: req);
          return lista;
        } else if (retorno.indTipo == 2) {
          // List<SolicitacaoMotorista> lista =
          //     await _userRepository.buscaSolicitacoesCem(retorno.codCem!,
          //         indBuscaChamadosRaio: indBuscaChamadosRaio);
          // return lista;
        }
      }
    }
    return null;
  }

  Future<List<SolicitacaoMotorista>?> fetchNovasCorridasMotorista(
      {int indBuscaChamadosRaio = 0, bool isAdm = false}) async {
    var retorno = await getCurrentUser();
    if (retorno != null) {
      if (retorno.indTipo == 1) {
        List<SolicitacaoMotorista> lista =
            await _userRepository.buscaNovasSolicitacoesMotorista(
          retorno.usuarioResp!.motoristas!.first.codMotorista ?? -1,
        );
        return lista;
      } else if (retorno.indTipo == 2) {
        // List<SolicitacaoMotorista> lista =
        //     await _userRepository.buscaSolicitacoesCem(retorno.codCem!,
        //         indBuscaChamadosRaio: indBuscaChamadosRaio);
        // return lista;
      }
    }
    return null;
  }

  Future<void> novoPedidoDeSocorro(double latitude, double longitude) async {
    var retorno = await getCurrentUser();
    await _userRepository.chamaPedidoDeSocorro(retorno!, latitude, longitude);
  }

  Future<void> novaCorrida(SolicitacaoMotorista sol) async {
    var retorno = await getCurrentUser();
    await _userRepository.chamaNovaCorrida(retorno!, sol);
  }

  Future<void> novoPedidoDeSocorroBlut() async {
    var retorno = await getCurrentUser();
    double latitude = (await getLatitude())!;
    double longitude = (await getLongitude())!;
    await _userRepository.chamaPedidoDeSocorro(retorno!, latitude, longitude);
  }

  Future<void> novoPedidoDeSocorroFlutuante(Usuario user) async {
    await _userRepository.chamaPedidoDeSocorro(user, 0, 0);
  }

  Future<void> atualizarLocalMotorista(
      double latitude, double longitude) async {
    try {
      var retorno = await getCurrentUser();

      if (retorno?.indTipo == 1 || retorno?.indTipo == 2) {
        await updateLatitudeLongitude(latitude, longitude);
        await _userRepository.updateLocalizacaoMotorista(
            retorno!, latitude, longitude);
      }
    } on Exception catch (e) {
      await updateLatitudeLongitude(latitude, longitude);
      await _userRepository.updateLocalizacaoMotorista(
          ApiBaseHelper.userSessao!, latitude, longitude);
    }
  }

  Future<List<MotoristasProximos>?> buscaMotoristasProximos() async {
    var retorno = await getCurrentUser();
    if (retorno != null) {
//1= motorista 2=cem
      if (retorno.indTipo == 1) {
        List<MotoristasProximos> lista =
            await _userRepository.buscaMotoristaProximos(retorno);
        return lista;
      } else if (retorno.indTipo == 2) {
        List<MotoristasProximos> lista =
            await _userRepository.buscaMotoristaCemProximos(retorno);
        return lista;
      }
    }
    return null;
  }

  Future<Usuario?> registraCem(CadastroCemRequest login, {login2}) async {
    var result = await _userRepository.registraCem(null, null, login,
        userInsert: login2);
    return result;
  }

  Future<Usuario?> atualizaUsuario(CadastroCemRequest login, {login2}) async {
    var result = await _userRepository.atualizaUser(null, null, login,
        userInsert: login2);
    return result;
  }

  Future<Usuario?> registraMotorista(CadastroCemRequest login) async {
    var result = await _userRepository.registraMotorista(null, null, login);
    if (ApiBaseHelper.userSessao != null) {
      if (ApiBaseHelper.userSessao!.indTipo == 1) {
        await saveLocalDB(ApiBaseHelper.userSessao ?? Usuario());
      }
    }
    return result;
  }

  Future<void> finalizarChamado(int numSeqChamado, int indStatusCorrida, {String? motivoCancelamento}) async {
    var retorno = await getCurrentUser();
    await _userRepository.finalizarChamado(numSeqChamado, indStatusCorrida, motivoCancelamento: motivoCancelamento);
  }

  Future<void> aceitarCorrida(int numSeqChamado, int indStatusCorrida) async {
    var retorno = await getCurrentUser();
    await _userRepository.aceitarCorrida(numSeqChamado, indStatusCorrida);
  }

  Future<List<DadosCorridas>> buscaDadosCorrida(
      {int? codEmpresa,
      int? codMotorista,
      DateTime? dtaIni,
      DateTime? dtaFim,
      bool? isAdm}) async {
    List<DadosCorridas> lista = await _userRepository.buscaTotaisCorridas(
        codEmpresa: codEmpresa,
        codMotorista: codMotorista,
        dtaIni: dtaIni,
        dtaFim: dtaFim,
        isAdm: isAdm);
    return lista;
  }

  Future<List<SaldosCorrida>> buscaDadosSaldosCorrida(
      {int? codEmpresa,
      int? codMotorista,
      DateTime? dtaIni,
      DateTime? dtaFim,
      bool? isAdm}) async {
    List<SaldosCorrida> lista = await _userRepository.buscaSaldosCorridas(
        codEmpresa: codEmpresa,
        codMotorista: codMotorista,
        dtaIni: dtaIni,
        dtaFim: dtaFim,
        isAdm: isAdm);
    return lista;
  }

  Future<void> changeStatusUser(UsuarioResp? usuario, int indStatus) async {
    var retorno = await getCurrentUser();
    await _userRepository.atualizaStatusOnOff(usuario!, indStatus);
  }

  Future<void> realizaPagamentoMotorista(
      String numSeqChamado, int codMotorista) async {
    await _userRepository.realizaPagamentoMotorista(
        numSeqChamado, codMotorista);
  }

  Future<void> realizaRecebimentoEstabelecimento(
      String numSeqChamado, int codEmpresa) async {
    await _userRepository.realizaConfirmaRecebimentoEstabelecimento(
        numSeqChamado, codEmpresa);
  }

  Future<void> atualizaConfigSys(ConfigSys login) async {
    var result = await _userRepository.atualizaConfigSys(login);
  }

  Future<ConfigSys> buscarConfigSys() async {
    var result = await _userRepository.buscaConfigSys();
    return result;
  }

  Future<double?> getVlrTaxa(double vlrKm) async {
    var result = await _userRepository.buscaVlrTaxa(vlrKm);
    return result;
  }

  /// Solicita recuperação de senha
  Future<void> solicitarRecuperacaoSenha(String email) async {
    try {
      final request = RecuperacaoSenhaRequest(email: email);
      await _userRepository.solicitarRecuperacaoSenha(request);
    } on ApiException catch (e) {
      Logger.logError(
        e,
        meta: {'email': email},
        tag: 'UserService.solicitarRecuperacaoSenha',
      );
      rethrow;
    } catch (e, stackTrace) {
      Logger.logError(
        e,
        stackTrace: stackTrace,
        meta: {'email': email},
        tag: 'UserService.solicitarRecuperacaoSenha',
      );
      throw ApiException(
        message: ErrorHandler.handleError(e, stackTrace: stackTrace),
        originalError: e,
      );
    }
  }

  /// Altera a senha do usuário logado
  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmacaoSenha,
  }) async {
    try {
      final request = AlteracaoSenhaRequest(
        senhaAtual: senhaAtual,
        novaSenha: novaSenha,
        confirmacaoSenha: confirmacaoSenha,
      );
      await _userRepository.alterarSenha(request);
    } on ApiException catch (e) {
      Logger.logError(
        e,
        tag: 'UserService.alterarSenha',
      );
      rethrow;
    } catch (e, stackTrace) {
      Logger.logError(
        e,
        stackTrace: stackTrace,
        tag: 'UserService.alterarSenha',
      );
      throw ApiException(
        message: ErrorHandler.handleError(e, stackTrace: stackTrace),
        originalError: e,
      );
    }
  }
}
