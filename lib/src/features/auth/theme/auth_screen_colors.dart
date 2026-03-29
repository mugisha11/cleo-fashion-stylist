import 'package:flutter/material.dart';

/// Giovanni-style design tokens for auth screens (light theme from reference images).
/// Design-only; backend unchanged.
class AuthScreenColors {
  AuthScreenColors._();

  // ----- LOGIN SCREEN -----
  // Background gradient: top → bottom
  static const Color loginBgTop = Color(0xFFF0F0EE);
  static const Color loginBgBottom = Color(0xFFDCDADF);

  // Logo gradient (login): G + iovann coral→purple, last i blue
  static const Color loginLogoPink = Color(0xFFFF4C5B);
  static const Color loginLogoPurple = Color(0xFFA66DD9);
  static const Color loginLogoBlue = Color(0xFF4C7DFF);

  // Login: tagline, body text
  static const Color loginTagline = Color(0xFF555555);
  static const Color loginHeading = Color(0xFF333333);
  static const Color loginPlaceholder = Color(0xFF777777);
  static const Color loginIcon = Color(0xFF555555);

  // Login: inputs
  static const Color loginInputBg = Color(0xFFEDEDED);

  // Login: links & primary button
  static const Color loginLinkGreen = Color(0xFF70C55F);
  static const Color loginButtonCoral = Color(0xFFFC6B7B);

  // Login: separator
  static const Color loginSeparatorLine = Color(0xFFBBBBBB);
  static const Color loginSeparatorText = Color(0xFF777777);

  // Login: social buttons
  static const Color loginSocialBg = Color(0xFFD0D0D0);
  static const Color loginSocialText = Color(0xFF444444);

  // ----- SIGNUP SCREEN -----
  // Background gradient
  static const Color signupBgTop = Color(0xFFE8E2EC);
  static const Color signupBgBottom = Color(0xFFE5E1D8);

  // Logo (signup): G and i pink, ovanni purple
  static const Color signupLogoPink = Color(0xFFF74C65);
  static const Color signupLogoPurple = Color(0xFF5F40B3);

  // Signup: text
  static const Color signupTitle = Color(0xFF333333);
  static const Color signupPlaceholder = Color(0xFF9FA1A5);
  static const Color signupIconBlue = Color(0xFF4295EB);
  static const Color signupIconGrey = Color(0xFF9FA1A5);

  // Signup: inputs
  static const Color signupInputBg = Color(0xFFF0F2F5);
  static const Color signupInputBorderFocused = Color(0xFFB6B6E7);

  // Signup: Continue button gradient
  static const Color signupButtonTop = Color(0xFFFF7B8D);
  static const Color signupButtonBottom = Color(0xFFF74C65);

  // Signup: separator
  static const Color signupSeparatorLine = Color(0xFFCCCCCC);
  static const Color signupSeparatorText = Color(0xFF666666);

  // Signup: social buttons
  static const Color signupSocialBg = Color(0xFFECECEC);
  static const Color signupSocialBorder = Color(0xFF666666);
  static const Color signupSocialText = Color(0xFF666666);

  // Signup: Login link
  static const Color signupLoginLink = Color(0xFF38C793);

  // Error (shared)
  static const Color errorRed = Color(0xFFD32F2F);
}
