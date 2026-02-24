import 'package:delivery_front/core/app_gradients.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const routeName = AppRoutes.splash;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final LoginControler _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginControler(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final isAuthenticated = await _controller.authenticateCurrentUser();
    if (!mounted || isAuthenticated) return;
    if (!context.mounted) return;

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.login,
      arguments: {'tipoLogin': 2},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.linear,
        ),
        child: Center(
          child: Image.asset(
            AppImages.logo,
            height: 250,
            width: 250,
          ),
        ),
      ),
    );
  }
}
