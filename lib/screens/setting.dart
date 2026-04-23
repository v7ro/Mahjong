import 'dart:ui';
import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  static const Color black = Color(0xFF454545);
  static const Color burgundy = Color(0xFF6B1F2B);

  bool isMusicOn = true;
  bool isSoundOn = true;

///ЯЗЫК
  String selectedLanguage = 'English';

  void _openLanguageMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: burgundy.withOpacity(0.62),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LANGUAGE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Aboreto',
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                title: const Text(
                  'English',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Aboreto'),
                ),
                trailing: selectedLanguage == 'English'
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
                onTap: () {
                  setState(() {
                    selectedLanguage = 'English';
                  });
                  Navigator.pop(context);
                },
              ),

              ListTile(
                title: const Text(
                  'Russian',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Aboreto'),
                ),
                trailing: selectedLanguage == 'Russian'
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
                onTap: () {
                  setState(() {
                    selectedLanguage = 'Russian';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

///SETTINGS
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: burgundy),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Aboreto',
            fontSize: 40,
            color: burgundy,
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          ),
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/backgrounds/setting_bg.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),

/// LANGUAGE
          Positioned(
            left: 32,
            top: 233,
            child: GestureDetector(
              onTap: _openLanguageMenu,
              child: Container(
                width: 320,
                height: 60,
                decoration: BoxDecoration(
                  color: black.withOpacity(0.36),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'LANGUAGE',
                  style: TextStyle(
                    color: burgundy,
                    fontSize: 32,
                    letterSpacing: 1.5,
                    fontFamily: 'Aboreto',
                  ),
                ),
              ),
            ),
          ),

/// MUSIC
          Positioned(
            left: 32,
            top: 341,
            child: Container(
              width: 320,
              height: 60,
              decoration: BoxDecoration(
                color: black.withOpacity(0.36),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'MUSIC',
                    style: TextStyle(
                      color: burgundy,
                      fontSize: 32,
                      letterSpacing: 1.5,
                      fontFamily: 'Aboreto',
                    ),
                  ),

                  Positioned(
                    right: 10,
                    child: Switch(
                      value: isMusicOn,
                      activeColor: burgundy,
                      inactiveTrackColor: black.withOpacity(0.1),
                      onChanged: (value) {
                        setState(() {
                          isMusicOn = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

/// SOUNDS 
          Positioned(
            left: 32,
            top: 450,
            child: Container(
              width: 320,
              height: 60,
              decoration: BoxDecoration(
                color: black.withOpacity(0.36),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'SOUNDS',
                    style: TextStyle(
                      color: burgundy,
                      fontSize: 32,
                      letterSpacing: 1.5,
                      fontFamily: 'Aboreto',
                    ),
                  ),

                  Positioned(
                    right: 10,
                    child: Switch(
                      value: isSoundOn,
                      activeColor: burgundy,
                      inactiveTrackColor: black.withOpacity(0.1),
                      onChanged: (value) {
                        setState(() {
                          isSoundOn = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

/// ABOUT US
          Positioned(
            left: 32,
            top: 559,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 320,
                height: 60,
                decoration: BoxDecoration(
                  color: black.withOpacity(0.36),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'ABOUT US',
                  style: TextStyle(
                    color: burgundy,
                    fontSize: 32,
                    letterSpacing: 1.5,
                    fontFamily: 'Aboreto',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
