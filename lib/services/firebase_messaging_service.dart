import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:delivery_front/shared/services/local_storage_service.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:dio/dio.dart';
import 'package:delivery_front/services/advanced_notification_service.dart';


class FirebaseMessagingService {
  static final _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  static Future<void> initialize() async {
    try {
      // Solicita permissão
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Firebase Messaging: Permissão concedida');
      } else {
        debugPrint('⚠️ Firebase Messaging: Permissão negada');
        return;
      }

      // Obtém token, persiste localmente e sincroniza com backend na inicialização
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await LocalStorageService.setTokenFCM(_fcmToken!);
        // BUG-017: sincroniza na inicialização, não só no refresh
        await _syncTokenToBackend(_fcmToken!);
      }
      debugPrint('🔥 ==========================================');
      debugPrint('🔥 TOKEN FCM: $_fcmToken');
      debugPrint('🔥 ==========================================');

      // Escuta mudanças no token — persiste e sincroniza com backend
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await LocalStorageService.setTokenFCM(newToken);
        debugPrint('🔄 Novo Token FCM: $newToken');
        await _syncTokenToBackend(newToken);
      });

      // BUG-018: NÃO registra onMessage aqui — AdvancedNotificationService
      // é o único responsável pelos handlers de mensagem. Duplo listener
      // causava notificações duplicadas.

      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📱 App foi aberto por notificação (estava fechado)');
        // AdvancedNotificationService gerencia a navegação via navigatorKey
      }
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Firebase Messaging: $e');
    }
  }

  static String? getFcmToken() => _fcmToken;

  /// Sincroniza o token FCM com o backend quando o usuário já está logado.
  /// Chamado automaticamente no onTokenRefresh e após login bem-sucedido.
  static Future<void> _syncTokenToBackend(String token) async {
    try {
      final user = ApiBaseHelper.userSessao;
      if (user == null || user.jwt == null || user.codUsuario == null) return;

      final base = ApiBaseHelper.baseUrl;
      final fullUrl = base.endsWith('/')
          ? '${base}private/user/${user.codUsuario}/fcm-token'
          : '$base/private/user/${user.codUsuario}/fcm-token';

      final dio = Dio(ApiBaseHelper.options);
      dio.options.headers['Authorization'] = 'Bearer ${user.jwt}';
      await dio.patch(fullUrl, data: {'desTokenFcm': token});
      debugPrint('✅ Token FCM sincronizado com backend: ${user.codUsuario}');
    } catch (e) {
      // Falha silenciosa — token será sincronizado no próximo login
      debugPrint('⚠️ Falha ao sincronizar token FCM: $e');
    }
  }

  /// Sincroniza o token FCM após login bem-sucedido.
  /// Deve ser chamado imediatamente após saveLocalDB() no LoginController,
  /// quando o JWT já está disponível em ApiBaseHelper.userSessao.
  static Future<void> syncAfterLogin() async {
    try {
      final token = _fcmToken ?? await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ syncAfterLogin: sem token FCM disponível');
        return;
      }
      _fcmToken = token;
      await _syncTokenToBackend(token);
    } catch (e) {
      debugPrint('⚠️ syncAfterLogin: erro ao sincronizar: $e');
    }
  }
}

