import 'package:flutter/material.dart';

import 'profile.dart';
import 'setting.dart';
import 'playing_field.dart';
import 'rating.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  static const Color burgundy = Color(0xFF6B1F2B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
/// ФОН
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_window.jpeg',
              fit: BoxFit.cover,
            ),
          ),

/// MAHJONG
          const Positioned(
            left: 91,
            top: 260,
            child: Text(
              'MAHJONG',
              style: TextStyle(
                fontSize: 40,
                fontFamily: 'Aboreto',
                color: burgundy,
              ),
            ),
          ),

/// КНОПКА LEVEL
          Positioned(
            left: 17,
            top: 401,
            child: GestureDetector(
              onTap: () {
              	Navigator.push(
                  	context,
                  	MaterialPageRoute(
                    	builder: (context) => const PlayingFieldScreen(),
                  	),
                	);
	},
              child: Container(
                width: 360,
                height: 60,
                decoration: BoxDecoration(
                  color: burgundy.withOpacity(0.62),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'LEVEL ...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    letterSpacing: 1.5,
                    fontFamily: 'Aboreto',
                  ),
                ),
              ),
            ),
          ),

/// КНОПКА RATING
          Positioned(
            left: 50,
            top: 783,
            child: GestureDetector(
              onTap: () {
              	Navigator.push(
                  	context,
                  	MaterialPageRoute(
                    	builder: (context) => const RatingScreen(),
                  	),
                	);
	},
              child: Container(
                width: 300,
                height: 45,
                decoration: BoxDecoration(
                  color: burgundy.withOpacity(0.62),
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'RATING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    letterSpacing: 1.5,
                    fontFamily: 'Aboreto',
                  ),
                ),
              ),
            ),
          ),

///КНОПКА PROFILE
          Positioned(
            left: 17,
            top: 43,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/profile.JPEG'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x66454545),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x33FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

///КНОПКА SETTINGS
          Positioned(
            left: 307,
            top: 44,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingScreen(),
                  ),
                );
              },
              child: SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/setting.PNG'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x66454545),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x33FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
