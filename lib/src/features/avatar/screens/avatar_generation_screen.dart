import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes.dart';
import '../services/ready_player_me_avatar_service.dart';
import '../widgets/avatar_3d_viewer.dart';
import '../../auth/widgets/fashion_gradient_button.dart';

/// Premium Avatar Generation Screen
/// Integrates Ready Player Me creator with postMessage handling
/// Renders 3D avatars and saves to Firebase
class AvatarGenerationScreen extends ConsumerStatefulWidget {
  const AvatarGenerationScreen({super.key});

  @override
  ConsumerState<AvatarGenerationScreen> createState() =>
      _AvatarGenerationScreenState();
}

class _AvatarGenerationScreenState
    extends ConsumerState<AvatarGenerationScreen> {
  // Step tracking
  int _currentStep = 0; // 0: Create, 1: Preview, 2: Save

  // Ready Player Me service
  final _rpmService = ReadyPlayerMeAvatarService();

  // WebView controller
  WebViewController? _webViewController;

  // Avatar data
  String? _avatarId;
  String? _glbUrl;
  String? _previewUrl;
  bool _isLoadingAvatar = false;
  String? _errorMessage;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// Initialize WebView for Ready Player Me creator
  void _initializeWebView() {
    final user = FirebaseAuth.instance.currentUser;
    final creatorUrl = _rpmService.getCreatorUrl(
      userId: user?.uid,
      clearCache: 'false',
    );

    if (kIsWeb) {
      // Web platform - use iframe approach
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _injectPostMessageListener();
            },
          ),
        )
        ..loadRequest(Uri.parse(creatorUrl));
    } else {
      // Mobile platform
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _injectPostMessageListener();
            },
          ),
        )
        ..addJavaScriptChannel(
          'AvatarChannel',
          onMessageReceived: (JavaScriptMessage message) {
            _handlePostMessage(message.message);
          },
        )
        ..loadRequest(Uri.parse(creatorUrl));
    }
  }

  /// Inject JavaScript to listen for postMessage from Ready Player Me
  void _injectPostMessageListener() {
    const script = '''
      (function() {
        window.addEventListener('message', function(event) {
          // Ready Player Me sends avatar data via postMessage
          if (event.data && typeof event.data === 'object') {
            if (event.data.type === 'vrm.avatar.exported' || 
                event.data.avatarId || 
                event.data.source === 'readyplayerme') {
              // Send to Flutter
              if (window.AvatarChannel) {
                window.AvatarChannel.postMessage(JSON.stringify(event.data));
              } else {
                // Fallback for web
                window.flutter_inappwebview?.callHandler('onAvatarCreated', event.data);
              }
            }
          }
        });
        
        // Also listen for URL changes (some RPM implementations use this)
        let lastUrl = location.href;
        setInterval(function() {
          if (location.href !== lastUrl) {
            lastUrl = location.href;
            const urlParams = new URLSearchParams(location.search);
            const avatarId = urlParams.get('avatarId') || urlParams.get('id');
            if (avatarId) {
              if (window.AvatarChannel) {
                window.AvatarChannel.postMessage(JSON.stringify({avatarId: avatarId}));
              }
            }
          }
        }, 1000);
      })();
    ''';

    _webViewController?.runJavaScript(script);
  }

  /// Handle postMessage from Ready Player Me iframe
  void _handlePostMessage(String message) {
    try {
      final data = jsonDecode(message);
      final avatarId = _rpmService.parseAvatarIdFromMessage(data);

      if (avatarId != null && avatarId != _avatarId) {
        setState(() {
          _avatarId = avatarId;
          _currentStep = 1; // Move to preview step
          _errorMessage = null;
        });

        // Fetch and validate avatar
        _fetchAvatarGlb(avatarId);
      }
    } catch (e) {
      debugPrint('Error handling postMessage: $e');
    }
  }

  /// Fetch GLB URL with retry logic
  Future<void> _fetchAvatarGlb(String avatarId) async {
    setState(() {
      _isLoadingAvatar = true;
      _errorMessage = null;
    });

    try {
      // Get valid avatar URL with fallback
      final glbUrl = await _rpmService.getValidAvatarUrl(avatarId);

      if (glbUrl != null) {
        setState(() {
          _glbUrl = glbUrl;
          _previewUrl = 'https://models.readyplayer.me/$avatarId.png';
          _isLoadingAvatar = false;
          _retryCount = 0;
        });

        // Auto-save to Firebase
        await _saveAvatarToFirebase();
      } else {
        // Retry with different parameters
        if (_retryCount < 3) {
          _retryCount++;
          await Future.delayed(const Duration(seconds: 2));
          await _fetchAvatarGlb(avatarId);
        } else {
          setState(() {
            _errorMessage =
                'Avatar not available yet. Please try again in a few moments.';
            _isLoadingAvatar = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load avatar: ${e.toString()}';
        _isLoadingAvatar = false;
      });
    }
  }

  /// Save avatar to Firebase
  Future<void> _saveAvatarToFirebase() async {
    if (_avatarId == null || _glbUrl == null) return;

    try {
      await _rpmService.saveAvatarToFirebase(
        avatarId: _avatarId!,
        glbUrl: _glbUrl!,
        previewUrl: _previewUrl,
      );

      setState(() {
        _currentStep = 2; // Move to save step
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save avatar: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Navigate to try-on page
  void _continueToTryOn() {
    Navigator.of(context).pushReplacementNamed(Routes.tryon);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isWeb = screenWidth > 1024;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF121212),
                    Color(0xFF1E1E1E),
                    Color(0xFF121212),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFFDFDFD),
                    Colors.white,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with step indicator
              _buildHeader(isDark, isWeb),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 80 : isTablet ? 40 : 24,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      // Step content
                      if (_currentStep == 0) _buildCreateStep(isDark),
                      if (_currentStep == 1) _buildPreviewStep(isDark),
                      if (_currentStep == 2) _buildSaveStep(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build header with step indicator
  Widget _buildHeader(bool isDark, bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 80 : 40,
        vertical: 24,
      ),
      child: Column(
        children: [
          // Title
          Text(
            'Create Your Virtual Twin',
            style: TextStyle(fontFamily: 'system-ui', 
              fontSize: isWeb ? 36 : 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.2, duration: 400.ms),
          const SizedBox(height: 32),
          // Step indicator
          _buildStepIndicator(isDark),
        ],
      ),
    );
  }

  /// Build step indicator
  Widget _buildStepIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepItem('Create Avatar', 0, isDark),
        _buildStepConnector(isDark),
        _buildStepItem('Preview', 1, isDark),
        _buildStepConnector(isDark),
        _buildStepItem('Save', 2, isDark),
      ],
    );
  }

  Widget _buildStepItem(String label, int step, bool isDark) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive || isCompleted
                ? const LinearGradient(
                    colors: [Color(0xFF4B39EF), Color(0xFF39D2C0)],
                  )
                : null,
            color: isActive || isCompleted
                ? null
                : isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
            border: isActive || isCompleted
                ? null
                : Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                    width: 2,
                  ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(fontFamily: 'system-ui', 
                      color: isActive || isCompleted
                          ? Colors.white
                          : isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontFamily: 'system-ui', 
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive || isCompleted
                ? const Color(0xFF4B39EF)
                : isDark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isDark) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: _currentStep > 0
              ? const LinearGradient(
                  colors: [Color(0xFF4B39EF), Color(0xFF39D2C0)],
                )
              : null,
          color: _currentStep > 0
              ? null
              : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
        ),
      ),
    );
  }

  /// Build create avatar step
  Widget _buildCreateStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // WebView container
        Container(
          height: 600,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _webViewController != null
                ? WebViewWidget(controller: _webViewController!)
                : const Center(child: CircularProgressIndicator()),
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(duration: 400.ms, begin: const Offset(0.95, 0.95)),
        const SizedBox(height: 32),
        // Instructions
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF4B39EF),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'How to create your avatar',
                    style: TextStyle(fontFamily: 'system-ui', 
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInstructionItem(
                '1',
                'Customize your avatar\'s appearance',
                isDark,
              ),
              _buildInstructionItem(
                '2',
                'Choose your style and accessories',
                isDark,
              ),
              _buildInstructionItem(
                '3',
                'Click "Done" when finished',
                isDark,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .slideY(begin: 0.2, duration: 500.ms, delay: 200.ms),
      ],
    );
  }

  Widget _buildInstructionItem(String number, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF4B39EF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(fontFamily: 'system-ui', 
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontFamily: 'system-ui', 
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build preview step
  Widget _buildPreviewStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3D Avatar Preview
        if (_isLoadingAvatar)
          const AvatarLoadingShimmer(height: 500)
        else if (_glbUrl != null)
          Avatar3DViewer(
            glbUrl: _glbUrl!,
            height: 500,
            errorMessage: _errorMessage,
            onError: _avatarId != null
                ? () => _fetchAvatarGlb(_avatarId!)
                : null,
          )
        else
          Container(
            height: 500,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your avatar...',
                    style: TextStyle(fontFamily: 'system-ui', 
                      fontSize: 16,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 32),
        // Action buttons
        if (_glbUrl != null)
          FashionGradientButton(
            text: 'Use This Avatar',
            icon: Icons.check_circle_outline,
            onPressed: _saveAvatarToFirebase,
            isLoading: false,
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(duration: 300.ms, begin: const Offset(0.95, 0.95)),
      ],
    );
  }

  /// Build save step
  Widget _buildSaveStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success message
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4B39EF), Color(0xFF39D2C0)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4B39EF).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Avatar Created Successfully!',
                style: TextStyle(fontFamily: 'system-ui', 
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your virtual twin is ready to try on outfits',
                style: TextStyle(fontFamily: 'system-ui', 
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(duration: 400.ms, begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 32),
        // Continue button
        FashionGradientButton(
          text: 'Continue to Try On',
          icon: Icons.arrow_forward,
          onPressed: _continueToTryOn,
          isLoading: false,
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .scale(duration: 400.ms, delay: 200.ms, begin: const Offset(0.95, 0.95)),
      ],
    );
  }
}

