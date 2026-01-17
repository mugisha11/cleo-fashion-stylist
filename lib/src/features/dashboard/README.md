# Fashion AI Assistant Dashboard

A production-ready, luxury fashion-grade dashboard UI/UX for a Fashion AI Assistant that recommends outfits, evaluates wardrobe items, and provides ChatGPT-style interactions.

## Features

### 🎨 Design System
- **Color Palette**: Deep Navy (#1B1D2E), Soft Lavender (#A29BFE), Aqua/Teal (#41D3BD), Muted Blush (#F6E9E9)
- **Typography**: Modern, geometric fonts with consistent spacing
- **Shadows & Effects**: Premium soft shadows and smooth animations

### 📱 Components

#### 1. **Left Sidebar Navigation** (Pi Network Style)
- 8 navigation tabs: Home, AI Stylist, My Wardrobe, Saved Outfits, 3D Avatar, Style Settings, Account & Profile, Support
- Animated active tab indicator
- Smooth hover effects
- Collapsible on tablet
- Bottom navigation on mobile

#### 2. **Top Bar**
- Search bar (desktop)
- Notifications with badge
- Settings button
- User profile with avatar

#### 3. **AI Chat Workspace** (ChatGPT Style)
- Conversational message bubbles
- User and AI message differentiation
- Image upload button
- Voice input support (optional)
- Quick action chips for common queries
- Loading states with shimmer effects
- Empty state with helpful prompts

#### 4. **Fashion Recommendations Panel** (Right Side)
- 3D Avatar preview area (ReadyPlayer Me integration ready)
- Outfit recommendation cards
- "Try on Avatar" button
- "Add to Wardrobe" and "Save Outfit" actions
- Magazine-like editorial layout
- Tag system for outfit categorization

### 📐 Responsive Design
- **Desktop**: Full three-panel layout (Sidebar + Chat + Recommendations)
- **Tablet**: Collapsed sidebar, stacked chat and recommendations
- **Mobile**: Bottom navigation, full-screen chat, recommendations in modal

### ✨ Animations
- Fade-in and slide animations for messages
- Smooth tab transitions
- Hover effects on interactive elements
- Loading shimmer skeletons
- Micro-interactions on buttons

## Usage

### Navigation
Navigate to the dashboard using:
```dart
Navigator.pushNamed(context, Routes.dashboard);
```

### Integration Points

#### 1. **AI Chat Backend**
Replace the mock `_handleSendMessage` in `dashboard_screen.dart` with your AI service:
```dart
void _handleSendMessage(String message) {
  // Call your AI service
  final aiResponse = await aiService.getResponse(message);
  // Update messages list
}
```

#### 2. **Wardrobe Database**
Connect to your wardrobe service:
```dart
void _handleAddToWardrobe(OutfitCard outfit) {
  wardrobeService.addItem(outfit);
}
```

#### 3. **3D Avatar (ReadyPlayer Me)**
Integrate ReadyPlayer Me widget in `fashion_recommendations_panel.dart`:
```dart
Widget _buildAvatarPreview(bool isMobile) {
  return ReadyPlayerMeWidget(
    // Your ReadyPlayer Me configuration
  );
}
```

#### 4. **Outfit Generator**
Connect to your outfit generation service:
```dart
Future<List<OutfitCard>> _generateOutfits() async {
  return await outfitService.generateOutfits(userPreferences);
}
```

## File Structure

```
lib/src/features/dashboard/
├── screens/
│   └── dashboard_screen.dart          # Main dashboard screen
├── widgets/
│   ├── dashboard_sidebar.dart         # Left sidebar navigation
│   ├── dashboard_topbar.dart          # Top bar with search & profile
│   ├── ai_chat_workspace.dart         # ChatGPT-style chat interface
│   └── fashion_recommendations_panel.dart  # Right panel with outfits
└── README.md                           # This file

lib/src/core/theme/
└── dashboard_design_system.dart        # Design system constants
```

## Customization

### Colors
Edit `lib/src/core/theme/dashboard_design_system.dart` to customize colors:
```dart
static const Color primaryNavy = Color(0xFF1B1D2E);
static const Color secondaryLavender = Color(0xFFA29BFE);
// ... etc
```

### Typography
Modify font styles in `dashboard_design_system.dart`:
```dart
static TextStyle headlineLarge({bool isMobile = false}) {
  return TextStyle(
    fontSize: isMobile ? 24 : 28,
    fontWeight: FontWeight.bold,
    // ... etc
  );
}
```

### Sidebar Items
Add or remove navigation items in `dashboard_sidebar.dart`:
```dart
final List<SidebarItem> _items = [
  SidebarItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
    index: 0,
  ),
  // Add more items...
];
```

## Next Steps

1. **Connect AI Backend**: Integrate your AI service for chat responses
2. **Wardrobe Integration**: Connect to wardrobe database
3. **3D Avatar**: Integrate ReadyPlayer Me widget
4. **Outfit Generation**: Connect outfit recommendation engine
5. **Image Upload**: Implement image picker and upload to Supabase
6. **Voice Input**: Add speech-to-text functionality
7. **Analytics**: Add user interaction tracking

## Dependencies

- `flutter_animate`: For smooth animations
- `google_fonts`: For typography
- `flutter_riverpod`: For state management (already in project)

## Notes

- All components are fully responsive
- Design follows luxury fashion aesthetic
- Code is production-ready and well-documented
- Ready for backend integration


