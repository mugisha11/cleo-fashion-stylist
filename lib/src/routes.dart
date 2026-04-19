import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/avatar/screens/avatar_creation_screen.dart';
import 'features/avatar/screens/avatar_generation_screen.dart';
import 'features/wardrobe/screens/wardrobe_screen.dart';
import 'features/wardrobe/screens/add_item_screen.dart';
import 'features/tryon/screens/production_tryon_screen.dart';
import 'features/tryon/screens/luxury_tryon_screen.dart';
import 'features/tryon/screens/tryon_history_screen.dart';
import 'features/recommendations/screens/recommendations_screen.dart';
import 'features/virtualwearon/screens/virtualwearon_screen.dart';
import 'features/vton/screens/fashion_quiz_screen.dart';
import 'features/vton/screens/photo_capture_screen.dart';
import 'features/vton/screens/outfit_source_screen.dart';
import 'features/vton/screens/tryon_preview_screen.dart';
import 'features/onboarding/screens/fashion_questionnaire_screen.dart';
import 'features/calendar/screens/fashion_calendar_screen.dart';
import 'features/settings/screens/settings_page.dart';
import 'features/style_feed/screens/style_feed_screen.dart';
import 'features/style_feed/screens/post_look_screen.dart';
import 'features/social/screens/chats_list_screen.dart';
import 'features/social/screens/chat_screen.dart';
import 'features/social/screens/friend_requests_screen.dart';
import 'features/social/screens/discover_people_screen.dart';
import 'features/social/screens/generated_outfits_screen.dart';
import 'features/notifications/screens/notification_center_screen.dart';
import 'screens/dashboard_screen.dart';
import 'core/widgets/splash_screen.dart';

class Routes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String avatarCreation = '/avatar-creation';
  static const String avatarGeneration = '/avatar-generation';
  static const String wardrobe = '/wardrobe';
  static const String addItem = '/add-item';
  static const String tryon = '/tryon';
  static const String luxuryTryon = '/luxury-tryon';
  static const String premiumVton = '/premium-vton';
  static const String mobileVton = '/mobile-vton';
  static const String recommendations = '/recommendations';
  static const String virtualwearon = '/virtualwearon';
  static const String dashboard = '/dashboard';
  static const String fashionQuiz = '/fashion-quiz';
  static const String photoCapture = '/photo-capture';
  static const String outfitSource = '/outfit-source';
  static const String tryonPreview = '/tryon-preview';
  static const String fashionQuestionnaire = '/fashion-questionnaire';
  static const String calendar = '/calendar';
  static const String settings = '/settings';
  static const String tryonHistory = '/tryon-history';
  static const String styleFeed = '/style-feed';
  static const String postLook = '/post-look';
  static const String chats = '/chats';
  static const String chat = '/chat';
  static const String friendRequests = '/friend-requests';
  static const String discoverPeople = '/discover-people';
  static const String notificationCenter = '/notifications';
  static const String generatedOutfits = '/my-outfits';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case welcome:
        return _buildRoute(const WelcomeScreen(), settings);
      case signup:
        return _buildRoute(const SignUpScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case home:
        return _buildRoute(const ModernHomeScreen(), settings);
      case avatarCreation:
        return _buildRoute(const AvatarCreationScreen(), settings);
      case avatarGeneration:
        return _buildRoute(const AvatarGenerationScreen(), settings);
      case wardrobe:
        return _buildRoute(const WardrobeScreen(), settings);
      case addItem:
        return _buildRoute(const AddItemScreen(), settings);
      case tryon:
        return _buildRoute(const LuxuryTryOnScreen(), settings);
      case luxuryTryon:
        return _buildRoute(const LuxuryTryOnScreen(), settings);
      case premiumVton:
        return _buildRoute(const LuxuryTryOnScreen(), settings);
      case mobileVton:
        return _buildRoute(const ProductionTryOnScreen(), settings);
      case recommendations:
        return _buildRoute(const RecommendationsScreen(), settings);
      case virtualwearon:
        return _buildRoute(const VirtualWearOnScreen(), settings);
      case dashboard:
        // Dashboard landing page after login
        return _buildRoute(const DashboardScreen(), settings);
      case fashionQuiz:
        return _buildRoute(const FashionQuizScreen(), settings);
      case photoCapture:
        return _buildRoute(const PhotoCaptureScreen(), settings);
      case outfitSource:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          OutfitSourceScreen(photoUrl: args?['photoUrl'] ?? ''),
          settings,
        );
      case tryonPreview:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          TryOnPreviewScreen(sessionId: args?['sessionId'] ?? ''),
          settings,
        );
      case fashionQuestionnaire:
        return _buildRoute(const FashionQuestionnaireScreen(), settings);
      case calendar:
        return _buildRoute(const FashionCalendarScreen(), settings);
      case Routes.settings:
        return _buildRoute(const SettingsPage(), settings);
      case Routes.tryonHistory:
        return _buildRoute(const TryOnHistoryScreen(), settings);
      case Routes.styleFeed:
        return _buildRoute(const StyleFeedScreen(), settings);
      case Routes.postLook:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          PostLookScreen(
            imagePath: args?['imagePath'] as String?,
            imageBytes: args?['imageBytes'] is List<int>
                ? args!['imageBytes'] as List<int>
                : null,
            suggestedCaption: args?['suggestedCaption'] as String?,
          ),
          settings,
        );
      case Routes.chats:
        return _buildRoute(const ChatsListScreen(), settings);
      case Routes.chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ChatScreen(
            chatId: args?['chatId'] as String?,
            otherUserId: args?['otherUserId'] as String? ?? '',
            otherUserName: args?['otherUserName'] as String? ?? 'User',
            otherUserAvatar: args?['otherUserAvatar'] as String?,
          ),
          settings,
        );
      case Routes.friendRequests:
        return _buildRoute(const FriendRequestsScreen(), settings);
      case Routes.discoverPeople:
        return _buildRoute(const DiscoverPeopleScreen(), settings);
      case Routes.notificationCenter:
        return _buildRoute(const NotificationCenterScreen(), settings);
      case Routes.generatedOutfits:
        return _buildRoute(const GeneratedOutfitsScreen(), settings);
      default:
        return _buildRoute(
          const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
          settings,
        );
    }
  }

  static PageRoute<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
