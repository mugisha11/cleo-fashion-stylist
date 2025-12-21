import 'package:flutter/material.dart';
import 'premium_mobile_header.dart';

/// Example implementation showing PremiumMobileHeader usage
class PremiumHeaderExample extends StatefulWidget {
  const PremiumHeaderExample({super.key});

  @override
  State<PremiumHeaderExample> createState() => _PremiumHeaderExampleState();
}

class _PremiumHeaderExampleState extends State<PremiumHeaderExample> {
  bool _isDarkMode = false;
  int _notificationCount = 3;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        appBar: PremiumMobileHeader(
          appTitle: 'Cleo Fashion',
          screenTitle: 'Dashboard',
          showSearchIcon: false,
          notificationCount: _notificationCount,
          avatarUrl: null,
          isDarkMode: _isDarkMode,
          onNotificationTap: () {
            setState(() => _notificationCount = 0);
          },
          onAvatarTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile tapped')),
            );
          },
          onSearchTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search tapped')),
            );
          },
          onAppTitleTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App title tapped')),
            );
          },
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 20,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Item ${index + 1}',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
          child: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
        ),
      ),
    );
  }
}

