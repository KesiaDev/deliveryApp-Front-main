import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/shared/services/local_storage_service.dart';

/// Serviço para autenticação biométrica (Face ID / Touch ID / Fingerprint)
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica se o dispositivo suporta biometria
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      Logger.logError(e, tag: 'BiometricService.isDeviceSupported');
      return false;
    }
  }

  /// Verifica se há biometrias cadastradas no dispositivo
  static Future<bool> hasEnrolledBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (e) {
      Logger.logError(e, tag: 'BiometricService.hasEnrolledBiometrics');
      return false;
    }
  }

  /// Lista os tipos de biometria disponíveis
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      Logger.logError(e, tag: 'BiometricService.getAvailableBiometrics');
      return [];
    }
  }

  /// Verifica se a biometria está habilitada para o usuário
  static Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await LocalStorageService.getBool('biometric_enabled');
      return enabled ?? false;
    } catch (e) {
      Logger.logError(e, tag: 'BiometricService.isBiometricEnabled');
      return false;
    }
  }

  /// Habilita ou desabilita a biometria
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await LocalStorageService.setBool('biometric_enabled', enabled);
    } catch (e) {
      Logger.logError(e, tag: 'BiometricService.setBiometricEnabled');
    }
  }

  /// Autentica usando biometria
  static Future<bool> authenticate({
    String reason = 'Autentique-se para continuar',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Verifica se o dispositivo suporta
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        Logger.logWarn(
          'Dispositivo não suporta autenticação biométrica',
          tag: 'BiometricService.authenticate',
        );
        return false;
      }

      // Verifica se há biometrias cadastradas
      final canCheck = await hasEnrolledBiometrics();
      if (!canCheck) {
        Logger.logWarn(
          'Nenhuma biometria cadastrada no dispositivo',
          tag: 'BiometricService.authenticate',
        );
        return false;
      }

      // Tenta autenticar
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      Logger.logError(
        e,
        tag: 'BiometricService.authenticate',
        meta: {
          'code': e.code,
          'message': e.message,
        },
      );

      // Trata erros específicos
      switch (e.code) {
        case 'NotAvailable':
          Logger.logWarn(
            'Biometria não disponível',
            tag: 'BiometricService.authenticate',
          );
          break;
        case 'NotEnrolled':
          Logger.logWarn(
            'Nenhuma biometria cadastrada',
            tag: 'BiometricService.authenticate',
          );
          break;
        case 'LockedOut':
          Logger.logWarn(
            'Biometria bloqueada. Tente novamente mais tarde.',
            tag: 'BiometricService.authenticate',
          );
          break;
        case 'PermanentlyLockedOut':
          Logger.logWarn(
            'Biometria permanentemente bloqueada',
            tag: 'BiometricService.authenticate',
          );
          break;
      }

      return false;
    } catch (e, stackTrace) {
      Logger.logError(
        e,
        stackTrace: stackTrace,
        tag: 'BiometricService.authenticate',
      );
      return false;
    }
  }

  /// Obtém o tipo de biometria disponível como string amigável
  static Future<String> getBiometricTypeName() async {
    try {
      final available = await getAvailableBiometrics();
      
      if (available.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (available.contains(BiometricType.fingerprint)) {
        return 'Touch ID / Impressão Digital';
      } else if (available.contains(BiometricType.strong)) {
        return 'Autenticação Biométrica';
      } else if (available.contains(BiometricType.weak)) {
        return 'Autenticação Biométrica';
      } else {
        return 'Biometria';
      }
    } catch (e) {
      Logger.logError(e, tag: 'BiometricService.getBiometricTypeName');
      return 'Biometria';
    }
  }

  /// Verifica se pode usar biometria (suportado + habilitado + cadastrado)
  static Future<bool> canUseBiometric() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      final hasEnrolled = await hasEnrolledBiometrics();
      if (!hasEnrolled) return false;

      final isEnabled = await isBiometricEnabled();
      return isEnabled;
    } catch (e) {
      Logger.logError(e, tag: 'BiometricService.canUseBiometric');
      return false;
    }
  }
}
