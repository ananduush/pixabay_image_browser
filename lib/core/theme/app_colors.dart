import 'package:flutter/material.dart';

/// The Aperture palette: five values plus alpha variants of ink/black.
/// "Five values total. Everything else is photography."
abstract final class AppColors {
  static const Color paper = Color(0xFFFBFAF8);
  static const Color ink = Color(0xFF16130F);
  static const Color skeleton = Color(0xFFF2F0EC);
  static const Color critical = Color(0xFFA4392B);

  // Ink fills (rgba(22,19,15,x)).
  static const Color inkFill16 = Color(0x2916130F);
  static const Color inkFill9 = Color(0x1716130F);
  static const Color inkFill7 = Color(0x1216130F);
  static const Color inkFill55 = Color(0x0E16130F);

  // Secondary text (rgba(0,0,0,x)).
  static const Color text62 = Color(0x9E000000);
  static const Color text56 = Color(0x8F000000);
  static const Color text55 = Color(0x8C000000);
  static const Color text44 = Color(0x70000000);

  // Rules and strokes (rgba(0,0,0,x)).
  static const Color rule50 = Color(0x80000000);
  static const Color rule40 = Color(0x66000000);
  static const Color rule35 = Color(0x59000000);
  static const Color rule28 = Color(0x47000000);
  static const Color rule25 = Color(0x40000000);
  static const Color rule20 = Color(0x33000000);
  static const Color rule9 = Color(0x17000000);
  static const Color rule7 = Color(0x12000000);

  // Glass surfaces.
  static const Color glassFill = Color(0x80FBFAF8);
  static const Color glassBorder = Color(0xB3FFFFFF);
  static const Color glassGloss = Color(0x99FFFFFF);
  static const Color glassShadow = Color(0x2616130F);
  static const Color glassShadowSoft = Color(0x1216130F);

  // Tag chip hairline (rgba(255,255,255,.6)).
  static const Color chipBorder = Color(0x99FFFFFF);
}
