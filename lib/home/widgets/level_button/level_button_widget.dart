import 'package:delivery_front/core/core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelButtonWidget extends StatelessWidget {
  final String label;
  LevelButtonWidget({
    Key? key,
    required this.label,
  });

  final config = {
    "Polícia": {
      "color": AppColors.levelButtonFacil,
      "borderColor": AppColors.levelButtonBorderFacil,
      "fontColor": AppColors.levelButtonTextFacil,
    },
    "Atendimento Médico": {
      "color": AppColors.levelButtonMedio,
      "borderColor": AppColors.levelButtonBorderMedio,
      "fontColor": AppColors.levelButtonTextMedio,
    },
    "Bombeiros": {
      "color": AppColors.levelButtonDificil,
      "borderColor": AppColors.levelButtonBorderDificil,
      "fontColor": AppColors.levelButtonTextDificil,
    },
    "Rodoviaria": {
      "color": AppColors.levelButtonPerito,
      "borderColor": AppColors.levelButtonBorderPerito,
      "fontColor": AppColors.levelButtonTextPerito,
    },
  };

  Color get color => AppColors.levelButtonDificil;
  Color get borderColor => AppColors.levelButtonBorderDificil;
  Color get fontColor => AppColors.levelButtonTextDificil;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.fromBorderSide(BorderSide(
            color: borderColor,
          )),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.notoSans(color: fontColor, fontSize: 30),
          ),
        ));
  }
}
