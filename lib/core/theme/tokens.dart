import 'package:flutter/material.dart';

abstract class AppTokens {
  // ─── Brand ───────────────────────────────────────────────────────────────
  static const colorBrand = Color(0xFFEE1D52);
  static const colorBrandCyan = Color(0xFF69C9D0);

  // ─── Dark backgrounds ────────────────────────────────────────────────────
  static const colorBgBase = Color(0xFF000000);
  static const colorBgSurface = Color(0xFF121212);
  static const colorBgCard = Color(0xFF1C1C1E);
  static const colorBgOverlay = Color(0x73000000);

  // ─── Light backgrounds ───────────────────────────────────────────────────
  static const colorBgLight = Color(0xFFFFFFFF);
  static const colorBgLightSurface = Color(0xFFF2F2F2);
  static const colorBgLightCard = Color(0xFFEFEFEF);

  // ─── Text ────────────────────────────────────────────────────────────────
  static const colorTextPrimary = Color(0xFFFFFFFF);
  static const colorTextPrimaryDark = Color(0xFF000000);
  static const colorTextSecondary = Color(0xB3FFFFFF);
  static const colorTextSecondaryDark = Color(0xFF8A8A8A);
  static const colorTextBrand = Color(0xFFEE1D52);

  // ─── States ──────────────────────────────────────────────────────────────
  static const colorLike = Color(0xFFEE1D52);
  static const colorLiveRed = Color(0xFFFE2C55);
  static const colorVerified = Color(0xFF20D5EC);
  static const colorFollowBtn = Color(0xFFEE1D52);
  static const colorDivider = Color(0x1FFFFFFF);
  static const colorDividerLight = Color(0xFFE8E8E8);

  // ─── Spacing ─────────────────────────────────────────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;
  static const double space56 = 56;

  // ─── Radii ───────────────────────────────────────────────────────────────
  static const double radiusNone = 0;
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusPill = 999;

  // ─── Icon sizes ──────────────────────────────────────────────────────────
  static const double iconSidebar = 28;
  static const double iconNav = 24;
  static const double iconHeader = 22;
  static const double iconInline = 20;

  // ─── Text styles ─────────────────────────────────────────────────────────
  static const titleL = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3);
  static const titleM = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3);
  static const bodyM = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4);
  static const bodyS = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4);
  static const labelM = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2);
  static const labelS = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, height: 1.2);
  static const caption = TextStyle(fontSize: 10, fontWeight: FontWeight.w400, height: 1.2);
}
