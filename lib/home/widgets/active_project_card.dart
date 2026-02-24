import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ActiveProjectsCard extends StatelessWidget {
  final Color? cardColor;
  final double? loadingPercent;
  final String? title;
  final String? subtitle;

  ActiveProjectsCard({
    this.cardColor,
    this.loadingPercent,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Cores do padrão FOLL
    const Color primaryRed = Color(0xFFE53935);
    const Color backgroundColor = Color(0xFFFFFFFF);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);
    const Color borderColor = Color(0xFFE6E7EB);
    const Color chartBackground = Color(0xFFF5F6FA);
    
    final percent = loadingPercent ?? 0.0;
    final percentValue = (percent * 100).roundToDouble();
    // Se percent >= 1.0, mostra o número absoluto (subtitle) ao invés da porcentagem
    final showAbsoluteValue = percent >= 1.0;
    
    return Expanded(
      flex: 1,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.0, right: 8.0),
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularPercentIndicator(
                animation: true,
                radius: 60.0,
                percent: percent > 1.0 ? 1.0 : percent,
                lineWidth: 10.0, // Linha mais grossa
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: chartBackground,
                progressColor: primaryRed,
                center: Text(
                  showAbsoluteValue ? (subtitle ?? '0') : '${percentValue.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  title ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14.0,
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                if (showAbsoluteValue && subtitle != null && subtitle!.isNotEmpty) ...[
                  SizedBox(height: 4.0),
                  Text(
                    subtitle ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.0,
                      color: textSecondary,
                      fontWeight: FontWeight.normal,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
