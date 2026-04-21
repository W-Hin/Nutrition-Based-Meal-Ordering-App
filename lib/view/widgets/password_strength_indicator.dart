import 'package:flutter/material.dart';
import '../../utils/password_validator.dart';

/// A live password strength bar + checklist.
/// Place directly below the password field and pass the current value.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  static const _grey   = Color(0xFFDDDDDD);
  static const _dark   = Color(0xFF2D2D2D);

  const PasswordStrengthIndicator({super.key, required this.password});

  Color _barColor(int score) {
    switch (score) {
      case 1: return Colors.red.shade500;
      case 2: return Colors.orange.shade400;
      case 3: return Colors.amber.shade500;
      case 4: return const Color(0xFF4CAF50);
      case 5: return const Color(0xFF1E4620);
      default: return _grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final score  = passwordStrength(password);
    final label  = strengthLabel(score);
    final color  = _barColor(score);
    // 5 segments: fill up to `score` of them
    const total  = 5;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Strength bar ─────────────────────────────────────
            Row(
              children: List.generate(total, (i) {
                final filled = i < score;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                    height: 5,
                    decoration: BoxDecoration(
                      color:        filled ? color : _grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            // ── Label ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Password strength',
                  style: TextStyle(
                    fontSize: 11,
                    color:    _dark.withValues(alpha: 0.4),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    label,
                    key:   ValueKey(label),
                    style: TextStyle(
                      fontSize:   11,
                      color:      color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Requirements checklist ────────────────────────────
            ...passwordRequirements.map((req) {
              final met = req.test(password);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width:  16,
                      height: 16,
                      decoration: BoxDecoration(
                        color:  met ? color : Colors.transparent,
                        border: Border.all(
                          color: met ? color : _grey,
                          width: 1.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: met
                          ? const Icon(Icons.check,
                              size: 10, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      req.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: met
                            ? color
                            : _dark.withValues(alpha: 0.45),
                        fontWeight:
                            met ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
