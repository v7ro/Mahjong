import 'package:flutter/material.dart';

class RatingScreen extends StatelessWidget {
  const RatingScreen({super.key});
  static const Color black = Color(0xFF454545);
  static const Color burgundy = Color(0xFF6B1F2B);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: burgundy),
        title: const Text(
          'Rating',
          style: TextStyle(
            fontFamily: 'Aboreto',
            fontSize: 38,
            color: burgundy,
          ),
        ),
      ),
///ФОН
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/rating.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
