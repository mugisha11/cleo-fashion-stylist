import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/platform_helper.dart';
import '../../../routes.dart';
import '../../../core/widgets/theme_wrapper.dart';
import '../../../core/widgets/theme_helpers.dart';
import '../../../core/widgets/cleo_logo.dart';
import '../../../core/theme/app_theme_data.dart';

/// Premium Fashion Login Screen
/// Step-by-step flow: Email → Password
/// Inspired by Dribbble Session, GitHub, and ChatGPT
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  int _currentStep = 0; // 0 = email, 1 = password
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppThemeData.animationMedium,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppThemeData.smoothCurve,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppThemeData.smoothCurve,
      ),
    );
    _animationController.forward();
    
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      if (_emailFormKey.currentState!.validate()) {
        setState(() {
          _currentStep = 1;
          _errorMessage = null;
        });
        _animationController.reset();
        _animationController.forward();
        // Auto-focus password field
        Future.delayed(const Duration(milliseconds: 350), () {
          _passwordFocusNode.requestFocus();
        });
      }
    }
  }

  void _goToPreviousStep() {
    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        _errorMessage = null;
      });
      _animationController.reset();
      _animationController.forward();
      _emailFocusNode.requestFocus();
    }
  }

  Future<void> _handleEmailSignIn() async {
    if (!_passwordFormKey.currentState!.validate()) return;

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
      
      // Invalidate providers to refresh user data
      ref.invalidate(currentUserProvider);
      ref.invalidate(authStateProvider);

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
    final theme = context.appTheme;
    final isMobile = MediaQuery.of(context).size.width <= 600;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(theme),
          
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: isMobile ? AppThemeData.spacingXXL : 120,
                  right: isMobile ? AppThemeData.spacingXXL : 120,
                  top: isMobile ? AppThemeData.spacingXL : AppThemeData.spacingXXL,
                  bottom: keyboardHeight > 0 
                      ? AppThemeData.spacingXXL 
                      : (isMobile ? AppThemeData.spacingXL : AppThemeData.spacingXXL),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildAuthCard(isMobile, theme),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(AppThemeData theme) {
    return Positioned.fill(
      child: Container(
        decoration: theme.backgroundGradient != null
            ? BoxDecoration(gradient: theme.backgroundGradient)
            : BoxDecoration(color: theme.backgroundPrimary),
      ),
    );
  }

  Widget _buildAuthCard(bool isMobile, AppThemeData theme) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppThemeData.spacingXL : AppThemeData.spacingXXL),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadiusLarge),
        border: Border.all(
          color: theme.borderLight.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: theme.cardGlow != null ? [theme.cardGlow!] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo/Brand
          _buildLogo(theme),
          
          SizedBox(height: isMobile ? AppThemeData.spacingXL : AppThemeData.spacingXXL),
          
          // Title
          _buildTitle(theme, isMobile),
          
          SizedBox(height: AppThemeData.spacingXL),
          
          // Step indicator (subtle)
          if (_currentStep > 0) _buildStepIndicator(theme),
          
          if (_currentStep > 0) SizedBox(height: AppThemeData.spacingXL),
          
          // Error message
          if (_errorMessage != null) 
            _buildErrorMessage(theme),
          
          if (_errorMessage != null) SizedBox(height: AppThemeData.spacingLG),
          
          // Step content
          AnimatedSwitcher(
            duration: AppThemeData.animationMedium,
            switchInCurve: AppThemeData.smoothCurve,
            switchOutCurve: AppThemeData.smoothCurve,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: AppThemeData.smoothCurve,
                  )),
                  child: child,
                ),
              );
            },
            child: _currentStep == 0
                ? _buildEmailStep(theme, isMobile)
                : _buildPasswordStep(theme, isMobile),
          ),
          
          SizedBox(height: AppThemeData.spacingXL),
          
          // Social auth (only on email step)
          if (_currentStep == 0) _buildSocialAuth(theme),
          
          if (_currentStep == 0) SizedBox(height: AppThemeData.spacingLG),
          
          // Footer
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildLogo(AppThemeData theme) {
    return const Center(
      child: CleoLogo.medium(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  Widget _buildTitle(AppThemeData theme, bool isMobile) {
    return Column(
      children: [
        Text(
          _currentStep == 0 ? 'Welcome back' : 'Enter your password',
          style: theme.headlineLarge(isMobile: isMobile).copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppThemeData.spacingSM),
        Text(
          _currentStep == 0
              ? 'Sign in to continue'
              : _emailController.text.trim(),
          style: theme.bodyMedium(isMobile: isMobile).copyWith(
            color: theme.textSecondary,
            fontSize: isMobile ? 14 : 15,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepIndicator(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(theme, true),
        const SizedBox(width: AppThemeData.spacingSM),
        Container(
          width: 24,
          height: 1,
          color: theme.borderLight,
        ),
        const SizedBox(width: AppThemeData.spacingSM),
        _buildStepDot(theme, false),
      ],
    );
  }

  Widget _buildStepDot(AppThemeData theme, bool isActive) {
    return AnimatedContainer(
      duration: AppThemeData.animationFast,
      width: isActive ? 6 : 5,
      height: isActive ? 6 : 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? theme.primary
            : theme.borderLight,
      ),
    );
  }

  Widget _buildEmailStep(AppThemeData theme, bool isMobile) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email_step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAnimatedInputField(
            theme: theme,
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: 'Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
            onFieldSubmitted: (_) => _goToNextStep(),
          ),
          
          const SizedBox(height: AppThemeData.spacingXL),
          
          _buildContinueButton(theme, _goToNextStep),
        ],
      ),
    );
  }

  Widget _buildPasswordStep(AppThemeData theme, bool isMobile) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        key: const ValueKey('password_step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAnimatedInputField(
            theme: theme,
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleEmailSignIn(),
          ),
          
          const SizedBox(height: AppThemeData.spacingMD),
          
          // Back button
          _buildBackButton(theme),
          
          const SizedBox(height: AppThemeData.spacingMD),
          
          _buildSignInButton(theme),
        ],
      ),
    );
  }

  Widget _buildAnimatedInputField({
    required AppThemeData theme,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasValue = controller.text.isNotEmpty;
    
    return AnimatedContainer(
      duration: AppThemeData.animationFast,
      curve: AppThemeData.smoothCurve,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        style: theme.bodyLarge().copyWith(
          fontSize: 16,
          height: 1.5,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: theme.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          floatingLabelStyle: TextStyle(
            color: theme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: theme.textTertiary,
            fontSize: 16,
          ),
          filled: true,
          fillColor: theme.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppThemeData.spacingLG,
            vertical: AppThemeData.spacingLG,
          ),
          suffixIcon: obscureText && onToggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: theme.textSecondary,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.borderRadius),
            borderSide: BorderSide(
              color: theme.borderLight,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.borderRadius),
            borderSide: BorderSide(
              color: theme.borderLight,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.borderRadius),
            borderSide: BorderSide(
              color: theme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.borderRadius),
            borderSide: BorderSide(
              color: theme.accentError,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.borderRadius),
            borderSide: BorderSide(
              color: theme.accentError,
              width: 2,
            ),
          ),
        ),
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }

  Widget _buildContinueButton(AppThemeData theme, VoidCallback onPressed) {
    return AnimatedContainer(
      duration: AppThemeData.animationFast,
      curve: AppThemeData.smoothCurve,
      child: ThemedButton.primary(
        context: context,
        text: 'Continue',
        onPressed: onPressed,
        isLoading: false,
      ),
    );
  }

  Widget _buildSignInButton(AppThemeData theme) {
    return ThemedButton.primary(
      context: context,
      text: 'Sign in',
      onPressed: _handleEmailSignIn,
      isLoading: _isLoading,
    );
  }

  Widget _buildBackButton(AppThemeData theme) {
    return TextButton(
      onPressed: _goToPreviousStep,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppThemeData.spacingMD,
          vertical: AppThemeData.spacingSM,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back_ios,
            size: 14,
            color: theme.textSecondary,
          ),
          const SizedBox(width: AppThemeData.spacingXS),
          Text(
            'Back',
            style: theme.bodyMedium(color: theme.textSecondary).copyWith(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialAuth(AppThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: theme.borderLight.withValues(alpha: 0.5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppThemeData.spacingMD),
              child: Text(
                'or',
                style: theme.bodySmall(color: theme.textTertiary).copyWith(
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.borderLight.withValues(alpha: 0.5))),
          ],
        ),
        
        const SizedBox(height: AppThemeData.spacingLG),
        
        ThemedButton.secondary(
          context: context,
          text: 'Continue with Google',
          onPressed: _isLoading ? () {} : _handleGoogleSignIn,
          imageAsset: 'assets/icons/google.jpg',
        ),
      ],
    );
  }

  Widget _buildFooter(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: theme.bodyMedium().copyWith(
            fontSize: 14,
            color: theme.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.signup),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppThemeData.spacingXS,
              vertical: AppThemeData.spacingXS,
            ),
          ),
          child: Text(
            'Sign up',
            style: theme.bodyMedium(color: theme.primary).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(AppThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppThemeData.animationFast,
      curve: AppThemeData.smoothCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.all(AppThemeData.spacingMD),
            decoration: BoxDecoration(
              color: theme.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(theme.borderRadius),
              border: Border.all(
                color: theme.accentError.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.accentError,
                  size: 18,
                ),
                const SizedBox(width: AppThemeData.spacingSM),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.bodySmall(color: theme.accentError).copyWith(
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
