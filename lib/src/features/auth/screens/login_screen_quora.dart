import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/quora_design_system.dart';
import '../../../routes.dart';

/// login screen for the app 
class LoginScreenQuora extends ConsumerStatefulWidget {
  const LoginScreenQuora({super.key});

  @override
  ConsumerState<LoginScreenQuora> createState() => _LoginScreenQuoraState();
}

class _LoginScreenQuoraState extends ConsumerState<LoginScreenQuora> {
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Scaffold(
      backgroundColor: QuoraDesignSystem.backgroundWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? QuoraDesignSystem.spacingXXL : 120,
              vertical: QuoraDesignSystem.spacingXXXL,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'Log in',
                    style: QuoraDesignSystem.headlineLarge(isMobile: isMobile),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: QuoraDesignSystem.spacingSM),
                  
                  // Subtitle
                  Text(
                    'Welcome back to StyleApp',
                    style: QuoraDesignSystem.bodyMedium(isMobile: isMobile).copyWith(
                      color: QuoraDesignSystem.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: QuoraDesignSystem.spacingXXXL),
                  
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
                          style: QuoraDesignSystem.bodyMedium(),
                          decoration: InputDecoration(
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
                        
                        SizedBox(height: QuoraDesignSystem.spacingLG),
                        
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: QuoraDesignSystem.bodyMedium(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: QuoraDesignSystem.iconSize,
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
                        
                        SizedBox(height: QuoraDesignSystem.spacingSM),
                        
                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            child: Text(
                              'Forgot password?',
                              style: QuoraDesignSystem.linkText(),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: QuoraDesignSystem.spacingXL),
                        
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
                              : Text('Log in', style: QuoraDesignSystem.bodyMedium().copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                )),
                        ),
                        
                        SizedBox(height: QuoraDesignSystem.spacingLG),
                        
                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: QuoraDesignSystem.dividerColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: QuoraDesignSystem.spacingMD),
                              child: Text(
                                'or',
                                style: QuoraDesignSystem.bodySmall(),
                              ),
                            ),
                            Expanded(child: Divider(color: QuoraDesignSystem.dividerColor)),
                          ],
                        ),
                        
                        SizedBox(height: QuoraDesignSystem.spacingLG),
                        
                        // Google sign in
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.g_mobiledata, size: QuoraDesignSystem.iconSize),
                          label: Text('Continue with Google', style: QuoraDesignSystem.bodyMedium()),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: QuoraDesignSystem.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: QuoraDesignSystem.spacingMD),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: QuoraDesignSystem.spacingXXXL),
                  
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: QuoraDesignSystem.bodyMedium(),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.signup),
                        child: Text('Sign up', style: QuoraDesignSystem.linkText()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: EdgeInsets.only(bottom: QuoraDesignSystem.spacingLG),
      padding: EdgeInsets.all(QuoraDesignSystem.spacingMD),
      decoration: BoxDecoration(
        color: QuoraDesignSystem.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(QuoraDesignSystem.radiusMD),
        border: Border.all(
          color: QuoraDesignSystem.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: QuoraDesignSystem.errorColor,
            size: QuoraDesignSystem.iconSizeSmall,
          ),
          SizedBox(width: QuoraDesignSystem.spacingSM),
          Expanded(
            child: Text(
              _errorMessage!,
              style: QuoraDesignSystem.bodySmall().copyWith(
                color: QuoraDesignSystem.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
