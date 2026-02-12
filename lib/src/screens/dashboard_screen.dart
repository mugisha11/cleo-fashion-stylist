import 'dart:ui' show PlatformDispatcher;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/luxury_theme.dart';
import '../core/widgets/luxury_components.dart';
import '../core/widgets/dashboard_components.dart';
import 'dart:convert';

import '../core/constants/trusted_retailers.dart';
import '../core/services/ai_chat_firestore_service.dart';
import '../core/services/backend_config_service.dart';
import '../core/services/open_router_service.dart';
import '../core/services/sound_service.dart';
import '../core/services/tryon_service.dart';
import '../core/models/wardrobe_item_model.dart';
import '../core/providers/user_image_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/settings/models/settings_state.dart';
import '../features/settings/providers/settings_provider.dart';
import '../features/wardrobe/providers/wardrobe_provider.dart' show wardrobeItemsProvider;
import '../features/social/providers/social_provider.dart';
import '../routes.dart';
import '../core/models/user_model.dart';

/// 🎨 DASHBOARD SCREEN - Main UI with AI chat (Cleo), feed, and navigation.
/// Route: /dashboard (Routes.dashboard). Keep this screen for the AI chat.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _messageController;
  late ScrollController _chatScrollController;
  late AnimationController _wardrobeSlideController;
  final OpenRouterService _openRouter = OpenRouterService();
  final TryOnService _tryOnService = TryOnService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _imagePicker = ImagePicker();
  final AiChatFirestoreService _aiChatService = AiChatFirestoreService();

  List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text:
          'Hello! I\'m Cleo, your AI fashion assistant. How can I help you today?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  bool _showWardrobePanel = false;
  bool _isAITyping = false;
  bool _isListening = false;
  String _lastWords = '';
  Uint8List? _attachedImageBytes;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _chatScrollController = ScrollController();
    _wardrobeSlideController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChatFromDb());
  }

  /// Load persisted AI chat from Firestore so chat is not lost.
  Future<void> _loadChatFromDb() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null || uid.isEmpty || !mounted) return;
    try {
      final dtos = await _aiChatService.getMessages(uid);
      if (!mounted) return;
      if (dtos.isNotEmpty) {
        setState(() {
          _messages = dtos.map(_chatMessageFromDto).toList();
        });
      }
    } catch (_) {
      // Keep default welcome message on error
    }
  }

  void _persistMessage(ChatMessage m) {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null || uid.isEmpty) return;
    _aiChatService.saveMessage(uid, _dtoFromChatMessage(m));
  }

  AiChatMessageDto _dtoFromChatMessage(ChatMessage m) {
    return AiChatMessageDto(
      id: m.id,
      text: m.text,
      isUser: m.isUser,
      timestamp: m.timestamp,
      imageUrl: m.imageUrl,
      isError: m.isError,
      buyLinkUrl: m.buyLinkUrl,
      externalImageUrl: m.externalImageUrl,
      externalDisplayImageUrl: m.externalDisplayImageUrl,
      externalProductPageUrl: m.externalProductPageUrl,
      searchedProducts: m.searchedProducts?.map((p) => {
        'title': p.title,
        'imageUrl': p.imageUrl,
        'link': p.link,
        'displayImageUrl': p.displayImageUrl,
      }).toList(),
    );
  }

  ChatMessage _chatMessageFromDto(AiChatMessageDto d) {
    return ChatMessage(
      id: d.id,
      text: d.text,
      isUser: d.isUser,
      timestamp: d.timestamp,
      imageUrl: d.imageUrl,
      isError: d.isError,
      buyLinkUrl: d.buyLinkUrl,
      externalImageUrl: d.externalImageUrl,
      externalDisplayImageUrl: d.externalDisplayImageUrl,
      externalProductPageUrl: d.externalProductPageUrl,
      searchedProducts: d.searchedProducts?.map((map) => SearchedProduct(
        title: map['title'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        link: map['link'] ?? '',
        displayImageUrl: map['displayImageUrl'],
      )).toList(),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _wardrobeSlideController.dispose();
    super.dispose();
  }

  void _toggleWardrobePanel() {
    if (_showWardrobePanel) {
      _wardrobeSlideController.reverse();
    } else {
      _wardrobeSlideController.forward();
    }
    setState(() => _showWardrobePanel = !_showWardrobePanel);
  }

  Future<void> _pickImage() async {
    if (_isListening) return;
    final result = await showModalBottomSheet<Object>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.checkroom_outlined),
              title: const Text('From wardrobe'),
              onTap: () => Navigator.pop(context, 'wardrobe'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;

    if (result == 'wardrobe') {
      await _pickImageFromWardrobe();
      return;
    }

    final source = result as ImageSource;
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        if (mounted) setState(() => _attachedImageBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromWardrobe() async {
    // Refresh wardrobe so we get the same items as /wardrobe (same backend)
    ref.invalidate(wardrobeItemsProvider);
    List<WardrobeItemModel> items;
    try {
      items = await ref.read(wardrobeItemsProvider.future);
    } catch (_) {
      items = [];
    }
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your wardrobe is empty. Add items at Wardrobe.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isDark = context.isDarkMode;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Choose from wardrobe',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final imageUrl = item.processedImageUrl ?? item.imageUrl;
                    return GestureDetector(
                      onTap: () async {
                        try {
                          final response = await http.get(Uri.parse(imageUrl));
                          if (response.statusCode == 200 && context.mounted) {
                            final bytes = response.bodyBytes;
                            Navigator.pop(context);
                            if (mounted) setState(() => _attachedImageBytes = bytes);
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not load image'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not load image: $e'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
                                child: Icon(Icons.checkroom, color: context.textSecondaryColor),
                              ),
                            ),
                            Positioned(
                              left: 4,
                              right: 4,
                              bottom: 4,
                              child: Text(
                                item.category,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearAttachedImage() {
    setState(() => _attachedImageBytes = null);
  }

  /// Build a single block of user preferences (gender, body, style, colors, etc.) for the AI. AI must read this first.
  String _buildUserPreferencesSummary(UserModel? user, SettingsState settings) {
    final parts = <String>[];
    final body = user?.onboardingData?.bodyInputs;
    final onboarding = user?.onboardingData;

    // Gender — critical so AI never assumes
    if (body?.gender != null && body!.gender.isNotEmpty) {
      parts.add('Gender: ${body.gender}');
    } else {
      parts.add('Gender: not specified (ask if relevant)');
    }

    // Body type & height
    final bodyType = body?.bodyType ?? settings.bodyType;
    if (bodyType != null && bodyType.toString().isNotEmpty) {
      parts.add('Body type: $bodyType');
    }
    final height = body?.height ?? settings.height;
    if (height != null) {
      parts.add('Height: ${height.toStringAsFixed(0)} cm');
    }

    // Style preferences (settings)
    if (settings.preferredStyles != null && settings.preferredStyles.isNotEmpty) {
      parts.add('Preferred styles: ${settings.preferredStyles.join(', ')}');
    }
    if (settings.colorPreferences != null && settings.colorPreferences.isNotEmpty) {
      parts.add('Color preferences: ${settings.colorPreferences.join(', ')}');
    }
    if (settings.eventPreferences != null && settings.eventPreferences.isNotEmpty) {
      parts.add('Occasions/events: ${settings.eventPreferences.join(', ')}');
    }

    // Onboarding context
    if (onboarding != null) {
      if (onboarding.fashionStyle.isNotEmpty) {
        parts.add('Fashion style (go-to): ${onboarding.fashionStyle}');
      }
      if (onboarding.favoriteColors.isNotEmpty) {
        parts.add('Favorite colors: ${onboarding.favoriteColors}');
      }
      if (onboarding.occasion.isNotEmpty) {
        parts.add('Typical occasion: ${onboarding.occasion}');
      }
      if (onboarding.budget.isNotEmpty) {
        parts.add('Budget: ${onboarding.budget}');
      }
      if (onboarding.styleInspiration.isNotEmpty) {
        parts.add('Style inspiration: ${onboarding.styleInspiration}');
      }
    }

    if (parts.isEmpty) return 'No preferences set yet; ask the user if gender or style matters.';
    return parts.join('\n');
  }

  /// Handle Tips, Favorites, Trending, Style quick-action buttons.
  void _onQuickActionTap(String action) {
    String prompt;
    switch (action) {
      case 'tips':
        prompt = 'Give me styling tips for my wardrobe and how to put outfits together.';
        break;
      case 'favorites':
        prompt = 'Show my wardrobe and help me pick my favorite looks.';
        break;
      case 'trending':
        prompt = "What's trending in fashion right now? Show me some options I can try on.";
        break;
      case 'style':
        prompt = 'Help me with my personal style — what suits me and what pieces am I missing?';
        break;
      default:
        return;
    }
    _messageController.text = prompt;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachedImageBytes == null) return;

    _messageController.clear();
    HapticFeedback.mediumImpact();
    SoundService.play(AppSound.messageSent);
    final hadImage = _attachedImageBytes != null;
    if (mounted) setState(() => _attachedImageBytes = null);

    final displayText = text.isEmpty && hadImage
        ? '[Attached an image]'
        : text;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: displayText,
      isUser: true,
      timestamp: DateTime.now(),
      imageUrl: hadImage ? 'attached' : null,
    );
    setState(() {
      _messages.add(userMessage);
      _isAITyping = true;
    });
    _persistMessage(userMessage);
    _scrollToBottom();

    try {
      final apiKey = await OpenRouterService.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        if (mounted) {
          final errMsg = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text:
              'Add your OpenRouter API key in Settings → AI & Try-On Settings → Cleo Chat API Key to chat with Cleo. Get a key at openrouter.ai.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        );
        setState(() {
            _messages.add(errMsg);
            _isAITyping = false;
          });
        _persistMessage(errMsg);
          _scrollToBottom();
        }
        return;
      }

      final currentUser = ref.read(currentUserProvider).value;
      final settings = ref.read(settingsProvider);
      final wardrobeAsync = ref.read(wardrobeItemsProvider);
      final wardrobeSummary = wardrobeAsync.valueOrNull
          ?.map((WardrobeItemModel item) => {
                'id': item.id,
                'name':
                    '${item.category}${item.colorTags.isNotEmpty ? ' (${item.colorTags.join(', ')})' : ''}',
                'category': item.category,
              })
          .toList()
          .cast<Map<String, String>>();

      final userPreferencesSummary = _buildUserPreferencesSummary(currentUser, settings);
      final userCountryCode = PlatformDispatcher.instance.locale.countryCode;
      final systemPrompt = OpenRouterService.buildFashionSystemPrompt(
        userName: currentUser?.displayName ?? 'User',
        wardrobeSummary: wardrobeSummary ?? [],
        savedPhotoHint: 'User can try on outfits; their photo is saved in Settings.',
        userCountryCode: (userCountryCode != null && userCountryCode.isNotEmpty) ? userCountryCode : null,
        userPreferencesSummary: userPreferencesSummary,
      );

      final history = _messages
          .where((m) => !m.isError)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList()
          .cast<Map<String, String>>();

      final response = await _openRouter.chatWithFallback(
        messages: history,
        systemPrompt: systemPrompt,
        temperature: 0.7,
        maxTokens: 1024,
      );

      if (mounted) {
        final (displayText, tryOnId, showWardrobe, scheduleDate, buyLinkUrl, searchQuery) =
            _parseAssistantResponse(response);
        // Fallback: if user asked for wardrobe but AI didn't output SHOW_WARDROBE, show grid anyway
        final userAskedForWardrobe = _userAskedForWardrobe(text);
        final showWardrobeGrid = showWardrobe || (userAskedForWardrobe && tryOnId == null && scheduleDate == null);

        final aiMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: displayText,
          isUser: false,
          timestamp: DateTime.now(),
          buyLinkUrl: buyLinkUrl,
        );
        setState(() {
          _messages.add(aiMessage);
          _isAITyping = false;
        });
        _scrollToBottom();
        SoundService.play(AppSound.messageReceived);

        if (tryOnId != null) {
          _runTryOnInChat(tryOnId);
        } else if (showWardrobeGrid) {
          _showWardrobeInChat();
        } else if (scheduleDate != null) {
          _openScheduleForDate(scheduleDate);
        } else if (searchQuery != null && searchQuery.isNotEmpty) {
          _fetchAndShowSearchedProducts(searchQuery);
        }
        // Try-on from external link: if user sent a direct image URL, try it on
        final imageUrl = _extractDirectImageUrl(text);
        if (imageUrl != null) {
          _runTryOnWithGarmentUrl(imageUrl);
        } else {
          // Product page link: fetch image from backend and show in chat (user can then try on or buy)
          final productPageUrl = _extractProductPageUrl(text);
          if (productPageUrl != null) {
            _fetchAndShowExternalProduct(productPageUrl);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final errStr = e is OpenRouterException ? e.message : e.toString();
        final errorChatMsg = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Sorry, something went wrong: $errStr',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        );
        setState(() {
          _messages.add(errorChatMsg);
          _isAITyping = false;
        });
        _persistMessage(errorChatMsg);
        _scrollToBottom();
      }
    }
  }

  /// Extract first direct image URL from message (for try-on from external link).
  String? _extractDirectImageUrl(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;
    // Single token that is a direct image URL
    if (isDirectImageUrl(trimmed)) return trimmed;
    // Look for URLs in the text (space-separated or common patterns)
    final words = trimmed.split(RegExp(r'\s+'));
    for (final w in words) {
      final clean = w.replaceAll(RegExp(r'[.,!?)]+$'), '');
      if (isDirectImageUrl(clean)) return clean;
    }
    return null;
  }

  /// Extract first product-page URL (http(s) that is NOT a direct image) for link-preview.
  String? _extractProductPageUrl(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;
    final urlPattern = RegExp(r'https?://[^\s<>"{}|\\^`\[\]]+', caseSensitive: false);
    final match = urlPattern.firstMatch(trimmed);
    if (match == null) return null;
    var url = match.group(0) ?? '';
    url = url.replaceAll(RegExp(r'[.,!?)]+$'), '');
    if (url.isEmpty || isDirectImageUrl(url)) return null;
    return url;
  }

  /// Fetch product image from backend link-preview and show in chat.
  Future<void> _fetchAndShowExternalProduct(String pageUrl) async {
    String baseUrl;
    try {
      baseUrl = await BackendConfigService.getBackendUrl();
    } catch (_) {
      baseUrl = 'http://localhost:8001';
    }
    final uri = Uri.parse('$baseUrl/link-preview').replace(queryParameters: {'url': pageUrl});
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200 || resp.body.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load product image from link.'), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>?;
      if (data == null) return;
      final imageUrl = data['image_url'] as String?;
      final title = data['title'] as String?;
      final pageUrlReturned = data['page_url'] as String? ?? pageUrl;
      if (imageUrl == null || imageUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image found for this link.'), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }
      if (!mounted) return;
      final displayImageUrl = '$baseUrl/proxy-image?url=${Uri.encodeComponent(imageUrl)}';
      final previewMsg = ChatMessage(
        id: 'preview-${DateTime.now().millisecondsSinceEpoch}',
        text: title?.isNotEmpty == true ? title! : 'From your link — try it on or buy below.',
        isUser: false,
        timestamp: DateTime.now(),
        externalImageUrl: imageUrl,
        externalDisplayImageUrl: displayImageUrl,
        externalProductPageUrl: pageUrlReturned,
      );
      setState(() {
        _messages.add(previewMsg);
      });
      _persistMessage(previewMsg);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load product: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  /// Search for products (AI shopping) and show results in chat so user can try on or buy.
  Future<void> _fetchAndShowSearchedProducts(String query) async {
    String baseUrl;
    try {
      baseUrl = await BackendConfigService.getBackendUrl();
    } catch (_) {
      baseUrl = 'http://localhost:8001';
    }
    final uri = Uri.parse('$baseUrl/product-search').replace(queryParameters: {'q': query, 'limit': '8'});
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200 || resp.body.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not search products.'), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>?;
      if (data == null) return;
      final list = data['products'] as List<dynamic>?;
      if (list == null || list.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No products found.'), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }
      final products = <SearchedProduct>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final title = e['title'] as String? ?? '';
        final imageUrl = e['image_url'] as String? ?? '';
        final link = e['link'] as String? ?? '';
        if (title.isEmpty && imageUrl.isEmpty) continue;
        // Proxy URL so images display (external CDNs block direct browser requests)
        final displayImageUrl = imageUrl.isNotEmpty
            ? '$baseUrl/proxy-image?url=${Uri.encodeComponent(imageUrl)}'
            : null;
        products.add(SearchedProduct(
          title: title,
          imageUrl: imageUrl,
          link: link,
          displayImageUrl: displayImageUrl,
        ));
      }
      if (products.isEmpty) return;
      if (!mounted) return;
      final searchMsg = ChatMessage(
        id: 'search-${DateTime.now().millisecondsSinceEpoch}',
        text: 'Here are some options for "$query". Try on any image or tap Buy.',
        isUser: false,
        timestamp: DateTime.now(),
        searchedProducts: products,
      );
      setState(() {
        _messages.add(searchMsg);
      });
      _persistMessage(searchMsg);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  /// True if the user message clearly asks to see/show/list their wardrobe.
  bool _userAskedForWardrobe(String userMessage) {
    final lower = userMessage.trim().toLowerCase();
    if (!lower.contains('wardrobe')) return false;
    return lower.contains('show') ||
        lower.contains('see') ||
        lower.contains('list') ||
        lower.contains('my ') ||
        lower.contains('what') ||
        lower.contains('browse');
  }

  (String, String?, bool, String?, String?, String?) _parseAssistantResponse(String raw) {
    String display = raw;
    String? tryOnId;
    bool showWardrobe = false;
    String? scheduleDate;
    String? buyLinkUrl;
    String? searchQuery;
    final lines = raw.split('\n');
    final keep = <String>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('TRY_ON_ITEM_ID=')) {
        tryOnId = t.substring('TRY_ON_ITEM_ID='.length).trim();
      } else if (t == 'SHOW_WARDROBE') {
        showWardrobe = true;
      } else if (t.startsWith('SCHEDULE_FOR=')) {
        scheduleDate = t.substring('SCHEDULE_FOR='.length).trim();
      } else if (t.startsWith('BUY_LINK=')) {
        buyLinkUrl = t.substring('BUY_LINK='.length).trim();
        if (buyLinkUrl != null && !buyLinkUrl!.startsWith('http')) buyLinkUrl = 'https://$buyLinkUrl';
      } else if (t.startsWith('SEARCH_PRODUCTS=')) {
        searchQuery = t.substring('SEARCH_PRODUCTS='.length).trim();
      } else {
        keep.add(line);
      }
    }
    display = keep.join('\n').trim();
    if (display.isEmpty) display = raw;
    return (display, tryOnId, showWardrobe, scheduleDate, buyLinkUrl, searchQuery);
  }

  /// Run try-on in chat: add "in progress" message, call backend, then show result in chat.
  Future<void> _runTryOnInChat(String itemId) async {
    final items = ref.read(wardrobeItemsProvider).valueOrNull ?? [];
    WardrobeItemModel? item;
    for (final e in items) {
      if (e.id == itemId) {
        item = e;
        break;
      }
    }
    if (item == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item "$itemId" not found in wardrobe.'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    final garmentUrl = item.processedImageUrl ?? item.imageUrl;
    // Get try-on photo from Settings (Fashion Preferences) — await so we use latest from preferences
    ref.invalidate(userImageBytesProvider);
    Uint8List? userBytes;
    try {
      userBytes = await ref.read(userImageBytesProvider.future);
    } catch (_) {
      userBytes = null;
    }
    if (userBytes == null || userBytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add your try-on photo in Settings → Fashion Preferences (Body & Photo), then try again.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final progressId = 'tryon-${DateTime.now().millisecondsSinceEpoch}';
    final progressMsg = ChatMessage(
      id: progressId,
      text: 'Try-on in progress...',
      isUser: false,
      timestamp: DateTime.now(),
      isTryOnInProgress: true,
    );
    setState(() {
      _messages.add(progressMsg);
      _isAITyping = false;
    });
    _persistMessage(progressMsg);
    _scrollToBottom();

    try {
      final userBase64 = 'data:image/jpeg;base64,${base64Encode(userBytes)}';
      final result = await _tryOnService.generateTryOnPreviewFromBase64(
        userImageBase64: userBase64,
        clothingImageUrls: [garmentUrl],
      );
      Uint8List? resultBytes;
      if (result.startsWith('http')) {
        final res = await http.get(Uri.parse(result));
        if (res.statusCode == 200) resultBytes = res.bodyBytes;
      } else if (result.startsWith('data:') && result.contains(',')) {
        final b64 = result.split(',').last;
        resultBytes = base64Decode(b64);
      } else if (result.length > 100 && !result.startsWith('http')) {
        resultBytes = base64Decode(result);
      }
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == progressId);
      if (idx >= 0) {
        final doneMsg = ChatMessage(
          id: progressId,
          text: "Here's your try-on!",
          isUser: false,
          timestamp: DateTime.now(),
          tryOnResultImageBytes: resultBytes,
        );
        setState(() {
          _messages[idx] = doneMsg;
        });
        _persistMessage(doneMsg);
      }
      _scrollToBottom();
      SoundService.play(AppSound.messageReceived);
    } catch (e) {
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == progressId);
      if (idx >= 0) {
        final tryOnErrMsg = ChatMessage(
          id: progressId,
          text: 'Try-on failed: ${e is TryOnException ? e.getUserMessage() : e}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        );
        setState(() => _messages[idx] = tryOnErrMsg);
        _persistMessage(tryOnErrMsg);
      }
      _scrollToBottom();
    }
  }

  /// Run try-on in chat using an external garment image URL (e.g. from Zalando, OTTO).
  Future<void> _runTryOnWithGarmentUrl(String garmentUrl) async {
    ref.invalidate(userImageBytesProvider);
    Uint8List? userBytes;
    try {
      userBytes = await ref.read(userImageBytesProvider.future);
    } catch (_) {
      userBytes = null;
    }
    if (userBytes == null || userBytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add your try-on photo in Settings → Fashion Preferences, then try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final progressId = 'tryon-url-${DateTime.now().millisecondsSinceEpoch}';
    final progressMsg = ChatMessage(
      id: progressId,
      text: 'Try-on in progress (from link)...',
      isUser: false,
      timestamp: DateTime.now(),
      isTryOnInProgress: true,
    );
    setState(() {
      _messages.add(progressMsg);
    });
    _persistMessage(progressMsg);
    _scrollToBottom();

    try {
      final userBase64 = 'data:image/jpeg;base64,${base64Encode(userBytes)}';
      final result = await _tryOnService.generateTryOnPreviewFromBase64(
        userImageBase64: userBase64,
        clothingImageUrls: [garmentUrl],
      );
      Uint8List? resultBytes;
      if (result.startsWith('http')) {
        final res = await http.get(Uri.parse(result));
        if (res.statusCode == 200) resultBytes = res.bodyBytes;
      } else if (result.startsWith('data:') && result.contains(',')) {
        resultBytes = base64Decode(result.split(',').last);
      } else if (result.length > 100 && !result.startsWith('http')) {
        resultBytes = base64Decode(result);
      }
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == progressId);
      if (idx >= 0) {
        final doneMsg = ChatMessage(
          id: progressId,
          text: "Here's your try-on from the link!",
          isUser: false,
          timestamp: DateTime.now(),
          tryOnResultImageBytes: resultBytes,
        );
        setState(() => _messages[idx] = doneMsg);
        _persistMessage(doneMsg);
      }
      _scrollToBottom();
      SoundService.play(AppSound.messageReceived);
    } catch (e) {
      if (!mounted) return;
      final idx = _messages.indexWhere((m) => m.id == progressId);
      if (idx >= 0) {
        final tryOnErrMsg = ChatMessage(
          id: progressId,
          text: 'Try-on failed: ${e is TryOnException ? e.getUserMessage() : e}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        );
        setState(() => _messages[idx] = tryOnErrMsg);
        _persistMessage(tryOnErrMsg);
      }
      _scrollToBottom();
    }
  }

  void _openScheduleForDate(String dateIso) {
    Navigator.of(context).pushNamed(Routes.calendar);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calendar opened — add an outfit for $dateIso'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show wardrobe in chat: add message with grid of items and "Try on" in chat.
  Future<void> _showWardrobeInChat() async {
    ref.invalidate(wardrobeItemsProvider);
    List<WardrobeItemModel> list;
    try {
      list = await ref.read(wardrobeItemsProvider.future);
    } catch (_) {
      list = [];
    }
    if (!mounted) return;
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: list.isEmpty ? 'Your wardrobe is empty. Add items in Wardrobe.' : "Here's your wardrobe. Tap Try on on any item.",
      isUser: false,
      timestamp: DateTime.now(),
      wardrobeItems: list.isEmpty ? null : list,
    );
    setState(() {
      _messages.add(msg);
      _isAITyping = false;
    });
    _persistMessage(msg);
    _scrollToBottom();
  }

  Future<void> _startVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      if (_lastWords.trim().isNotEmpty && mounted) {
        _messageController.text = _lastWords.trim();
      }
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (mounted && (status == 'done' || status == 'notListening')) {
          setState(() => _isListening = false);
          if (_lastWords.trim().isNotEmpty) {
            _messageController.text = _lastWords.trim();
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.errorMsg),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input is not available on this device.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _lastWords = '';
    setState(() => _isListening = true);
    HapticFeedback.mediumImpact();

    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        // ChatGPT-style: live transcript in the input field as you speak
        if (mounted) {
          _messageController.text = _lastWords;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _lastWords.length),
          );
          setState(() {});
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: null,
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 600;

    ref.listen(socialUnreadCountProvider, (prev, next) {
      final prevCount = prev;
      final nextCount = next;
      if (prevCount != null && nextCount != null && nextCount > prevCount && nextCount > 0) {
        SoundService.play(AppSound.notification);
      }
    });

    return Scaffold(
      appBar: DashboardTopBar(
        aiStatus: _isListening
            ? 'Listening...'
            : (_isAITyping ? 'Analyzing...' : 'Ready to assist'),
        isAITyping: _isAITyping || _isListening,
        notificationCount: ref.watch(socialUnreadCountProvider),
        onProfileTap: () {
          Navigator.of(context).pushNamed(Routes.settings);
        },
        onNotificationsTap: () {
          Navigator.of(context).pushNamed(Routes.notificationCenter);
        },
      ),
      drawer: _buildNavigationDrawer(context),
      endDrawer: null,
      body: Row(
        children: [
          // Main Content Area — when chat has messages, only chat (no carousel/sidebar/FAB)
          Expanded(
            child: Column(
              children: [
                if (_messages.isEmpty) _buildRecommendationCarousel(context),
                Expanded(child: _buildChatArea(context)),
                MessageInputBar(
                  controller: _messageController,
                  onSendMessage: _sendMessage,
                  onImagePick: _pickImage,
                  onMicTap: _startVoiceInput,
                  isLoading: _isAITyping,
                  isListening: _isListening,
                  attachedImageBytes: _attachedImageBytes,
                  onRemoveAttachedImage: _clearAttachedImage,
                  onQuickActionTap: _onQuickActionTap,
                ),
              ],
            ),
          ),
          if (!isMobile && _messages.isEmpty)
            Container(
              width: DesignTokens.wardrobeSidebarWidth,
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
                border: Border(
                  left: BorderSide(
                    color: isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.lightBorder,
                    width: 0.5,
                  ),
                ),
              ),
              child: _buildWardrobePanel(context),
            ),
        ],
      ),
      floatingActionButton: isMobile && _messages.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 160),
              child: FloatingActionButton.extended(
                onPressed: _toggleWardrobePanel,
                label: const Text('Wardrobe'),
                icon: const Icon(Icons.checkroom),
                backgroundColor:
                    isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final isDark = context.isDarkMode;
    return Drawer(
      child: Container(
        color:
            isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.lightBorder,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cleo Fashion',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? DesignTokens.darkAccent
                              : DesignTokens.lightAccent,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your style companion',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _buildNavItem(
              context: context,
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.auto_awesome_outlined,
              label: 'Try On',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.tryon);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.checkroom_outlined,
              label: 'My Closet',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.wardrobe);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.star_outline,
              label: 'Picks for You',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.recommendations);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.calendar_today_outlined,
              label: 'Calendar',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.calendar);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.grid_view_rounded,
              label: 'Style Feed',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.styleFeed);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.photo_library_outlined,
              label: 'My Outfits',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.generatedOutfits);
              },
            ),
            const Divider(),
            _buildNavItem(
              context: context,
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(Routes.settings);
              },
            ),
            _buildNavItem(
              context: context,
              icon: Icons.help_outline,
              label: 'Help',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help section coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? DesignTokens.darkAccent : DesignTokens.lightAccent,
      ),
      title: Text(label),
      onTap: onTap,
      hoverColor: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
    );
  }

  Widget _buildRecommendationCarousel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended for you',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                RecommendationCard(
                  title: 'Summer Collection',
                  subtitle: 'Light & breathable styles',
                  imageUrl:
                      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=500&fit=crop',
                  icon: Icons.sunny,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Opening Summer Collection')),
                    );
                  },
                ),
                const SizedBox(width: DesignTokens.spacingMd),
                RecommendationCard(
                  title: 'Casual Chic',
                  subtitle: 'Effortless everyday looks',
                  imageUrl:
                      'https://images.unsplash.com/photo-1515575227652-8d992ee8c5d1?w=400&h=500&fit=crop',
                  icon: Icons.favorite,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Casual Chic')),
                    );
                  },
                ),
                const SizedBox(width: DesignTokens.spacingMd),
                RecommendationCard(
                  title: 'Evening Elegance',
                  subtitle: 'Sophisticated evening wear',
                  imageUrl:
                      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&h=500&fit=crop',
                  icon: Icons.diamond,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Evening Elegance')),
                    );
                  },
                ),
                const SizedBox(width: DesignTokens.spacingMd),
                RecommendationCard(
                  title: 'Try-On Experience',
                  subtitle: 'See how items look on you',
                  imageUrl:
                      'https://images.unsplash.com/photo-1561181286-d3fee7d55364?w=400&h=500&fit=crop',
                  icon: Icons.image_search,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Virtual Try-On')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      color:
          isDark ? DesignTokens.darkBackground : DesignTokens.lightBackground,
      child: ListView.builder(
        controller: _chatScrollController,
        padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.spacingMd,
        ),
        itemCount: _messages.length + (_isAITyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isAITyping && index == _messages.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingSm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(DesignTokens.spacingMd),
                  child: AITypingIndicator(),
                ),
              ),
            );
          }

          final message = _messages[index];
          if (message.wardrobeItems != null && message.wardrobeItems!.isNotEmpty) {
            return _buildWardrobeMessageBubble(message, isDark, context);
          }
          if (message.externalImageUrl != null && message.externalImageUrl!.isNotEmpty) {
            return _buildExternalProductBubble(message, isDark, context);
          }
          if (message.searchedProducts != null && message.searchedProducts!.isNotEmpty) {
            return _buildSearchedProductsBubble(message, isDark, context);
          }
          return ChatMessageBubble(
            message: message.isTryOnInProgress
                ? '${message.text}'
                : message.text,
            isUser: message.isUser,
            timestamp: message.timestamp,
            imagePreview: message.tryOnResultImageBytes != null
                ? Image.memory(
                    message.tryOnResultImageBytes!,
                    fit: BoxFit.contain,
                    width: 280,
                    height: 320,
                  )
                : null,
            buyLinkUrl: message.buyLinkUrl,
          );
        },
      ),
    );
  }

  Widget _buildWardrobeMessageBubble(
    ChatMessage message,
    bool isDark,
    BuildContext context,
  ) {
    final items = message.wardrobeItems!;
    final luxuryTheme = context.luxuryTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          decoration: BoxDecoration(
            color: luxuryTheme.chatAIBubble,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final imageUrl = item.processedImageUrl ?? item.imageUrl;
                    return SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                            child: Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: DesignTokens.darkCard,
                                child: Icon(Icons.checkroom, color: context.textSecondaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.category,
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          TextButton(
                            onPressed: () => _runTryOnInChat(item.id),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Try on'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExternalProductBubble(
    ChatMessage message,
    bool isDark,
    BuildContext context,
  ) {
    final luxuryTheme = context.luxuryTheme;
    final imageUrl = message.externalImageUrl!;
    final displayImageUrl = message.externalDisplayImageUrl ?? imageUrl;
    final pageUrl = message.externalProductPageUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          decoration: BoxDecoration(
            color: luxuryTheme.chatAIBubble,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: Image.network(
                  displayImageUrl,
                  width: 280,
                  height: 280,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) =>
                      progress == null
                          ? child
                          : SizedBox(
                              width: 280,
                              height: 280,
                              child: Center(
                                child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            (progress.expectedTotalBytes ?? 1)
                                        : null),
                              ),
                            ),
                  errorBuilder: (_, __, ___) => Container(
                    width: 280,
                    height: 200,
                    color: DesignTokens.darkCard,
                    child: Icon(Icons.broken_image_outlined, color: context.textSecondaryColor, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () => _runTryOnWithGarmentUrl(imageUrl),
                    icon: const Icon(Icons.checkroom, size: 18),
                    label: const Text('Try on'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (pageUrl != null && pageUrl.isNotEmpty) ...[
                    const SizedBox(width: DesignTokens.spacingSm),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(pageUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Buy'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchedProductsBubble(
    ChatMessage message,
    bool isDark,
    BuildContext context,
  ) {
    final luxuryTheme = context.luxuryTheme;
    final products = message.searchedProducts!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          decoration: BoxDecoration(
            color: luxuryTheme.chatAIBubble,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                    ),
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return SizedBox(
                      width: 140,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                            child: Image.network(
                              p.displayImageUrl ?? p.imageUrl,
                              width: 120,
                              height: 140,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : SizedBox(
                                          width: 120,
                                          height: 140,
                                          child: Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  value: progress.expectedTotalBytes != null
                                                      ? progress.cumulativeBytesLoaded /
                                                          (progress.expectedTotalBytes ?? 1)
                                                      : null),
                                            ),
                                          ),
                                        ),
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 140,
                                color: DesignTokens.darkCard,
                                child: Icon(Icons.checkroom, color: context.textSecondaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.title,
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () => _runTryOnWithGarmentUrl(p.imageUrl),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Try on'),
                              ),
                              if (p.link.isNotEmpty)
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      final uri = Uri.parse(p.link);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    } catch (_) {}
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Buy'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWardrobePanel(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          child: Text(
            'Your Wardrobe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            mainAxisSpacing: DesignTokens.spacingMd,
            crossAxisSpacing: DesignTokens.spacingMd,
            children: List.generate(
              6,
              (index) => WardrobeItemCard(
                imageUrl:
                    'https://images.unsplash.com/photo-1591959375444-7c6a2c59ddc4?w=300&h=300&fit=crop',
                category: [
                  'Tops',
                  'Bottoms',
                  'Dresses',
                  'Outerwear',
                  'Shoes',
                  'Accessories'
                ][index],
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected ${[
                        'Tops',
                        'Bottoms',
                        'Dresses',
                        'Outerwear',
                        'Shoes',
                        'Accessories'
                      ][index]}'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 💬 CHAT MESSAGE MODEL
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isError;
  /// Try-on result image (in-chat try-on)
  final Uint8List? tryOnResultImageBytes;
  /// Wardrobe grid in chat (show items + Try on)
  final List<WardrobeItemModel>? wardrobeItems;
  /// Placeholder while try-on is running
  final bool isTryOnInProgress;
  /// Buy link: shown as "Buy this outfit" when user asks where to buy
  final String? buyLinkUrl;
  /// Product image from external link (fetched via link-preview) — for try-on
  final String? externalImageUrl;
  /// Proxy URL for displaying external product image (avoids CORS)
  final String? externalDisplayImageUrl;
  /// Product page URL for "Buy" when message shows external product image
  final String? externalProductPageUrl;
  /// AI shopping search results (product images + Try on + Buy)
  final List<SearchedProduct>? searchedProducts;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
    this.isError = false,
    this.tryOnResultImageBytes,
    this.wardrobeItems,
    this.isTryOnInProgress = false,
    this.buyLinkUrl,
    this.externalImageUrl,
    this.externalDisplayImageUrl,
    this.externalProductPageUrl,
    this.searchedProducts,
  });
}

/// One product from AI shopping search (image + link for try-on and buy).
class SearchedProduct {
  final String title;
  final String imageUrl;
  final String link;
  /// Proxy URL for display (avoids CORS); try-on uses [imageUrl].
  final String? displayImageUrl;

  SearchedProduct({
    required this.title,
    required this.imageUrl,
    required this.link,
    this.displayImageUrl,
  });
}
