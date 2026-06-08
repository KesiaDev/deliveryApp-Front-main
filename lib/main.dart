import 'dart:io';

import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/core/sentry_config.dart';
import 'package:delivery_front/shared/services/local_storage_service.dart';
import 'package:delivery_front/core/theme_controller.dart';
import 'package:delivery_front/services/firebase_messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const AndroidNotificationChannel _fcmChannel = AndroidNotificationChannel(
  'fool_high_importance',
  'Notificações Fool Entregas',
  description: 'Corridas e alertas do Fool Entregas',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Mensagem em background: ${message.notification?.title}');

  // Data-only messages: Android não exibe automaticamente — mostrar via local notification
  if (message.notification == null) {
    final plugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await plugin.initialize(initSettings);
    await plugin.show(
      message.hashCode,
      message.data['title'] as String? ?? 'Nova notificação',
      message.data['body'] as String? ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _fcmChannel.id,
          _fcmChannel.name,
          channelDescription: _fcmChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-aquece SharedPreferences e carrega preferência de tema
  await ThemeController.init();
  Future.microtask(() => LocalStorageService.tokenFCM);

  try {
    // Inicializa Firebase ANTES de tudo
    await Firebase.initializeApp();

    // Sign-in anônimo para autenticar Firestore operations
    // BUG-020: envolvido em try/catch próprio — falha em devices sem Google Play
    // Services não impede o app de subir
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      Logger.logError(e, tag: 'main.signInAnonymously',
          message: 'Firebase Auth anônimo falhou — app continua sem Auth');
    }

    // Configura background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Inicializa Firebase Messaging
    if (!kIsWeb) {
      await FirebaseMessagingService.initialize();
    }

    // Cria canal de notificação de alta importância (Android 8+)
    if (!kIsWeb) {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_fcmChannel);
      await plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ));
    }
    
    // Inicializa Sentry se DSN estiver disponível (opcional)
    await SentryConfig.initialize(
      dsn: const String.fromEnvironment('SENTRY_DSN', defaultValue: ''),
    );

    if (kIsWeb) {
      setPathUrlStrategy();
    } else if (Platform.isAndroid) {
      await initOneSignal();
    }
  } catch (e, stackTrace) {
    // Falhas durante a inicialização não devem impedir o app de subir
    Logger.logError(
      e,
      stackTrace: stackTrace,
      tag: 'main',
      message: 'Erro durante inicialização do app',
    );
  }

  runApp(AppWidget());
}

Future<void> initOneSignal() async {
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("2854750a-4282-4e06-9b17-3127cd90f012");

  // BUG-017/BUG-020: NÃO sobrescreve o token FCM do Firebase com o ID do OneSignal.
  // Os dois sistemas usam tokens diferentes. O Firebase FCM token é gerenciado
  // exclusivamente pelo FirebaseMessagingService e enviado ao backend no login.
  // O OneSignal é um sistema paralelo de notificação e não deve conflitar.

  await OneSignal.Notifications.requestPermission(true);
}
