import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Decorative corners ──────────────────────────────
            Positioned(
              top: -20, left: -20,
              child: Transform.rotate(
                angle: -0.3,
                child: Opacity(
                  opacity: 0.85,
                  child: Image.asset('assets/images/cucumber.png', width: 150),
                ),
              ),
            ),
            Positioned(
              top: -5, right: -10,
              child: Transform.rotate(
                angle: 0.2,
                child: Opacity(
                  opacity: 0.85,
                  child: Image.asset('assets/images/fire.png', width: 130),
                ),
              ),
            ),
            Positioned(
              bottom: 50, left: -10,
              child: Transform.rotate(
                angle: 0.15,
                child: Opacity(
                  opacity: 0.85,
                  child: Image.asset('assets/images/fire.png', width: 110),
                ),
              ),
            ),
            Positioned(
              bottom: 30, right: -15,
              child: Transform.rotate(
                angle: 0.4,
                child: Opacity(
                  opacity: 0.85,
                  child: Image.asset('assets/images/cucumber.png', width: 145),
                ),
              ),
            ),

            // ── Main content ────────────────────────────────────
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Welcome text with shadow
                        const Text(
                          'Welcome!',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E4620),
                            shadows: [
                              Shadow(
                                color: Color(0x331E4620),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Logo
                        Image.asset(
                          'assets/images/NuBurnLogoWithWord.png',
                          width: size.width * 0.75,
                        ),
                        const SizedBox(height: 28),

                        // Multi-colored slogan matching prototype
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                              children: [
                                TextSpan(text: '🔥  '),
                                TextSpan(
                                  text: 'BURN OLD ME, ',
                                  style: TextStyle(color: Color(0xFFD95B2B)),
                                ),
                                TextSpan(
                                  text: 'BORN NEW ME.',
                                  style: TextStyle(color: Color(0xFF1E4620)),
                                ),
                                TextSpan(text: '  🔥'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 52),

                        // Get Started button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD95B2B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0xFFD95B2B).withValues(alpha: 0.45),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}