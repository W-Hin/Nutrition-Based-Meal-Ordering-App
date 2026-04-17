import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Decorative corners ──────────────────────────────
            // Top-left cucumber
            Positioned(
              top: -10,
              left: -10,
              child: Transform.rotate(
                angle: -0.3,
                child: Opacity(
                  opacity: 0.75,
                  child: Image.asset(
                    'assets/images/cucumber.png',
                    width: 110,
                  ),
                ),
              ),
            ),
            // Top-right fire
            Positioned(
              top: 0,
              right: -5,
              child: Transform.rotate(
                angle: 0.2,
                child: Opacity(
                  opacity: 0.75,
                  child: Image.asset(
                    'assets/images/fire.png',
                    width: 90,
                  ),
                ),
              ),
            ),
            // Bottom-left fire
            Positioned(
              bottom: 60,
              left: -5,
              child: Transform.rotate(
                angle: 0.15,
                child: Opacity(
                  opacity: 0.75,
                  child: Image.asset(
                    'assets/images/fire.png',
                    width: 80,
                  ),
                ),
              ),
            ),
            // Bottom-right cucumber
            Positioned(
              bottom: 40,
              right: -10,
              child: Transform.rotate(
                angle: 0.4,
                child: Opacity(
                  opacity: 0.75,
                  child: Image.asset(
                    'assets/images/cucumber.png',
                    width: 100,
                  ),
                ),
              ),
            ),

            // ── Main content ────────────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome text
                    const Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E4620), // Dark green
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Logo
                    Image.asset(
                      'assets/images/NuBurnLogoWithWord.png',
                      width: size.width * 0.55,
                    ),
                    const SizedBox(height: 24),

                    // Tagline
                    const Text(
                      'BURN OLD ME, BORN NEW ME.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: Color(0xFFD95B2B), // Orange tagline
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD95B2B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}