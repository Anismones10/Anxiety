import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../book_info.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/geometric_pattern.dart';
import 'home_screen.dart';

/// Short start screen (about 2 seconds). Tap to skip.
class SplashScreen extends StatefulWidget {
  final AppState app;

  const SplashScreen({super.key, required this.app});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2400), _goHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goHome() {
    if (_left || !mounted) return; // go only once
    _left = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            HomeScreen(app: widget.app),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goHome,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A5490), Color(0xFF0D3A6B), Color(0xFF062445)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Stack(
            children: [
              // Very light geometric pattern over the whole screen.
              const Positioned.fill(
                child: GeometricPattern(color: Color(0x0FFFFFFF), tile: 64),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      FadeSlideIn(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 64,
                          color: Color(0xFFC9A961),
                        ),
                      ),
                      SizedBox(height: 24),
                      FadeSlideIn(
                        delay: Duration(milliseconds: 250),
                        child: Text(
                          bookTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.7,
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      FadeSlideIn(
                        delay: Duration(milliseconds: 550),
                        child: Text(
                          researcherLine,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFC9A961),
                            height: 1.9,
                          ),
                        ),
                      ),
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
}
