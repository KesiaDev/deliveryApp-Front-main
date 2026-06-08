import 'package:delivery_front/core/app_gradients.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const routeName = AppRoutes.splash;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final LoginControler _controller;
  late final VideoPlayerController _videoController;
  bool _bootstrapCalled = false;

  @override
  void initState() {
    super.initState();
    _controller = LoginControler(context);
    _videoController = VideoPlayerController.asset(
      'assets/videos/flash_screen.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );
    _videoController.addListener(_onVideoUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initVideo());
  }

  Future<void> _initVideo() async {
    await _videoController.initialize();
    if (!mounted) return;
    setState(() {});
    await _videoController.play();
  }

  void _onVideoUpdate() {
    if (_bootstrapCalled) return;
    if (!_videoController.value.isInitialized) return;
    final duration = _videoController.value.duration;
    final position = _videoController.value.position;
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 100) {
      _bootstrapCalled = true;
      _videoController.removeListener(_onVideoUpdate);
      _bootstrap();
    }
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
  void dispose() {
    _videoController.removeListener(_onVideoUpdate);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.linear,
        ),
        child: _videoController.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              )
            : Center(
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
