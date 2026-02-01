/// Push Notification Service
/// Handles Firebase Cloud Messaging (FCM) for Android, iOS, and Web
library;
import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'notification_intelligence.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message received: ${message.messageId}');
  // Handle background notification
}

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final NotificationIntelligence _intelligence = NotificationIntelligence();
  
  StreamController<FashionNotification>? _notificationStream;
  Stream<FashionNotification>? get notificationStream => _notificationStream?.stream;
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize push notification service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Request permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get FCM token
      await _getFCMToken();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      // Set up token refresh listener
      _setupTokenRefresh();
      
      // Initialize stream
      _notificationStream = StreamController<FashionNotification>.broadcast();
      
      _initialized = true;
      debugPrint('✅ Push Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize push notifications: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      // Web: Request browser notification permission
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('📱 Web notification permission: ${settings.authorizationStatus}');
    } else if (Platform.isIOS) {
      // iOS: Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('📱 iOS notification permission: ${settings.authorizationStatus}');
    } else if (Platform.isAndroid) {
      // Android: Request permission (Android 13+)
      final androidSettings = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      debugPrint('📱 Android notification permission: $androidSettings');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android == null) return;
    
    // Try-on notifications channel
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'tryon_notifications',
        'Try-On Updates',
        description: 'Notifications for AI try-on job status',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    
    // Calendar notifications channel
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'calendar_notifications',
        'Calendar Reminders',
        description: 'Outfit planning and event reminders',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );
    
    // System notifications channel
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'system_notifications',
        'System Updates',
        description: 'App updates and security alerts',
        importance: Importance.low,
        playSound: false,
      ),
    );
  }

  /// Get FCM token and save to Firestore
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null && _auth.currentUser != null) {
        // Save token to Firestore
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('tokens')
            .doc(_fcmToken)
            .set({
          'token': _fcmToken,
          'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('✅ FCM Token saved: ${_fcmToken!.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // App opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);
    
    // Check if app was opened from notification
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationOpened(message);
      }
    });
  }

  /// Handle foreground message (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground message: ${message.messageId}');
    
    // Use intelligence to decide if we should show notification
    final shouldNotify = await _intelligence.shouldNotify(
      message.data,
      NotificationContext.foreground,
    );
    
    if (!shouldNotify) {
      debugPrint('🤫 Intelligence decided to suppress notification');
      return;
    }
    
    // Convert to FashionNotification
    final notification = _parseRemoteMessage(message);
    
    // Show local notification
    await _showLocalNotification(notification);
    
    // Emit to stream
    _notificationStream?.add(notification);
  }

  /// Handle notification opened (user tapped notification)
  Future<void> _handleNotificationOpened(RemoteMessage message) async {
    debugPrint('👆 Notification opened: ${message.messageId}');
    
    final notification = _parseRemoteMessage(message);
    
    // Handle deep link
    if (notification.actionUrl != null) {
      debugPrint('🔗 Deep link: ${notification.actionUrl}');
      // Use static method for background/terminated state
      await handleDeepLinkGlobal(notification.actionUrl);
    }
    
    // Mark as read
    // This will be handled by the notification service
  }

  /// Parse RemoteMessage to FashionNotification
  FashionNotification _parseRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    
    return FashionNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _parseNotificationType(data['type'] as String?),
      title: notification?.title ?? data['title'] as String? ?? 'Notification',
      message: notification?.body ?? data['message'] as String? ?? '',
      createdAt: message.sentTime ?? DateTime.now(),
      state: NotificationState.unread,
      imageUrl: notification?.android?.imageUrl ?? data['image_url'] as String?,
      actionUrl: data['action_url'] as String?,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : null,
    );
  }

  /// Parse notification type from string
  NotificationType _parseNotificationType(String? type) {
    if (type == null) return NotificationType.system;
    
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => NotificationType.system,
      );
    } catch (_) {
      return NotificationType.system;
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(FashionNotification notification) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(notification.type),
      _getChannelName(notification.type),
      channelDescription: notification.message,
      importance: _getImportance(notification.type),
      priority: _getPriority(notification.type),
      icon: '@mipmap/ic_launcher',
      // Note: Image handling would require network image download
      // For production, implement image caching and use FilePathAndroidBitmap
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      details,
      payload: notification.actionUrl,
    );
  }

  /// Get channel ID for notification type
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.tryonCompleted:
      case NotificationType.outfitReady:
        return 'tryon_notifications';
      case NotificationType.eventReminder:
        return 'calendar_notifications';
      default:
        return 'system_notifications';
    }
  }

  /// Get channel name for notification type
  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.tryonCompleted:
      case NotificationType.outfitReady:
        return 'Try-On Updates';
      case NotificationType.eventReminder:
        return 'Calendar Reminders';
      default:
        return 'System Updates';
    }
  }

  /// Get importance for notification type
  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.tryonCompleted:
        return Importance.high;
      case NotificationType.eventReminder:
        return Importance.defaultImportance;
      default:
        return Importance.low;
    }
  }

  /// Get priority for notification type
  Priority _getPriority(NotificationType type) {
    switch (type) {
      case NotificationType.tryonCompleted:
        return Priority.high;
      case NotificationType.eventReminder:
        return Priority.defaultPriority;
      default:
        return Priority.low;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      // Handle deep link - will be processed when app is in foreground
      // For background/terminated, handled by _handleNotificationOpened
      debugPrint('🔗 Deep link: ${response.payload}');
      handleDeepLinkGlobal(response.payload);
    }
  }
  
  /// Handle deep link with global context (static for background handlers)
  static Future<void> handleDeepLinkGlobal(String? actionUrl) async {
    if (actionUrl == null) return;
    debugPrint('🔗 Processing deep link: $actionUrl');
    // Navigation will be handled when app context is available
    // This is called from background handlers where context may not be available
  }

  /// Set up token refresh listener
  void _setupTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _getFCMToken(); // Save new token
      debugPrint('🔄 FCM Token refreshed');
    });
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic: $e');
    }
  }

  /// Dispose
  void dispose() {
    _notificationStream?.close();
    _notificationStream = null;
  }
}
