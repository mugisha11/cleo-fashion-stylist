import 'package:flutter/material.dart';

/// Dashboard home (image 1) and AI stylist chat (image 2) design colors.
class DashboardUIColors {
  DashboardUIColors._();

  // ----- SHARED GRADIENT -----
  static const Color gradientTop = Color(0xFFF5F5F5);
  static const Color gradientBottom = Color(0xFFEAEAEA);
  // AI Chat page: light gray (top-left) → warm light brownish-gray (bottom-right)
  static const Color chatGradientTopLeft = Color(0xFFF2F2F2);
  static const Color chatGradientBottomRight = Color(0xFFE8E4E0);
  static const Color chatTopBarButtonBorder = Color(0xFFE0E0E0);
  // Home screen can use slightly different (light gray → lavender)
  static const Color homeGradientTop = Color(0xFFF0F0EE);
  static const Color homeGradientBottom = Color(0xFFE5E2EC);

  // ----- HOME (Image 1) -----
  static const Color homePrimaryText = Color(0xFF333333);
  static const Color homeInputBg = Color(0xFFEDEDED);
  static const Color homeInputBorder = Color(0xFFCCCCCC);
  static const Color homeChipBg = Color(0xFFE8E8E8);
  static const Color homeChipText = Color(0xFF333333);
  static const Color homeButtonBorder = Color(0xFF333333);
  static const Color homeSparkleBlue = Color(0xFF8FB6FB);
  static const Color giovanniPink = Color(0xFFFF4C5B);
  static const Color giovanniBlue = Color(0xFF4C7DFF);

  // ----- AI CHAT (Image 2 / reference) -----
  static const Color chatHeaderBg = Color(0xFFFFFFFF);
  static const Color chatTitle = Color(0xFF1F1F1F);
  static const Color chatAIBubble = Color(0xFF5B646B);
  static const Color chatUserBubble = Color(0xFF5B4B9E);
  static const Color chatAIAvatarDots = Color(0xFF7BA3F7);
  static const Color chatInputBg = Color(0xFF6F7479);
  static const Color chatInputCameraBg = Color(0xFF4A4D52);
  static const Color chatInputText = Color(0xFFFFFFFF);
  static const Color chatSendButtonBg = Color(0xFFFFFFFF);
  static const Color chatSendIcon = Color(0xFF1F1F1F);
  static const Color chatQuickReplyBg = Color(0xFFE8E8E8);
  static const Color chatQuickReplyText = Color(0xFF444444);
}
