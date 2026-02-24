import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskColumn extends StatelessWidget {
  final IconData? icon;
  final Color? iconBackgroundColor;
  final String? title;
  final String? subtitle;
  TaskColumn({
    this.icon,
    this.iconBackgroundColor,
    this.title,
    this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    // Cores do padrão FOLL
    const Color backgroundColor = Color(0xFFFFFFFF);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);
    const Color iconColor = Color(0xFF9E9E9E);
    const Color cardBackground = Color(0xFFF8F6FB);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFFFDEEEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon ?? Icons.info_outline,
              size: 26.0,
              color: Colors.red,
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                SizedBox(height: 4.0),
                Text(
                  subtitle ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14.0,
                    fontWeight: FontWeight.normal,
                    color: textSecondary,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
