import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';

class NXSmartSearchBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final VoidCallback onMicPressed;
  final bool isListening;
  final bool isProcessing;
  final Function(String) onSubmit;

  const NXSmartSearchBar({
    super.key,
    required this.controller,
    required this.onMicPressed,
    required this.isListening,
    required this.isProcessing,
    required this.onSubmit,
  });

  @override
  ConsumerState<NXSmartSearchBar> createState() => _NXSmartSearchBarState();
}

class _NXSmartSearchBarState extends ConsumerState<NXSmartSearchBar> {
  late FocusNode _focusNode;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus;
    });
  }

  void _selectSuggestion(String query) {
    widget.controller.text = query;
    _focusNode.unfocus();
    _showSuggestions = false;
    widget.onSubmit(query);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(searchSuggestionsProvider);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF08142E),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? const Color(0xFF4488FF)
                  : const Color(0xFF2A4070),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: [
              if (_focusNode.hasFocus)
                BoxShadow(
                  color: const Color(0xFF4488FF).withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: const Color(0xFF2255CC).withOpacity(0.3),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Row(
            children: [
              // NX logo
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF2255BB), Color(0xFF060F28)],
                  ),
                  border: Border.all(
                    color: const Color(0xFF3A5A8A).withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFAABBDD)],
                    ).createShader(r),
                    child: const Text(
                      'NX',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 1,
                height: 20,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(width: 10),

              // Text input
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask NX for Outfit Suggestions',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _selectSuggestion(value);
                    }
                  },
                ),
              ),

              // Microphone + Processing indicator
              if (widget.isProcessing)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        Colors.white.withOpacity(0.7),
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: widget.onMicPressed,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      widget.isListening ? Icons.mic : Icons.mic_none,
                      color: widget.isListening
                          ? Colors.redAccent
                          : Colors.white70,
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Autocomplete suggestions dropdown
        if (_showSuggestions && suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E4A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2A4070),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent Searches',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  ...suggestions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final suggestion = entry.value;
                    return GestureDetector(
                      onTap: () => _selectSuggestion(suggestion),
                      child: Container(
                        color: index % 2 == 0
                            ? Colors.white.withOpacity(0.04)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          )
        else if (_showSuggestions &&
            suggestions.isEmpty &&
            widget.controller.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E4A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2A4070),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Try asking:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._getExampleQueries().map((query) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: GestureDetector(
                        onTap: () => _selectSuggestion(query),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color: Color(0xFF4488FF),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                query,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<String> _getExampleQueries() => [
        'What should I wear to a job interview?',
        'Casual outfit for a coffee date',
        'Business casual for tomorrow',
        'Weekend brunch outfit',
        'Help me style this rainy day',
      ];
}
