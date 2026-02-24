import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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

      // Obtém token
      _fcmToken = await _messaging.getToken();
      debugPrint('🔥 ==========================================');
      debugPrint('🔥 TOKEN FCM: $_fcmToken');
      debugPrint('🔥 ==========================================');
      debugPrint('💡 Copie este token para testar notificações no Firebase Console');

      // Escuta mudanças no token
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 Novo Token FCM: $newToken');
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
}

