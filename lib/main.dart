import 'dart:io';

import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/core/sentry_config.dart';
import 'package:delivery_front/shared/services/local_storage_service.dart';
import 'package:delivery_front/services/firebase_messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Mensagem em background: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializa Firebase ANTES de tudo
    await Firebase.initializeApp();
    
    // Configura background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Inicializa Firebase Messaging
    if (!kIsWeb) {
      await FirebaseMessagingService.initialize();
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

  await OneSignal.Notifications.requestPermission(true);
  // Handlers adicionais podem ser configurados conforme necessidade.
}
