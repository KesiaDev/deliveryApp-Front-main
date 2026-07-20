import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/shared/widgets/in_app_notification_widget.dart';
import 'package:flash/flash_helper.dart';
import 'package:google_fonts/google_fonts.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Serviço avançado para gerenciar notificações push
class AdvancedNotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static BuildContext? _context;

  /// Inicializa o serviço de notificações avançadas
  static Future<void> initialize(BuildContext? context) async {
    _context = context;

    // Firebase Messaging Handlers
    try {
      // Mensagens em foreground (app aberto)
      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          try {
            _handleForegroundMessage(message);
          } catch (e) {
            Logger.logError(e, tag: 'AdvancedNotificationService.onMessage');
          }
        },
        onError: (e) {
          Logger.logError(e, tag: 'AdvancedNotificationService.onMessage.stream');
        },
      );

      // App aberto via notificação (quando estava em background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // Verifica se app foi aberto via notificação (quando estava fechado)
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      Logger.logError(e, tag: 'AdvancedNotificationService.initialize');
    }

    // OneSignal Handlers (Android)
    try {
      OneSignal.Notifications.addClickListener((event) {
        _handleOneSignalNotification(event.notification);
      });
    } catch (e) {
      Logger.logError(e, tag: 'AdvancedNotificationService.OneSignal');
    }
  }

  /// Trata mensagens recebidas com app em foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    final title = (notification?.title as String?) ?? (data['title'] as String?) ?? 'Nova notificação';
    final body = (notification?.body as String?) ?? (data['body'] as String?) ?? '';

    // Dispara som/vibração via local notification (FCM em foreground não toca som no Android)
    try {
      _localNotifications.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fool_high_importance',
            'Notificações Fool Entregas',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {}

    // Mostra notificação in-app (usa navigatorKey para garantir contexto dentro do MaterialApp)
    try {
      _showInAppNotification(
        title: title,
        body: body,
        data: data,
      );
    } catch (_) {}

    // Log para debug
    Logger.logInfo(
      'Notificação recebida: $title',
      tag: 'NotificationService',
      meta: {'data': data},
    );
  }

  /// Trata quando usuário toca em uma notificação
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final tipo = data['tipo'] as String?;
    final corridaId = data['corridaId'] as String?;
    final chatId = data['chatId'] as String?;

    _navigateFromNotification(
      tipo: tipo,
      corridaId: corridaId,
      chatId: chatId,
      data: data,
    );
  }

  /// Trata notificações do OneSignal
  static void _handleOneSignalNotification(OSNotification notification) {
    final data = notification.additionalData;
    final tipo = data?['tipo'] as String?;
    final corridaId = data?['corridaId'] as String?;
    final chatId = data?['chatId'] as String?;

    _navigateFromNotification(
      tipo: tipo,
      corridaId: corridaId,
      chatId: chatId,
      data: data?.cast<String, dynamic>() ?? {},
    );
  }

  /// Navega para tela específica baseado no tipo de notificação
  static void _navigateFromNotification({
    String? tipo,
    String? corridaId,
    String? chatId,
    Map<String, dynamic>? data,
  }) {
    // Sempre usa navigatorKey.currentContext (dentro do MaterialApp, com Navigator)
    // _context vem do AppWidget (acima do MaterialApp) e não tem Navigator
    final context = navigatorKey.currentContext ?? _context;
    if (context == null) return;

    final isEmpresa = ApiBaseHelper.userSessao?.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (!context.mounted) return;
        switch (tipo) {
          case 'nova_corrida':
            if (isEmpresa) {
              Navigator.of(context).pushNamed(
                AppRoutes.corridasEmpresa,
                arguments: {'indTipoDefault': 0},
              );
            } else {
              Navigator.of(context).pushNamed(
                AppRoutes.corridas,
                arguments: {
                  'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA,
                },
              );
            }
            break;

          case 'corrida_aceita':
          case 'corrida_iniciada':
          case 'corrida_finalizada':
          case 'corrida_cancelada':
            if (isEmpresa) {
              Navigator.of(context).pushNamed(
                AppRoutes.corridasEmpresa,
                arguments: {'indTipoDefault': -1},
              );
            } else if (corridaId != null) {
              Navigator.of(context).pushNamed(
                AppRoutes.corridas,
                arguments: {
                  'indTipoDefault': -1,
                },
              );
            }
            break;

          case 'nova_mensagem':
            if (chatId != null && corridaId != null) {
              final currentUser = ApiBaseHelper.userSessao;
              Navigator.of(context).pushNamed(
                AppRoutes.chat,
                arguments: {
                  'corridaId': corridaId,
                  'chatId': chatId,
                  'currentUserId': currentUser?.codUsuario?.toString() ?? '',
                  'currentUserName': currentUser?.desNome ?? '',
                  'currentUserType': currentUser?.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                      ? 'motorista'
                      : 'empresa',
                },
              );
            } else {
              final currentUser = ApiBaseHelper.userSessao;
              Navigator.of(context).pushNamed(
                AppRoutes.chatList,
                arguments: {
                  'currentUserId': currentUser?.codUsuario?.toString() ?? '',
                  'currentUserName': currentUser?.desNome ?? '',
                  'currentUserType': currentUser?.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                      ? 'motorista'
                      : 'empresa',
                },
              );
            }
            break;

          case 'pagamento':
            Navigator.of(context).pushNamed(AppRoutes.saldos);
            break;

          case 'avaliacao':
            if (corridaId != null) {
              final currentUser = ApiBaseHelper.userSessao;
              Navigator.of(context).pushNamed(
                AppRoutes.rating,
                arguments: {
                  'corridaId': corridaId,
                  'avaliadorId': currentUser?.codUsuario?.toString() ?? '',
                  'avaliadorName': currentUser?.desNome ?? '',
                  'avaliadorType': currentUser?.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                      ? 'motorista'
                      : 'empresa',
                },
              );
            }
            break;

          default:
            break;
        }
      } catch (e) {
        debugPrint('❌ Erro ao navegar da notificação: $e');
      }
    });
  }

  /// Mostra notificação in-app (flash message ou overlay)
  static void _showInAppNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    // Sempre usa navigatorKey — é dentro do MaterialApp e tem acesso ao Overlay.
    // _context vem do AppWidget (acima do MaterialApp) e não tem Overlay.
    final context = navigatorKey.currentContext ?? _context;
    if (context == null) return;

    final tipo = data?['tipo'] as String?;
    Color backgroundColor = Colors.blue;
    IconData icon = Icons.notifications;

    // Define cor e ícone baseado no tipo
    switch (tipo) {
      case 'nova_corrida':
        backgroundColor = Colors.green;
        icon = Icons.motorcycle;
        break;
      case 'corrida_aceita':
        backgroundColor = Colors.orange;
        icon = Icons.check_circle;
        break;
      case 'corrida_finalizada':
        backgroundColor = Colors.blue;
        icon = Icons.done_all;
        break;
      case 'corrida_cancelada':
        backgroundColor = Colors.red;
        icon = Icons.cancel;
        break;
      case 'nova_mensagem':
        backgroundColor = Colors.purple;
        icon = Icons.chat;
        break;
      case 'pagamento':
        backgroundColor = Colors.green;
        icon = Icons.payment;
        break;
      case 'avaliacao':
        backgroundColor = Colors.amber;
        icon = Icons.star;
        break;
    }

    // Usa overlay para notificação in-app
    InAppNotificationOverlay.show(
      context: context,
      title: title,
      body: body,
      icon: icon,
      backgroundColor: backgroundColor,
      onTap: data != null && data['tipo'] != null
          ? () {
              _navigateFromNotification(
                tipo: data['tipo'] as String?,
                corridaId: data['corridaId'] as String?,
                chatId: data['chatId'] as String?,
                data: data,
              );
            }
          : null,
    );
  }

  /// Envia notificação local (para testes ou notificações internas)
  static void showLocalNotification({
    required String title,
    required String body,
    String? tipo,
    Map<String, dynamic>? data,
  }) {
    _showInAppNotification(
      title: title,
      body: body,
      data: {
        ...?data,
        'tipo': tipo,
      },
    );
  }

  /// Atualiza o contexto (chamar quando navegar entre telas)
  static void updateContext(BuildContext? context) {
    _context = context;
  }
}
