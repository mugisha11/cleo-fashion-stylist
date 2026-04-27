// ══════════════════════════════════════════════════════════════════════════════
//  auth_screens.dart
//  Pixel-perfect clone of the Thinder auth mockup.
//
//  Contains 3 screens:
//    • WelcomeScreen  — shown on app launch (middle mockup)
//    • LoginScreen    — left mockup
//    • SignUpScreen   — right mockup
//
//  USAGE — wire into your router:
//    Routes:
//      '/welcome'     → WelcomeScreen()
//      '/login'       → LoginScreen()
//      '/signup'      → SignUpScreen()
//
//  Backend/providers: none added — hook up your existing auth provider
//  inside the _onLogin() / _onSignUp() callbacks marked with TODO.
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/nikonyx_logo.dart';
import '../../../routes.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_screen_colors.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ──────────────────────────────────────────────────────────────────────────────
// Gradient colours extracted from the mockup image
const _gradTop = Color(0xFF1AACCF); // teal-blue top
const _gradMid = Color(0xFF1178B4); // mid blue
const _gradBot = Color(0xFF0A4E8F); // deep navy bottom

// Body panel (light dashboard surface)
const _panelBg = AuthScreenColors.loginInputBg;
const _fieldLine = AuthScreenColors.loginInputBorder;
const _hintColor = AuthScreenColors.loginPlaceholder;
const _darkText = AuthScreenColors.loginHeading;

// Buttons
const _btnBlue = AuthScreenColors.loginButtonCoral;
const _btnWhite = Colors.white;

const _gradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [_gradTop, _gradMid, _gradBot],
  stops: [0.0, 0.45, 1.0],
);

const _loginGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AuthScreenColors.loginBgTop, AuthScreenColors.loginBgBottom],
);

// ──────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ──────────────────────────────────────────────────────────────────────────────

/// Glass-circle "···" menu button in top-right of every screen
class _MenuDots extends StatelessWidget {
  const _MenuDots({this.dark = false});
  final bool dark;
  @override
  Widget build(BuildContext c) => GestureDetector(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (_) => Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark ? const Color(0xFF444444) : Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
}

/// Thin underline text field matching the mockup
class _UnderlineField extends StatefulWidget {
  const _UnderlineField({
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.onChanged,
  });
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  @override
  State<_UnderlineField> createState() => _UnderlineFieldState();
}

class _UnderlineFieldState extends State<_UnderlineField> {
  bool _focused = false;

  @override
  Widget build(BuildContext c) => Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: TextField(
          controller: widget.controller,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: const TextStyle(
              color: _darkText, fontSize: 14, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: _hintColor, fontSize: 13),
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 6),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _fieldLine, width: 1.0)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _btnBlue, width: 1.5)),
          )));
}

/// Blue pill "LOGIN" / "Next" button
class _BlueBtn extends StatelessWidget {
  const _BlueBtn(
      {required this.label, required this.onTap, required this.wide});
  final String label;
  final VoidCallback onTap;
  final bool wide;
  @override
  Widget build(BuildContext c) => SizedBox(
      width: wide ? 200 : null,
      height: 46,
      child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: _btnBlue,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          child: Text(label.toUpperCase())));
}

/// Outlined white pill button (used on Welcome screen)
class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => SizedBox(
      width: 200,
      height: 46,
      child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          child: Text(label.toUpperCase())));
}

/// White filled pill button (SIGN IN on Welcome screen)
class _WhiteBtn extends StatelessWidget {
  const _WhiteBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => SizedBox(
      width: 200,
      height: 46,
      child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _gradBot,
              elevation: 2,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          child: Text(label.toUpperCase())));
}

/// Auth method button for Google / Apple
class _AuthMethodBtn extends StatelessWidget {
  const _AuthMethodBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext c) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: icon,
        label: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  1. WELCOME SCREEN  (middle mockup — shown on app launch)
