import 'package:flutter/material.dart';

class AppColors {
  static final Color purple = Color(0xFF8257E5);
  static final Color white = Color(0xFFFFFFFF);
  static final Color black = Color(0xFF514766);
  static final Color grey = Color(0xFF6E6680);
  static final Color lightGrey = Color(0xFFA6A1B2);
  static final Color border = Color(0xFFE1E1E6);
  static final Color chartSecondary = Color(0xFFE1E6E3);
  static final Color chartPrimary = darkGreen;

  //Greens
  static final Color lightGreen = Color(0xFFE1F5EC);
  static final Color green = Color(0xFFB8DBCB);
  static final Color darkGreen = Color(0xFF04D361);

  //Reds
  static final Color lightRed = Color(0xFFF5E9EC);
  static final Color red = Color(0xFFE5C5CF);
  static final Color darkRed = Color(0xFF9F292A);

  //LevelButton
  static final Color levelButtonFacil = Color(0xFFEBEBFC);
  static final Color levelButtonMedio = lightGreen;
  static final Color levelButtonDificil = Color(0xFFF5EFE9);
  static final Color levelButtonPerito = lightRed;

  static final Color levelButtonBorderFacil = Color(0xFFCECEF5);
  static final Color levelButtonBorderMedio = green;
  static final Color levelButtonBorderDificil = Color(0xFFE5D5C5);
  static final Color levelButtonBorderPerito = red;

  static final Color levelButtonTextFacil = Color(0xFF6363DB);
  static final Color levelButtonTextMedio = darkGreen;
  static final Color levelButtonTextDificil = Color(0xFFE8891C);
  static final Color levelButtonTextPerito = darkRed;

  static final MaterialColor primaryBlack = MaterialColor(
    _blackPrimaryValue,
    <int, Color>{
      50: Color(0xFF000000),
      100: Color(0xFF000000),
      200: Color(0xFF000000),
      300: Color(0xFF000000),
      400: Color(0xFF000000),
      500: Color(_blackPrimaryValue),
      600: Color(0xFF000000),
      700: Color(0xFF000000),
      800: Color(0xFF000000),
      900: Color(0xFF000000),
    },
  );
  static final int _blackPrimaryValue = 0xFF000000;
}
