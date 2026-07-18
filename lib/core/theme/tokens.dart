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

// ── Top-level convenience aliases ─────────────────────────────────────────────
// Allows using bare names (colorBgBase, space16 …) without AppTokens prefix.
const colorBrand            = AppTokens.colorBrand;
const colorBrandCyan        = AppTokens.colorBrandCyan;
const colorBgBase           = AppTokens.colorBgBase;
const colorBgSurface        = AppTokens.colorBgSurface;
const colorBgCard           = AppTokens.colorBgCard;
const colorBgOverlay        = AppTokens.colorBgOverlay;
const colorBgLight          = AppTokens.colorBgLight;
const colorBgLightSurface   = AppTokens.colorBgLightSurface;
const colorBgLightCard      = AppTokens.colorBgLightCard;
const colorTextPrimary      = AppTokens.colorTextPrimary;
const colorTextPrimaryDark  = AppTokens.colorTextPrimaryDark;
const colorTextSecondary    = AppTokens.colorTextSecondary;
const colorTextSecondaryDark = AppTokens.colorTextSecondaryDark;
const colorTextBrand        = AppTokens.colorTextBrand;
const colorLike             = AppTokens.colorLike;
const colorLiveRed          = AppTokens.colorLiveRed;
const colorVerified         = AppTokens.colorVerified;
const colorFollowBtn        = AppTokens.colorFollowBtn;
const colorDivider          = AppTokens.colorDivider;
const colorDividerLight     = AppTokens.colorDividerLight;
const double space2         = AppTokens.space2;
const double space4         = AppTokens.space4;
const double space8         = AppTokens.space8;
const double space12        = AppTokens.space12;
const double space16        = AppTokens.space16;
const double space20        = AppTokens.space20;
const double space24        = AppTokens.space24;
const double space32        = AppTokens.space32;
const double space48        = AppTokens.space48;
const double space56        = AppTokens.space56;
const double radiusNone     = AppTokens.radiusNone;
const double radiusSm       = AppTokens.radiusSm;
const double radiusMd       = AppTokens.radiusMd;
const double radiusLg       = AppTokens.radiusLg;
const double radiusPill     = AppTokens.radiusPill;
const double iconSidebar    = AppTokens.iconSidebar;
const double iconNav        = AppTokens.iconNav;
const double iconHeader     = AppTokens.iconHeader;
const double iconInline     = AppTokens.iconInline;

// ── Animation durations ───────────────────────────────────────────────────────
const durationNormal = Duration(milliseconds: 250);
const durationFast   = Duration(milliseconds: 150);
const durationSlow   = Duration(milliseconds: 400);
const durationLike   = Duration(milliseconds: 380);
const durationPulse  = Duration(milliseconds: 900);
