import 'package:flutter/material.dart';

/// Giovanni-style design tokens for auth screens (light theme from reference images).
/// Design-only; backend unchanged.
class AuthScreenColors {
  AuthScreenColors._();

  // ----- LOGIN SCREEN -----
  // Background gradient: top → bottom
  static const Color loginBgTop = Color(0xFF1AACCF);
  static const Color loginBgBottom = Color(0xFF0A4E8F);

  // Logo gradient (login): home page palette accent
  static const Color loginLogoPink = Color(0xFFF74C65);
  static const Color loginLogoPurple = Color(0xFF5F40B3);
  static const Color loginLogoBlue = Color(0xFF2A58C8);

  // Login: tagline, body text
  static const Color loginTagline = Color(0xFF606880);
  static const Color loginHeading = Color(0xFF0C1E48);
  static const Color loginPlaceholder = Color(0xFF606880);
  static const Color loginIcon = Color(0xFF1A2A50);

  // Login: inputs
  static const Color loginInputBg = Color(0xFFFFFFFF);
  static const Color loginInputBorder = Color(0xFFB4CDF0);

  // Login: links & primary button
  static const Color loginLinkGreen = Color(0xFF2A58C8);
  static const Color loginButtonCoral = Color(0xFF2A58C8);

  // Login: separator
  static const Color loginSeparatorLine = Color(0xFFB4CDF0);
  static const Color loginSeparatorText = Color(0xFF606880);

  // Login: social buttons
  static const Color loginSocialBg = Color(0xFFF0F5FF);
  static const Color loginSocialText = Color(0xFF0C1E48);

  // ----- SIGNUP SCREEN -----
  // Background gradient
  static const Color signupBgTop = Color(0xFF1AACCF);
  static const Color signupBgBottom = Color(0xFF0A4E8F);

  // Logo (signup): home page palette accent
  static const Color signupLogoPink = Color(0xFFF74C65);
  static const Color signupLogoPurple = Color(0xFF5F40B3);

  // Signup: text
  static const Color signupTitle = Color(0xFF0C1E48);
  static const Color signupPlaceholder = Color(0xFF606880);
  static const Color signupIconBlue = Color(0xFF2A58C8);
  static const Color signupIconGrey = Color(0xFF606880);

  // Signup: inputs
  static const Color signupInputBg = Color(0xFFFFFFFF);
  static const Color signupInputBorderFocused = Color(0xFFB4CDF0);

  // Signup: Continue button gradient
  static const Color signupButtonTop = Color(0xFF1178B4);
  static const Color signupButtonBottom = Color(0xFF0A4E8F);

  // Signup: separator
  static const Color signupSeparatorLine = Color(0xFFB4CDF0);
  static const Color signupSeparatorText = Color(0xFF606880);

  // Signup: social buttons
  static const Color signupSocialBg = Color(0xFFF0F5FF);
  static const Color signupSocialBorder = Color(0xFFB4CDF0);
  static const Color signupSocialText = Color(0xFF0C1E48);

  // Signup: Login link
  static const Color signupLoginLink = Color(0xFF2A58C8);

  // Error (shared)
  static const Color errorRed = Color(0xFFD32F2F);
}
