import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_screen_colors.dart';
import '../../../core/widgets/nikonyx_logo.dart';
import '../../../routes.dart';
import '../utils/platform_helper.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: null,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
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
          Navigator.of(context).pushReplacementNamed(Routes.onboarding);
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

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
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
          Navigator.of(context).pushReplacementNamed(Routes.onboarding);
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
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
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
          Navigator.of(context).pushReplacementNamed(Routes.onboarding);
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
              AuthScreenColors.signupBgTop,
              AuthScreenColors.signupBgBottom,
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
                        'Signup for free.',
                        style: TextStyle(fontFamily: 'system-ui', 
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AuthScreenColors.signupTitle,
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
                        suffixIcon: Icons.person_outline,
                        suffixIconColor: AuthScreenColors.signupIconBlue,
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
                        suffixIconColor: AuthScreenColors.signupIconGrey,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter a password';
                          if (v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        controller: _confirmPasswordController,
                        hint: 'Confirm password',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        onSuffixTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        suffixIconColor: AuthScreenColors.signupIconGrey,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm your password';
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      _buildPrimaryButton(
                        label: 'Continue',
                        onPressed: _handleEmailSignUp,
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
          color: AuthScreenColors.signupTitle,
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
    Color? suffixIconColor,
    String? Function(String?)? validator,
  }) {
    final iconColor = suffixIconColor ?? AuthScreenColors.signupIconGrey;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontFamily: 'system-ui', 
        fontSize: 16,
        color: AuthScreenColors.signupTitle,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'system-ui', 
          color: AuthScreenColors.signupPlaceholder,
          fontSize: 16,
        ),
        filled: true,
        fillColor: AuthScreenColors.signupInputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AuthScreenColors.signupInputBorderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AuthScreenColors.errorRed, width: 1),
        ),
        suffixIcon: IconButton(
          icon: Icon(suffixIcon, color: iconColor, size: 22),
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
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: AuthScreenColors.signupButtonBottom.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AuthScreenColors.signupButtonTop,
            AuthScreenColors.signupButtonBottom,
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(27),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(27),
          child: Center(
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
                      color: Colors.white,
                    ),
                  ),
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
            color: AuthScreenColors.signupSeparatorLine,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or login via',
            style: TextStyle(fontFamily: 'system-ui', 
              fontSize: 13,
              color: AuthScreenColors.signupSeparatorText,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AuthScreenColors.signupSeparatorLine,
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
              backgroundColor: AuthScreenColors.signupSocialBg,
              foregroundColor: AuthScreenColors.signupSocialText,
              side: const BorderSide(color: AuthScreenColors.signupSocialBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/google.jpg',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 22, color: AuthScreenColors.signupSocialText),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Google',
                  style: TextStyle(fontFamily: 'system-ui', fontSize: 15, fontWeight: FontWeight.w500, color: AuthScreenColors.signupSocialText),
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
              backgroundColor: AuthScreenColors.signupSocialBg,
              foregroundColor: AuthScreenColors.signupSocialText,
              side: const BorderSide(color: AuthScreenColors.signupSocialBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, size: 22, color: AuthScreenColors.signupSocialText),
                SizedBox(width: 10),
                Text(
                  'Apple',
                  style: TextStyle(fontFamily: 'system-ui', fontSize: 15, fontWeight: FontWeight.w500, color: AuthScreenColors.signupSocialText),
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
            color: AuthScreenColors.signupSeparatorText,
            fontWeight: FontWeight.w400,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.login),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 36),
          ),
          child: const Text(
            'Login',
            style: TextStyle(fontFamily: 'system-ui', 
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AuthScreenColors.signupLoginLink,
              decoration: TextDecoration.underline,
              decorationColor: AuthScreenColors.signupLoginLink,
            ),
          ),
        ),
      ],
    );
  }
}
