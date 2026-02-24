import 'package:flutter/material.dart';
import 'theme_components.dart';

class CorridaCard extends StatelessWidget {
  final String title;
  final String distance;
  final String value;
  final String status;
  final Color statusColor;
  final VoidCallback onPrimaryAction;
  final String? actionLabel;
  final bool showAction;

  const CorridaCard({
    Key? key,
    required this.title,
    required this.distance,
    required this.value,
    required this.status,
    required this.statusColor,
    required this.onPrimaryAction,
    this.actionLabel,
    this.showAction = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      minHeight: kCardMinHeightSmall,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: kPrimaryRed.withOpacity(0.12),
            child: Icon(Icons.motorcycle, color: kPrimaryRed),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text("$distance • $value", style: kSubtitleStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(label: status, color: statusColor),
              if (showAction) ...[
                const SizedBox(height: 10),
                ActionButton(
                  label: actionLabel ?? "Aceitar",
                  width: 92,
                  onTap: onPrimaryAction,
                ),
              ],
            ],
          )
        ],
      ),
    );
  }
}
