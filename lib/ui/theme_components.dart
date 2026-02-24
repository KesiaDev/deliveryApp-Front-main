import 'package:flutter/material.dart';

const Color kPrimaryRed = Color(0xFFB63030);
const Color kBackground = Color(0xFFF5F6F8);
const Color kCardWhite = Colors.white;
const double kRadius = 16.0;
const double kCardMinHeightSmall = 110.0;
const double kCardMinHeightLarge = 160.0;
const double kSectionSpacing = 16.0;

final TextStyle kTitleStyle = const TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: Colors.black87,
);

final TextStyle kSubtitleStyle = const TextStyle(
  fontSize: 13,
  color: Colors.black54,
);

final TextStyle kNumberStyle = const TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w800,
  color: Colors.black87,
);

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? minHeight;

  const AppCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.minHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: child,
    );
  }
}

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final Widget? trailing;

  const AppAppBar({Key? key, required this.title, this.showBack = false, this.trailing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: kCardWhite,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 0,
      leadingWidth: 56,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : Builder(
              builder: (BuildContext context) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF1A1A1A),
                      size: 20,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                  ),
                );
              },
            ),
      title: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Text(title, style: kTitleStyle),
      ),
      actions: trailing != null ? [Padding(padding: const EdgeInsets.only(right: 8.0), child: trailing!)] : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double? width;

  const ActionButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: kPrimaryRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({Key? key, required this.label, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// KPI circular component (thicker ring, large center number)
class KpiCircle extends StatelessWidget {
  final double size;
  final int value;
  final double ringWidth;
  final Color color;
  final String label;

  const KpiCircle({
    Key? key,
    required this.value,
    this.size = 80,
    this.ringWidth = 6,
    this.color = kPrimaryRed,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: ringWidth),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0,4))
                  ],
                ),
              ),
              Text(
                "$value",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: kSubtitleStyle),
              const SizedBox(height: 6),
              Text("$value", style: kNumberStyle),
            ],
          ),
        ),
      ],
    );
  }
}
