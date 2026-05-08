import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:delivery_front/shared/services/local_storage_service.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:dio/dio.dart';

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

      // Obtém token e persiste localmente
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await LocalStorageService.setTokenFCM(_fcmToken!);
      }
      debugPrint('🔥 ==========================================');
      debugPrint('🔥 TOKEN FCM: $_fcmToken');
      debugPrint('🔥 ==========================================');
      debugPrint('💡 Copie este token para testar notificações no Firebase Console');

      // Escuta mudanças no token — persiste e sincroniza com backend
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await LocalStorageService.setTokenFCM(newToken);
        debugPrint('🔄 Novo Token FCM: $newToken');
        await _syncTokenToBackend(newToken);
      });

      // Handlers agora são gerenciados pelo AdvancedNotificationService
      // Mantém logs para debug
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('📩 ==========================================');
        debugPrint('📩 MENSAGEM RECEBIDA (App aberto)');
        debugPrint('📩 Título: ${message.notification?.title}');
        debugPrint('📩 Corpo: ${message.notification?.body}');
        debugPrint('📩 Dados: ${message.data}');
        debugPrint('📩 ==========================================');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('📱 ==========================================');
        debugPrint('📱 APP ABERTO VIA NOTIFICAÇÃO');
        debugPrint('📱 Título: ${message.notification?.title}');
        debugPrint('📱 ==========================================');
      });

      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📱 App foi aberto por notificação (estava fechado)');
      }
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Firebase Messaging: $e');
    }
  }

  static String? getFcmToken() => _fcmToken;

  /// Sincroniza o token FCM com o backend quando o usuário já está logado.
  /// Chamado automaticamente no onTokenRefresh.
  static Future<void> _syncTokenToBackend(String token) async {
    try {
      final user = ApiBaseHelper.userSessao;
      if (user == null || user.jwt == null || user.codUsuario == null) return;

      final dio = Dio(ApiBaseHelper.options);
      dio.options.headers['Authorization'] = 'Bearer ${user.jwt}';
      await dio.patch(
        '/private/user/${user.codUsuario}/fcm-token',
        data: {'desTokenFcm': token},
      );
      debugPrint('✅ Token FCM sincronizado com backend: ${user.codUsuario}');
    } catch (e) {
      // Falha silenciosa — token será sincronizado no próximo login
      debugPrint('⚠️ Falha ao sincronizar token FCM: $e');
    }
  }
}

