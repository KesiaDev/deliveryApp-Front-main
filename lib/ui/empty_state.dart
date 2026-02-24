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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: kBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(18),
            child: Icon(icon, size: 48, color: Colors.black26),
          ),
          const SizedBox(height: 12),
          Text(title, style: kTitleStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          Text(subtitle, style: kSubtitleStyle.copyWith(color: Colors.black38)),
        ],
      ),
    );
  }
}

