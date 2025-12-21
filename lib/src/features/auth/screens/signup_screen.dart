import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../routes.dart';
import '../../../core/theme/fashion_design_system.dart';
import '../utils/platform_helper.dart';

/// Premium Fashion Signup Screen
/// Elegant, fashion-editorial, with blurred fashion image background
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
        displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Scaffold(
      body: Stack(
        children: [
          // Fashion Image Background (Blurred)
          _buildFashionBackground(),
          
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? FashionDesignSystem.spacingXXL : 120,
                  vertical: FashionDesignSystem.spacingXXXL,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildSignupCard(isMobile),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFashionBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1200',
            ),
                  fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: FashionDesignSystem.backgroundIvory.withOpacity(0.85),
                  ),
                ),
              ),
    );
  }

  Widget _buildSignupCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(FashionDesignSystem.spacingXXL),
      decoration: FashionDesignSystem.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Logo/Icon
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: FashionDesignSystem.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(FashionDesignSystem.radiusLG),
              ),
              child: Icon(
                Icons.star_rounded,
                color: FashionDesignSystem.primaryColor,
                size: FashionDesignSystem.iconSizeLarge,
              ),
            ),
          ),
          
          SizedBox(height: FashionDesignSystem.spacingXXL),
          
          // Title
            Text(
              'Create Your Account',
            style: FashionDesignSystem.headlineLarge(isMobile: isMobile),
              textAlign: TextAlign.center,
          ),
          SizedBox(height: FashionDesignSystem.spacingSM),
            Text(
            'Start your style journey today',
            style: FashionDesignSystem.bodyMedium(isMobile: isMobile).copyWith(
              color: FashionDesignSystem.textSecondary,
            ),
              textAlign: TextAlign.center,
          ),
          
          SizedBox(height: FashionDesignSystem.spacingXXXL),
          
          // Error message
            if (_errorMessage != null) _buildErrorMessage(),
          
          // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Name field
                TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                  style: FashionDesignSystem.bodyMedium(),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',
                  ),
                  ),
                
                SizedBox(height: FashionDesignSystem.spacingLG),
                
                // Email field
                TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  style: FashionDesignSystem.bodyMedium(),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                  ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                    if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                
                SizedBox(height: FashionDesignSystem.spacingLG),
                
                // Password field
                TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                  style: FashionDesignSystem.bodyMedium(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: FashionDesignSystem.iconSize,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                
                SizedBox(height: FashionDesignSystem.spacingLG),
                
                // Confirm Password field
                TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                  style: FashionDesignSystem.bodyMedium(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: FashionDesignSystem.iconSize,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                
                SizedBox(height: FashionDesignSystem.spacingXL),
                
                // Sign up button
                ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailSignUp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: FashionDesignSystem.bodyMedium().copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  ),
                
                SizedBox(height: FashionDesignSystem.spacingLG),
                
                // Divider
                  Row(
                    children: [
                    Expanded(child: Divider(color: FashionDesignSystem.dividerColor)),
                      Padding(
                      padding: const EdgeInsets.symmetric(horizontal: FashionDesignSystem.spacingMD),
                      child: Text('or', style: FashionDesignSystem.bodySmall()),
                      ),
                    Expanded(child: Divider(color: FashionDesignSystem.dividerColor)),
                    ],
                  ),
                
                SizedBox(height: FashionDesignSystem.spacingLG),
                
                // Google sign in
                OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: FashionDesignSystem.iconSize),
                  label: Text('Continue with Google', style: FashionDesignSystem.bodyMedium()),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: FashionDesignSystem.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: FashionDesignSystem.spacingMD),
                  ),
                ),
                
                  if (isApplePlatform) ...[
                  SizedBox(height: FashionDesignSystem.spacingMD),
                  OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleAppleSignIn,
                    icon: const Icon(Icons.apple, size: FashionDesignSystem.iconSize),
                    label: Text('Continue with Apple', style: FashionDesignSystem.bodyMedium()),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: FashionDesignSystem.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: FashionDesignSystem.spacingMD),
                    ),
                    ),
                  ],
                ],
              ),
            ),
          
          SizedBox(height: FashionDesignSystem.spacingXXXL),
          
          // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Text(
                'Already have an account? ',
                style: FashionDesignSystem.bodyMedium(),
              ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.login),
                child: Text('Log in', style: FashionDesignSystem.linkText()),
                ),
              ],
            ),
          ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: EdgeInsets.only(bottom: FashionDesignSystem.spacingLG),
      padding: EdgeInsets.all(FashionDesignSystem.spacingMD),
      decoration: BoxDecoration(
        color: FashionDesignSystem.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(FashionDesignSystem.radiusMD),
        border: Border.all(
          color: FashionDesignSystem.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: FashionDesignSystem.errorColor,
            size: FashionDesignSystem.iconSizeSmall,
          ),
          SizedBox(width: FashionDesignSystem.spacingSM),
          Expanded(
            child: Text(
              _errorMessage!,
              style: FashionDesignSystem.bodySmall().copyWith(
                color: FashionDesignSystem.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