// ──────────────────────────────────────────────────────────────────────────────
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    try {
      await authService.signInWithGoogle();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _signInWithApple(BuildContext context, WidgetRef ref) async {
    if (!(defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Apple Sign-In is only available on iOS/macOS')),
        );
      }
      return;
    }

    final authService = ref.read(authServiceProvider);
    try {
      await authService.signInWithApple();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _gradient),
        child: SafeArea(
          child: Column(children: [
            // ── top ··· menu ──────────────────────────────────────────
            const Align(
                alignment: Alignment.topRight,
                child: Padding(
                    padding: EdgeInsets.only(top: 8, right: 16),
                    child: _MenuDots())),

            // ── app name ──────────────────────────────────────────────
            const Spacer(flex: 3),
            const NikonyxLogo.medium(),
            const SizedBox(height: 16),
            const Text('NIKONYX',
                style: TextStyle(
                    color: Color(0xEBFFFFFF),
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5)),

            const Spacer(flex: 2),

            // ── welcome text ──────────────────────────────────────────
            const Text('Welcome back',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700)),

            const Spacer(flex: 3),

            // ── LOGIN (outlined) ──────────────────────────────────────
            _OutlineBtn(
                label: 'Login',
                onTap: () => Navigator.of(context).pushNamed(Routes.login)),
            const SizedBox(height: 14),

            // ── SIGN IN (white filled) ────────────────────────────────
            _WhiteBtn(
                label: 'Sign up',
                onTap: () => Navigator.of(context).pushNamed(Routes.signup)),

            const SizedBox(height: 24),
            _AuthMethodBtn(
              icon: Image.asset(
                'assets/icons/google.jpg',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              label: 'Continue with Google',
              onTap: () => _signInWithGoogle(context, ref),
            ),
            const SizedBox(height: 12),
            _AuthMethodBtn(
              icon: const Icon(Icons.apple, size: 20),
              label: 'Continue with Apple',
              onTap: () => _signInWithApple(context, ref),
            ),

            const Spacer(flex: 2),

            // ── social section ────────────────────────────────────────
            Text('Login with Social Media',
                style: TextStyle(
                    color: AuthScreenColors.loginPlaceholder.withOpacity(0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 16),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _SocialBtn(icon: _SocialIcon.instagram, onTap: () {}),
              const SizedBox(width: 14),
              _SocialBtn(icon: _SocialIcon.twitter, onTap: () {}),
              const SizedBox(width: 14),
              _SocialBtn(icon: _SocialIcon.facebook, onTap: () {}),
            ]),

            SizedBox(height: mq.padding.bottom + 24),
          ]),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  2. LOGIN SCREEN  (left mockup)
// ──────────────────────────────────────────────────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onAppleSignIn() async {
    if (!(defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Apple Sign-In is only available on iOS/macOS')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithApple();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(children: [
        // ── BLUE HEADER ─────────────────────────────────────────────────
        SizedBox(
          height: mq.size.height * 0.45,
          width: double.infinity,
          child: Container(
            decoration: const BoxDecoration(gradient: _loginGradient),
            child: const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ··· menu top-right
                    Align(
                        alignment: Alignment.topRight,
                        child: _MenuDots(dark: true)),
                    SizedBox(height: 12),
                    // Logo
                    NikonyxLogo.medium(),
                    SizedBox(height: 12),
                    // Title
                    Text('Hello\nLog In!',
                        style: TextStyle(
                            color: AuthScreenColors.loginHeading,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.15)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── WHITE PANEL ─────────────────────────────────────────────────
        Expanded(
            child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
              color: _panelBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          // pull panel down more to increase blue header space
          transform: Matrix4.translationValues(0, 30, 0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fields
                _UnderlineField(
                    hint: 'Email address',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                _UnderlineField(
                    hint: 'Password', obscure: true, controller: _passCtrl),

                // Forgot password
                const SizedBox(height: 10),
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Forget password?',
                            style: TextStyle(
                                color: AuthScreenColors.loginPlaceholder,
                                fontSize: 12,
                                fontWeight: FontWeight.w400)))),

                const SizedBox(height: 36),

                // LOGIN button — centered
                Center(
                    child: _loading
                        ? const CircularProgressIndicator(color: _btnBlue)
                        : _BlueBtn(
                            label: 'Login', onTap: _onLogin, wide: true)),

                const SizedBox(height: 20),
                _AuthMethodBtn(
                    icon: Image.asset(
                      'assets/icons/google.jpg',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    label: 'Continue with Google',
                    onTap: _onGoogleSignIn),
                const SizedBox(height: 12),
                _AuthMethodBtn(
                    icon: const Icon(Icons.apple, size: 20),
                    label: 'Continue with Apple',
                    onTap: _onAppleSignIn),

                const SizedBox(height: 24),

                // Don't have account
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(Routes.signup),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text("Don't have account?",
                            style: TextStyle(
                                color: AuthScreenColors.loginPlaceholder,
                                fontSize: 12,
                                fontWeight: FontWeight.w400)))),

                SizedBox(height: mq.padding.bottom + 16),
              ],
            ),
          ),
        )),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  3. SIGN UP SCREEN  (right mockup)
// ──────────────────────────────────────────────────────────────────────────────
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (_emailCtrl.text.isEmpty ||
        _firstCtrl.text.isEmpty ||
        _lastCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty) {
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Passwords don't match")));
      return;
    }
    setState(() => _loading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        displayName: '${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()}',
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onAppleSignIn() async {
    if (!(defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Apple Sign-In is only available on iOS/macOS')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithApple();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(children: [
        // ── BLUE HEADER ─────────────────────────────────────────────────
        Container(
          height: mq.size.height * 0.45,
          width: double.infinity,
          decoration: const BoxDecoration(gradient: _gradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                      alignment: Alignment.topRight, child: _MenuDots()),
                  const SizedBox(height: 12),
                  // Logo
                  Image.asset(
                    'assets/images/Nikonyx logo.svg',
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  const Text('Hello Create\naccount!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.15)),
                ],
              ),
            ),
          ),
        ),

        // ── WHITE PANEL ─────────────────────────────────────────────────
        Expanded(
            child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
              color: _panelBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          transform: Matrix4.translationValues(0, 30, 0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UnderlineField(
                    hint: 'Email address',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                _UnderlineField(hint: 'First name', controller: _firstCtrl),
                const SizedBox(height: 20),
                _UnderlineField(hint: 'Last name', controller: _lastCtrl),
                const SizedBox(height: 20),
                _UnderlineField(
                    hint: 'Password', obscure: true, controller: _passCtrl),
                const SizedBox(height: 20),
                _UnderlineField(
                    hint: 'Confirm password',
                    obscure: true,
                    controller: _confirmCtrl),
                const SizedBox(height: 40),
                Center(
                    child: _loading
                        ? const CircularProgressIndicator(color: _btnBlue)
                        : _BlueBtn(label: 'Next', onTap: _onNext, wide: true)),
                const SizedBox(height: 20),
                _AuthMethodBtn(
                    icon: Image.asset(
                      'assets/icons/google.jpg',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    label: 'Continue with Google',
                    onTap: _onGoogleSignIn),
                const SizedBox(height: 12),
                _AuthMethodBtn(
                    icon: const Icon(Icons.apple, size: 20),
                    label: 'Continue with Apple',
                    onTap: _onAppleSignIn),
                const SizedBox(height: 24),
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(Routes.login),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Already have account?',
                            style: TextStyle(
                                color: _hintColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w400)))),
                SizedBox(height: mq.padding.bottom + 16),
              ],
            ),
          ),
        )),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  SOCIAL ICON BUTTON
