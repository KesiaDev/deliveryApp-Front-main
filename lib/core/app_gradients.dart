import 'dart:ui';

import 'package:flutter/material.dart';

class AppGradients {
  static final linear = LinearGradient(
    colors: [
      Color.fromRGBO(16, 7, 7, 0.93),
      Color.fromRGBO(16, 7, 7, 0.93),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    transform: GradientRotation(2.13959913 * 3.14),
  );
}
