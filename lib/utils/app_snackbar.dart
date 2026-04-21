import 'package:flutter/material.dart';
import 'dart:async';

class AppSnackBar {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(BuildContext context, String message, {bool isError = false}) {
    // 1. Cancel previous notification instantly
    _timer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Overlay.of(context);
    final Color bgColor = isError ? const Color(0xFFD32F2F) : const Color(0xFF1E4620);
    final topPadding = MediaQuery.of(context).padding.top;

    // 2. Create the floating notification layer
    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 60,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    // 3. Insert into the overlay
    overlayState.insert(_currentEntry!);

    // 4. Auto-dismiss after 2 seconds
    _timer = Timer(const Duration(seconds: 2), () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }
}
