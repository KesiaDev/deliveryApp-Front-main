import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/login/login_page.dart';
import 'package:flutter/material.dart';

class AppSession {
  static final UserService _userService = UserService();

  static void logout(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      _buildLoginRoute(),
      (_) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userService.logoffLocalDB().catchError((_) {});
    });
  }

  static PageRouteBuilder<dynamic> _buildLoginRoute() {
    return PageRouteBuilder(
      settings: const RouteSettings(name: AppRoutes.login),
      pageBuilder: (ctx, anim, secAnim) => const LoginPage(tipoLogin: 2),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  static void logoutComConfirmacao(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              logout(context);
            },
            child: const Text('Sair', style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }
}
