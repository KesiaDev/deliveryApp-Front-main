import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget para exibir notificações in-app persistentes
class InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InAppNotificationWidget({
    Key? key,
    required this.title,
    required this.body,
    this.icon = Icons.notifications,
    this.backgroundColor = Colors.blue,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<InAppNotificationWidget> createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<InAppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.onTap?.call();
                dismiss();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.body,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: dismiss,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay para exibir notificações in-app
class InAppNotificationOverlay {
  static OverlayEntry? _overlayEntry;

  static void show({
    required BuildContext context,
    required String title,
    required String body,
    IconData icon = Icons.notifications,
    Color backgroundColor = Colors.blue,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Remove notificação anterior se existir
    dismiss();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 0,
        right: 0,
        child: InAppNotificationWidget(
          title: title,
          body: body,
          icon: icon,
          backgroundColor: backgroundColor,
          onTap: onTap,
          onDismiss: dismiss,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Auto-dismiss após duração
    Future.delayed(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
