import 'package:delivery_front/admin/admin_empresas_page.dart';
import 'package:delivery_front/admin/admin_motoristas_page.dart';
import 'package:delivery_front/admin/admin_vlr_taxas.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/cadastro/cadastro_page.dart';
import 'package:delivery_front/confiSys/editar_config_sys_page.dart';
import 'package:delivery_front/core/app_colors.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/editar_cadastro/editar_cadastro_page.dart';
import 'package:delivery_front/escolha_perfil/escolha_perfil.dart';
import 'package:delivery_front/home/home_admin/home_admin_page.dart';
import 'package:delivery_front/home/home_empresa/home_page_empresa.dart';
import 'package:delivery_front/home/home_page.dart';
import 'package:delivery_front/info_corridas_page/info_corrida_page.dart';
import 'package:delivery_front/login/login_page.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_page.dart';
import 'package:delivery_front/empresa/corridas/lista_solicitacoes_empresa_page.dart';
// UI Moderna do Motorista
import 'package:delivery_front/ui/home_page_modern.dart';
import 'package:delivery_front/ui/corridas_list_page.dart';
import 'package:delivery_front/home/map_page.dart';
import 'package:delivery_front/modules/monitoring/screens/available_rides_screen.dart';
import 'package:delivery_front/saldos/saldos_page.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/shared/terms_of_use.dart';
// ConfigSys está em usuario.dart, mas vamos garantir que está importado
import 'package:delivery_front/splash/splash_page.dart';
// Novos módulos isolados
import 'package:delivery_front/modules/chat/screens/chat_screen.dart';
import 'package:delivery_front/modules/chat/screens/chat_list_screen.dart';
import 'package:delivery_front/modules/rating/screens/rating_screen.dart';
import 'package:delivery_front/modules/rating/screens/rating_history_screen.dart' show RatingHistoryScreen;
import 'package:delivery_front/modules/tracking/screens/live_tracking_screen.dart';
import 'package:delivery_front/modules/payments/screens/payment_method_selection_screen.dart';
import 'package:delivery_front/modules/payments/screens/payment_review_screen.dart';
import 'package:delivery_front/modules/payments/models/payment_model.dart';
import 'package:delivery_front/analytics/analytics_dashboard_page.dart';
import 'package:delivery_front/services/advanced_notification_service.dart';
import 'package:delivery_front/seguranca/recuperacao_senha_page.dart';
import 'package:delivery_front/seguranca/alteracao_senha_page.dart';
import 'package:delivery_front/seguranca/biometric_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  ThemeData _buildTheme() {
    final base = ThemeData.light();
    final colorScheme =
        ColorScheme.fromSwatch(primarySwatch: AppColors.primaryBlack);
    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: AppColors.primaryBlack,
      hintColor: AppColors.primaryBlack,
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: Colors.black),
        hintStyle: TextStyle(color: AppColors.border),
        errorStyle: const TextStyle(color: Colors.black),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(32),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.black,
        decorationColor: Colors.black,
        displayColor: Colors.white,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE53935),
        secondary: Color(0xFFE53935),
        surface: Color(0xFF1E1E1E),
      ),
      primaryColor: const Color(0xFFE53935),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFF1E1E1E),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE53935)),
          borderRadius: BorderRadius.circular(32),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        decorationColor: Colors.white,
        displayColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
        ),
      ),
      dividerColor: Colors.white12,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Rotas que precisam retornar tipos específicos
      case AppRoutes.termos:
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => const TermsOfUse(),
        );
      // Rotas dos novos módulos (isolados)
      case AppRoutes.chatList: {
        final args = settings.arguments as Map<String, dynamic>?;
        final currentUserId = args?['currentUserId'] as String?;
        if (currentUserId == null || currentUserId.isEmpty) {
          // Parâmetro obrigatório faltando - redirecionar para splash
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SplashPage(),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChatListScreen(
            currentUserId: currentUserId,
            currentUserName: args?['currentUserName'] as String? ?? '',
            currentUserType: args?['currentUserType'] as String? ?? 'empresa',
          ),
        );
      }
      case AppRoutes.chat: {
        final args = settings.arguments as Map<String, dynamic>?;
        final corridaId = args?['corridaId'] as String?;
        if (corridaId == null || corridaId.isEmpty) {
          // Parâmetro obrigatório faltando - redirecionar para splash
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SplashPage(),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChatScreen(
            corridaId: corridaId,
            motoristaId: args?['motoristaId'] as String? ?? '',
            motoristaName: args?['motoristaName'] as String? ?? '',
            empresaId: args?['empresaId'] as String? ?? '',
            empresaName: args?['empresaName'] as String? ?? '',
            currentUserId: args?['currentUserId'] as String? ?? '',
            currentUserName: args?['currentUserName'] as String? ?? '',
            currentUserType: args?['currentUserType'] as String? ?? 'empresa',
          ),
        );
      }
      case AppRoutes.rating: {
        final args = settings.arguments as Map<String, dynamic>?;
        final corridaId = args?['corridaId'] as String?;
        if (corridaId == null || corridaId.isEmpty) {
          // Parâmetro obrigatório faltando - redirecionar para splash
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SplashPage(),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RatingScreen(
            corridaId: corridaId,
            avaliadorId: args?['avaliadorId'] as String? ?? '',
            avaliadorName: args?['avaliadorName'] as String? ?? '',
            avaliadorType: args?['avaliadorType'] as String? ?? 'empresa',
            avaliadoId: args?['avaliadoId'] as String? ?? '',
            avaliadoName: args?['avaliadoName'] as String? ?? '',
            avaliadoType: args?['avaliadoType'] as String? ?? 'motorista',
          ),
        );
      }
      case AppRoutes.ratingHistory: {
        final args = settings.arguments as Map<String, dynamic>?;
        String? userId = args?['userId'] as String?;
        
        // Se userId não foi fornecido, tenta pegar da sessão atual
        if (userId == null || userId.isEmpty) {
          userId = ApiBaseHelper.userSessao?.codUsuario?.toString();
        }
        
        if (userId == null || userId.isEmpty) {
          // Parâmetro obrigatório faltando - redirecionar para splash
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SplashPage(),
          );
        }
        
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RatingHistoryScreen(userId: userId!),
        );
      }
      case AppRoutes.liveTracking: {
        final args = settings.arguments as Map<String, dynamic>?;
        final corridaId = args?['corridaId'] as String?;
        if (corridaId == null || corridaId.isEmpty) {
          // Parâmetro obrigatório faltando - redirecionar para splash
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SplashPage(),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LiveTrackingScreen(
            corridaId: corridaId,
            trackedUserId: args?['trackedUserId'] as String? ?? '',
            initialLatitude: args?['initialLatitude'] as double? ?? 0.0,
            initialLongitude: args?['initialLongitude'] as double? ?? 0.0,
          ),
        );
      }
      case AppRoutes.paymentMethodSelection: {
        final args = settings.arguments as Map<String, dynamic>?;
        final corridaId = args?['corridaId'] as String?;
        if (corridaId == null || corridaId.isEmpty) {
          // Parâmetro obrigatório faltando - redirecionar para splash
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SplashPage(),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PaymentMethodSelectionScreen(
            corridaId: corridaId,
            amount: args?['amount'] as double? ?? 0.0,
            description: args?['description'] as String?,
          ),
        );
      }
      case AppRoutes.paymentReview: {
        final args = settings.arguments as Map<String, dynamic>?;
        final corridaId = args?['corridaId'] as String?;
        if (corridaId == null || corridaId.isEmpty) {
          // Parâmetro obrigatório faltando - redirecionar para splash
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SplashPage(),
          );
        }
        final methodString = args?['method'] as String?;
        final method = methodString != null
            ? PaymentMethod.values.firstWhere(
                (e) => e.name == methodString.toLowerCase(),
                orElse: () => PaymentMethod.cash,
              )
            : PaymentMethod.cash;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PaymentReviewScreen(
            corridaId: corridaId,
            amount: args?['amount'] as double? ?? 0.0,
            method: method,
            description: args?['description'] as String?,
          ),
        );
      }
      // Login e Cadastro agora estão nas rotas nomeadas diretamente
      case AppRoutes.map:
        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (_) => const MapPage(),
        );
      case AppRoutes.corridas:
        final args = settings.arguments as Map<String, dynamic>?;
        final indTipoDefault = args?['indTipoDefault'] as int? ?? 99;
        // Usar página moderna para motorista
        if (ApiBaseHelper.userSessao?.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
          // Novas corridas → Firebase real-time (AvailableRidesScreen)
          if (indTipoDefault == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA) {
            final user = ApiBaseHelper.userSessao!;
            return MaterialPageRoute<dynamic>(
              settings: settings,
              builder: (_) => AvailableRidesScreen(
                motoristaId: user.codUsuario?.toString() ?? '',
                motoristaName: user.desNome ?? 'Motorista',
              ),
            );
          }
          return MaterialPageRoute<dynamic>(
            settings: settings,
            builder: (_) => CorridasListPage(
              indTipoDefault: indTipoDefault,
            ),
          );
        }
        // Versão antiga para compatibilidade
        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (_) => ListaSolicitacoesMotoristaPage(
            indTipoDefault: indTipoDefault,
          ),
        );
      case AppRoutes.corridasEmpresa:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (_) => ListaSolicitacoesEmpresaPage(
            indTipoDefault: args?['indTipoDefault'] as int? ?? -1,
          ),
        );
      case AppRoutes.saldos:
        final args = settings.arguments as Map<String, dynamic>?;
        final isAdm = args?['isAdm'] as bool? ?? false;
        final userConsulta = args?['userConsulta'];
        if (isAdm && userConsulta != null) {
          return MaterialPageRoute<dynamic>(
            settings: settings,
            builder: (_) => SaldosPage.second(
              isAdm: true,
              userConsulta: userConsulta,
            ),
          );
        }
        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (_) => SaldosPage(
            userInfo: args?['userInfo'],
          ),
        );
      default:
        // Rota não encontrada - redirecionar para splash
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashPage(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inicializa serviço de notificações avançadas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdvancedNotificationService.initialize(context);
    });

    return MaterialApp(
      navigatorKey: AdvancedNotificationService.navigatorKey,
      title: 'Fool Delivery',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.escolhaPerfil: (_) => const EscolhaPerfil(),
        AppRoutes.home: (context) {
          final user = ApiBaseHelper.userSessao;
          if (user?.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
            return HomePageModern(user: user);
          }
          return HomePage();
        },
        AppRoutes.homeAdmin: (_) => HomeAdminPage(),
        AppRoutes.homeEmpresa: (_) => HomePageEmpresa(),
        // AppRoutes.termos movido para _generateRoute para retornar bool?
        AppRoutes.login: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return LoginPage(
            tipoLogin: args?['tipoLogin'] as int? ?? 2,
          );
        },
        AppRoutes.cadastro: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final tipoLogin = args?['tipoLogin'] as int?;
          if (tipoLogin == null) {
            // Se não fornecido, usar padrão baseado no contexto
            return CadastroPage(
              tipoLogin: 2, // Empresa por padrão
            );
          }
          return CadastroPage(
            tipoLogin: tipoLogin,
          );
        },
        AppRoutes.infoCorrida: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic> && args['userInfo'] != null) {
            return InfoCorridaPage(
              userInfo: args['userInfo'],
              isAdm: args['isAdm'] as bool?,
            );
          }
          // Fallback para userSessao se não fornecido
          final userSessao = ApiBaseHelper.userSessao;
          if (userSessao != null) {
            return InfoCorridaPage(
              userInfo: userSessao,
              isAdm: false,
            );
          }
          // Se não houver usuário, redirecionar para login
          return const SplashPage();
        },
        AppRoutes.adminEmpresas: (_) => AdminEmpresaPage(
          userInfo: ApiBaseHelper.userSessao ?? Usuario(),
        ),
        AppRoutes.adminMotoristas: (_) => AdminMotoristaPage(
          userInfo: ApiBaseHelper.userSessao ?? Usuario(),
        ),
        AppRoutes.adminTaxas: (_) => AdminVlrTaxasPage(
          userInfo: ApiBaseHelper.userSessao ?? Usuario(),
        ),
        AppRoutes.configSistema: (context) {
          // Tenta pegar argumentos passados, senão busca da API ou cria vazio
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic> && args['usuarioEdicao'] != null) {
            return EditarConfigSysPage(
              usuarioEdicao: args['usuarioEdicao'] as ConfigSys,
            );
          }
          // Se não tiver argumentos, cria um ConfigSys vazio com valores padrão
          return EditarConfigSysPage(
            usuarioEdicao: ConfigSys(
              vlrKmRodado: 0.0,
              vlrPercentualDescontoMotorista: 0.0,
              vlrTaxaApp: 0.0,
              raioBuscaCorridas: 25,
            ),
          );
        },
        AppRoutes.editarCadastro: (_) => EditarCadastroPage(
          usuarioEdicao: ApiBaseHelper.userSessao ?? Usuario(),
        ),
        AppRoutes.recuperacaoSenha: (_) => const RecuperacaoSenhaPage(),
        AppRoutes.alteracaoSenha: (_) => const AlteracaoSenhaPage(),
        AppRoutes.biometricSettings: (_) => const BiometricSettingsPage(),
        AppRoutes.analytics: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return AnalyticsDashboardPage(
            isAdm: args?['isAdm'] as bool?,
            codEmpresa: args?['codEmpresa'] as int?,
            codMotorista: args?['codMotorista'] as int?,
          );
        },
        // Rotas dos novos módulos (isolados)
        // As rotas dos módulos serão adicionadas via onGenerateRoute
        // para permitir argumentos dinâmicos
      },
      onGenerateRoute: _generateRoute,
    );
  }
}
