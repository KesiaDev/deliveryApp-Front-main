import 'dart:async';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/services/firebase_messaging_service.dart';
import 'package:delivery_front/shared/components/loading_dialog.dart';
import 'package:delivery_front/shared/models/loginRequest.dart';
import 'package:delivery_front/shared/services/local_storage_service.dart';
import 'package:delivery_front/seguranca/biometric_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginControler {
  final BuildContext context;

  UserService _userService = new UserService();

  LoginControler(this.context);

  String email = "";
  String senha = "";
  bool indLogado = false;

  void setEmail(String s) => email = s;
  void setSenha(String s) => senha = s;
  void setIndLogado(bool s) => indLogado = s;

  Future<LoginRequest> get credential async {
    // Timeout de 2s no token FCM para não bloquear login em redes lentas
    String tokenFcm = '';
    try {
      tokenFcm = await LocalStorageService.tokenFCM
          .timeout(const Duration(seconds: 2), onTimeout: () => '');
    } catch (_) {
      tokenFcm = '';
    }
    return LoginRequest(
      email: email,
      senha: senha,
      desTokenFcm: tokenFcm.isEmpty ? null : tokenFcm,
      indLogado: indLogado,
    );
  }

  Future<void> authenticate() async {
    print('🟡 [LOGIN_CONTROLLER] authenticate() chamado');
    print('🟡 [LOGIN_CONTROLLER] Email: $email');
    print('🟡 [LOGIN_CONTROLLER] Senha length: ${senha.length}');
    
    try {
      DialogBuilder(context).showLoadingIndicator("");
      
      print('🟡 [LOGIN_CONTROLLER] Chamando _userService.login...');
      final credentialData = await credential;
      print('🟡 [LOGIN_CONTROLLER] Credential email: ${credentialData.email}');
      print('🟡 [LOGIN_CONTROLLER] Credential senha length: ${credentialData.senha?.length ?? 0}');
      
      // Timeout de segurança (30s): evita ficar travado em "Aguarde" indefinidamente
      final result = await _userService
          .login(credentialData)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw ApiException(
          message: 'Tempo esgotado. Verifique sua conexão com a internet e tente novamente.',
        );
      });
      print('🟡 [LOGIN_CONTROLLER] Resultado recebido: ${result != null ? "SUCESSO" : "NULL"}');
      
      if (result != null) {
        print('🟡 [LOGIN_CONTROLLER] indTipo: ${result.indTipo}');
        print('🟡 [LOGIN_CONTROLLER] codUsuario: ${result.codUsuario}');
        print('🟡 [LOGIN_CONTROLLER] jwt presente: ${result.jwt != null && result.jwt!.isNotEmpty}');
        
        if (result.indTipo == 2) {
          result.usuario = email;
          result.desSenha = senha;
        }

        await _userService.saveLocalDB(result);
        print('🟡 [LOGIN_CONTROLLER] Usuário salvo no banco local');

        // Sincroniza token FCM agora que o JWT está disponível
        if (!kIsWeb) {
          FirebaseMessagingService.syncAfterLogin().catchError((_) {});
        }

        // Salva credenciais para biometria (se habilitada)
        final biometricEnabled = await BiometricService.isBiometricEnabled();
        if (biometricEnabled) {
          await LocalStorageService.setString('saved_email', email);
          await LocalStorageService.setString('saved_password', senha);
        }

        if (result.indTipo == ApiBaseHelper.IND_TIP_PERFIL_99_ADMIN_SISTEMA) {
          print('🟡 [LOGIN_CONTROLLER] Redirecionando para HomeAdmin');
          if (!context.mounted) return;
          await Navigator.pushReplacementNamed(
            context,
            AppRoutes.homeAdmin,
          );
        } else {
          if (result.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA ||
              result.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA) {
            if (kIsWeb) {
              if (!context.mounted) return;
              showToast(
                  context, "Login permitido somente via plataformas mobile.");
              if (!kDebugMode) return;
            }
          }

          if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == result.indTipo) {
            // Verificar se usuarioResp não é null antes de acessar
            if (result.usuarioResp != null) {
              if (result.usuarioResp!.desLatitude != null) {
                ApiBaseHelper.lat = result.usuarioResp!.desLatitude!;
              }
              if (result.usuarioResp!.desLongitude != null) {
                ApiBaseHelper.long = result.usuarioResp!.desLongitude!;
              }
            }
          }

          print('🟡 [LOGIN_CONTROLLER] Redirecionando para Home');
          if (!context.mounted) return;
          await Navigator.pushReplacementNamed(
            context,
            AppRoutes.home,
          );
        }
      } else {
        print('🔴 [LOGIN_CONTROLLER] Resultado é NULL - login falhou');
        if (!context.mounted) return;
        showToast(context, "E-mail ou senha inválidos, tente novamente");
      }
    } on ApiException catch (e) {
      print('🔴 [LOGIN_CONTROLLER] ApiException capturada: ${e.message}');
      print('🔴 [LOGIN_CONTROLLER] Status Code: ${e.statusCode}');
      if (context.mounted) {
        final friendlyMessage = ErrorHandler.handleError(e);
        showToast(context, friendlyMessage);
      }
    } catch (e, stackTrace) {
      print('🔴 [LOGIN_CONTROLLER] Erro genérico: ${e.toString()}');
      print('🔴 [LOGIN_CONTROLLER] StackTrace: $stackTrace');
      if (context.mounted) {
        final friendlyMessage = ErrorHandler.handleError(e, stackTrace: stackTrace);
        showToast(context, friendlyMessage);
      }
    } finally {
      try {
        if (context.mounted) {
          DialogBuilder(context).hideOpenDialog();
        }
      } catch (_) {
        // Garante que erros ao fechar o dialog não deixem o app travado
      }
    }
  }

  Future<bool> authenticateCurrentUser() async {
    try {
      var user = await _userService.getCurrentUser();
      if (user != null) {
        setEmail(user.usuario!);
        setSenha(user.desSenha!);
        setIndLogado(true);
        // authenticate() já gerencia o loading dialog e navega internamente
        await authenticate();

        var result = await _userService.getCurrentUser();
        return result != null;
      }
      return false;
    } on ApiException catch (e) {
      Logger.logWarn(
        'Erro ao autenticar usuário atual: ${e.message}',
        tag: 'LoginController.authenticateCurrentUser',
      );
      return false;
    } catch (e, stackTrace) {
      final friendlyMessage = ErrorHandler.handleError(e, stackTrace: stackTrace);
      showToast(context, friendlyMessage);
      return false;
    }
  }

  static void showToast(BuildContext context, String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}
