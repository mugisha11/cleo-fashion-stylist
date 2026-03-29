import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/auth_design_system.dart';

/// Premium text field with Canva/Discord-inspired styling
class PremiumTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const PremiumTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.enabled = true,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AuthDesignSystem.radiusSM),
            border: Border.all(
              color: _hasError
                  ? AuthDesignSystem.errorRed
                  : _isFocused
                      ? AuthDesignSystem.borderFocus
                      : AuthDesignSystem.borderLight,
              width: _isFocused ? 2 : 1.5,
            ),
            color: AuthDesignSystem.surfaceWhite,
          ),
          child: Focus(
            focusNode: _focusNode,
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textCapitalization: widget.textCapitalization,
              validator: (value) {
                final error = widget.validator?.call(value);
                setState(() => _hasError = error != null);
                return error;
              },
              onChanged: (value) {
                widget.onChanged?.call(value);
                setState(() {});
              },
              inputFormatters: widget.inputFormatters,
              enabled: widget.enabled,
              style: TextStyle(fontFamily: 'system-ui', 
                fontSize: isMobile ? 15 : 16,
                color: AuthDesignSystem.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused
                            ? AuthDesignSystem.borderFocus
                            : AuthDesignSystem.textSecondary,
                        size: 20,
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                labelStyle: TextStyle(fontFamily: 'system-ui', 
                  fontSize: 14,
                  color: _hasError
                      ? AuthDesignSystem.errorRed
                      : _isFocused
                          ? AuthDesignSystem.borderFocus
                          : AuthDesignSystem.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelStyle: TextStyle(fontFamily: 'system-ui', 
                  fontSize: 12,
                  color: _hasError
                      ? AuthDesignSystem.errorRed
                      : AuthDesignSystem.borderFocus,
                  fontWeight: FontWeight.w600,
                ),
                hintStyle: TextStyle(fontFamily: 'system-ui', 
                  fontSize: isMobile ? 15 : 16,
                  color: AuthDesignSystem.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        if (_hasError && widget.controller?.text.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              widget.validator?.call(widget.controller?.text) ?? '',
              style: const TextStyle(fontFamily: 'system-ui', 
                fontSize: 12,
                color: AuthDesignSystem.errorRed,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(
                  begin: -0.2,
                  duration: 200.ms,
                ),
          ),
      ],
    );
  }
}



