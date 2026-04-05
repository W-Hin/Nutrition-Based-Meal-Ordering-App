import 'package:flutter/material.dart';

class PaymentFailedPage extends StatelessWidget {
  const PaymentFailedPage({super.key});

  static const _green      = Color(0xFF1E4620);
  static const _terracotta = Color(0xFFD95F2B);
  static const _bg         = Color(0xFFF5F5F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PAYMENT',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Failure icon ──
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade200, width: 2),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.red, size: 52),
            ),
            const SizedBox(height: 24),

            const Text(
              'Payment Failed',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong while processing your payment. Please try again or use a different payment method.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6B6B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // ── Try again ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _terracotta,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'TRY AGAIN',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Go home ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: const BorderSide(color: Color(0xFF1E4620), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'BACK TO HOME',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}