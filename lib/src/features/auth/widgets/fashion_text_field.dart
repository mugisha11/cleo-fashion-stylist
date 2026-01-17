import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fashion-oriented text field with floating label and animations
class FashionTextField extends StatefulWidget {
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
  final int? maxLines;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const FashionTextField({
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
    this.maxLines = 1,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<FashionTextField> createState() => _FashionTextFieldState();
}

class _FashionTextFieldState extends State<FashionTextField> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = widget.controller?.text.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasError
                  ? const Color(0xFFEF4444)
                  : _isFocused
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFD0D0D0),
              width: _isFocused ? 2 : 1,
            ),
            color: isDark ? Colors.grey.shade900 : const Color(0xFFFFFFFF),
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
              maxLines: widget.maxLines,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey.shade600,
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: _isFocused || hasValue ? 12 : 16,
                  color: _hasError
                      ? const Color(0xFFEF4444)
                      : _isFocused
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey.shade600,
                ),
                floatingLabelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _hasError
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF1A1A1A),
                ),
                hintStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade500,
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
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFEF4444),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(
                  begin: -0.2,
                  duration: 200.ms,
                ),
          ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(
          begin: -0.1,
          duration: 300.ms,
        );
  }
}

