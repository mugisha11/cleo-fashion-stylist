import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/platform_helper.dart';
import '../../../routes.dart';
import '../../../core/theme/fashion_design_system.dart';

/// Premium Fashion Login Screen
/// Elegant, fashion-editorial, with blurred fashion image background
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
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
        Navigator.of(context).pushReplacementNamed(Routes.dashboard);
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
                  child: _buildLoginCard(isMobile),
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
              'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200',
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

  Widget _buildLoginCard(bool isMobile) {
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
              'Welcome Back',
            style: FashionDesignSystem.headlineLarge(isMobile: isMobile),
              textAlign: TextAlign.center,
          ),
          SizedBox(height: FashionDesignSystem.spacingSM),
            Text(
            'Log in to your style journey',
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
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    
                SizedBox(height: FashionDesignSystem.spacingSM),
                    
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                      // TODO: Implement forgot password
                        },
                    child: Text(
                      'Forgot password?',
                      style: FashionDesignSystem.linkText(),
                    ),
                      ),
                    ),
                    
                SizedBox(height: FashionDesignSystem.spacingXL),
                    
                    // Login button
                ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailSignIn,
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
                          'Log in',
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
                ],
              ),
            ),
            
          SizedBox(height: FashionDesignSystem.spacingXXXL),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Text(
                "Don't have an account? ",
                style: FashionDesignSystem.bodyMedium(),
              ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.signup),
                child: Text('Sign up', style: FashionDesignSystem.linkText()),
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
