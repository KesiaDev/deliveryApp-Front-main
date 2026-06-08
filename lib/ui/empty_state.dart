import 'package:flutter/material.dart';
import 'theme_components.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyState({
    Key? key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.motorcycle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final iconBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFF5F6F8);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(18),
            child: Icon(icon, size: 48, color: onSurface.withOpacity(0.25)),
          ),
          const SizedBox(height: 12),
          Text(title, style: kTitleStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          Text(subtitle, style: kSubtitleStyle.copyWith(color: onSurface.withOpacity(0.45))),
        ],
      ),
    );
  }
}