// ──────────────────────────────────────────────────────────────────────────────
enum _SocialIcon { instagram, twitter, facebook }

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({required this.icon, required this.onTap});
  final _SocialIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext c) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)),
          child: Center(child: _iconWidget)));

  Widget get _iconWidget {
    switch (icon) {
      case _SocialIcon.instagram:
        return CustomPaint(size: const Size(22, 22), painter: _InstaPainter());
      case _SocialIcon.twitter:
        return CustomPaint(
            size: const Size(22, 22), painter: _TwitterPainter());
      case _SocialIcon.facebook:
        return CustomPaint(size: const Size(22, 22), painter: _FbPainter());
    }
  }
}

// Instagram icon painter
class _InstaPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final r = s.width * 0.36;
    final cx = s.width / 2;
    final cy = s.height / 2;
    // outer rounded square
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy),
                width: s.width * 0.82,
                height: s.height * 0.82),
            Radius.circular(s.width * 0.22)),
        p);
    // circle
    c.drawCircle(Offset(cx, cy), r, p);
    // dot
    p.style = PaintingStyle.fill;
    c.drawCircle(Offset(cx + s.width * 0.22, cy - s.height * 0.22), 1.8, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// Twitter/X icon painter
class _TwitterPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Bird shape — simplified X/bird
    final path = Path()
      ..moveTo(s.width * 0.12, s.height * 0.72)
      ..quadraticBezierTo(
          s.width * 0.38, s.height * 0.52, s.width * 0.50, s.height * 0.28)
      ..quadraticBezierTo(
          s.width * 0.62, s.height * 0.52, s.width * 0.88, s.height * 0.30);
    c.drawPath(path, p);
    // Wing
    final path2 = Path()
      ..moveTo(s.width * 0.10, s.height * 0.32)
      ..quadraticBezierTo(
          s.width * 0.38, s.height * 0.50, s.width * 0.55, s.height * 0.72);
    c.drawPath(path2, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// Facebook "f" icon painter
class _FbPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // f shape
    final path = Path()
      ..moveTo(s.width * 0.62, s.height * 0.18)
      ..quadraticBezierTo(
          s.width * 0.52, s.height * 0.15, s.width * 0.46, s.height * 0.26)
      ..lineTo(s.width * 0.44, s.height * 0.42)
      ..moveTo(s.width * 0.32, s.height * 0.44)
      ..lineTo(s.width * 0.60, s.height * 0.44)
      ..moveTo(s.width * 0.44, s.height * 0.44)
      ..lineTo(s.width * 0.44, s.height * 0.82);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}
