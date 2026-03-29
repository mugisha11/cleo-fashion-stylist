import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_screen_colors.dart';
import '../utils/platform_helper.dart';
import '../../../core/widgets/nikonyx_logo.dart';
import '../../../routes.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static bool _isDeviceOrFileError(Object e) {
    final msg = e.toString();
    return msg.contains('FileSystem') ||
        msg.contains('path =') ||
        msg.contains('errno') ||
        msg.contains('OS Error') ||
        msg.contains('Read-only file system') ||
        msg.contains('.cursor') ||
        msg.contains('debug.log') ||
        (msg.contains(r'\') && msg.contains('.log'));
  }

  static String _sanitizeAuthError(Object e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    if (_isDeviceOrFileError(e)) {
      return 'Something went wrong. Please try again.';
    }
    return msg;
  }

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        if (_isDeviceOrFileError(e) && FirebaseAuth.instance.currentUser != null) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
          ref.invalidate(currentUserProvider);
          ref.invalidate(authStateProvider);
          Navigator.of(context).pushReplacementNamed(Routes.dashboard);
          return;
        }
        setState(() {
          _errorMessage = _sanitizeAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      ref.invalidate(currentUserProvider);
      ref.invalidate(authStateProvider);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        if (_isDeviceOrFileError(e) && FirebaseAuth.instance.currentUser != null) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
          ref.invalidate(currentUserProvider);
          ref.invalidate(authStateProvider);
          Navigator.of(context).pushReplacementNamed(Routes.dashboard);
          return;
        }
        setState(() {
          _errorMessage = _sanitizeAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (!isApplePlatform) {
      setState(() {
        _errorMessage = 'Apple Sign In is only available on iOS and macOS';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithApple();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        if (_isDeviceOrFileError(e) && FirebaseAuth.instance.currentUser != null) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
          ref.invalidate(currentUserProvider);
          ref.invalidate(authStateProvider);
          Navigator.of(context).pushReplacementNamed(Routes.dashboard);
          return;
        }
        setState(() {
          _errorMessage = _sanitizeAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AuthScreenColors.loginBgTop,
              AuthScreenColors.loginBgBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: keyboardHeight > 0 ? 24 : 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 28),
                      _buildTagline(),
                      const SizedBox(height: 32),
                      const Text(
                        'Welcome back!',
                        style: TextStyle(fontFamily: 'system-ui', 
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AuthScreenColors.loginHeading,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        _buildErrorMessage(),
                        const SizedBox(height: 16),
                      ],
                      _buildInput(
                        controller: _emailController,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        suffixIcon: Icons.mail_outline,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter your email';
                          if (!v.contains('@')) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        controller: _passwordController,
                        hint: 'Password',
                        obscureText: _obscurePassword,
                        suffixIcon: _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter your password';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(fontFamily: 'system-ui', 
                              fontSize: 14,
                              color: AuthScreenColors.loginLinkGreen,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildPrimaryButton(
                        label: "Let's go",
                        onPressed: _handleEmailSignIn,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 28),
                      _buildSeparator(),
                      const SizedBox(height: 24),
                      _buildSocialButtons(),
                      const SizedBox(height: 32),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AuthScreenColors.errorRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AuthScreenColors.errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontFamily: 'system-ui', 
                fontSize: 13,
                color: AuthScreenColors.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return const Center(
      child: NikonyxLogo.large(),
    );
  }

  Widget _buildTagline() {
    return const Center(
      child: Text(
        'Your Personal AI stylist',
        style: TextStyle(fontFamily: 'system-ui', 
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AuthScreenColors.loginTagline,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    required IconData suffixIcon,
    VoidCallback? onSuffixTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontFamily: 'system-ui', 
        fontSize: 16,
        color: AuthScreenColors.loginHeading,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'system-ui', 
          color: AuthScreenColors.loginPlaceholder,
          fontSize: 16,
        ),
        filled: true,
        fillColor: AuthScreenColors.loginInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthScreenColors.errorRed, width: 1),
        ),
        suffixIcon: IconButton(
          icon: Icon(suffixIcon, color: AuthScreenColors.loginIcon, size: 22),
          onPressed: onSuffixTap,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthScreenColors.loginButtonCoral,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontFamily: 'system-ui', 
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AuthScreenColors.loginSeparatorLine,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or login via',
            style: TextStyle(fontFamily: 'system-ui', 
              fontSize: 13,
              color: AuthScreenColors.loginSeparatorText,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AuthScreenColors.loginSeparatorLine,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? () {} : _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              backgroundColor: AuthScreenColors.loginSocialBg,
              foregroundColor: AuthScreenColors.loginSocialText,
              side: BorderSide(color: AuthScreenColors.loginSeparatorLine.withValues(alpha: 0.8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/google.jpg',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 22, color: AuthScreenColors.loginSocialText),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Google',
                  style: TextStyle(fontFamily: 'system-ui', fontSize: 15, fontWeight: FontWeight.w500, color: AuthScreenColors.loginSocialText),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? () {} : _handleAppleSignIn,
            style: OutlinedButton.styleFrom(
              backgroundColor: AuthScreenColors.loginSocialBg,
              foregroundColor: AuthScreenColors.loginSocialText,
              side: BorderSide(color: AuthScreenColors.loginSeparatorLine.withValues(alpha: 0.8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, size: 22, color: AuthScreenColors.loginSocialText),
                SizedBox(width: 10),
                Text(
                  'Apple',
                  style: TextStyle(fontFamily: 'system-ui', fontSize: 15, fontWeight: FontWeight.w500, color: AuthScreenColors.loginSocialText),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(fontFamily: 'system-ui', 
            fontSize: 14,
            color: AuthScreenColors.loginTagline,
            fontWeight: FontWeight.w400,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.signup),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 36),
          ),
          child: const Text(
            'Signup',
            style: TextStyle(fontFamily: 'system-ui', 
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AuthScreenColors.loginLinkGreen,
            ),
          ),
        ),
      ],
    );
  }
}
