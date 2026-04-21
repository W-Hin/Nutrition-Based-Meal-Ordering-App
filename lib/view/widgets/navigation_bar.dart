import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/cart_controller.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onCartTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onCartTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Increased height from 70 to 115+ to ensure the floating cart button
    // (at bottom: 50 with height 65) is within the tappable bounds.
    return SizedBox(
      height: 115,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Bottom bar background ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              color: const Color(0xFF1E4620),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Left side: Home + Explore
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          icon: Icons.home,
                          label: 'Home',
                          isSelected: selectedIndex == 0,
                          onTap: () => onItemTapped(0),
                        ),
                        _NavItem(
                          icon: Icons.explore,
                          label: 'Explore',
                          isSelected: selectedIndex == 1,
                          onTap: () => onItemTapped(1),
                        ),
                      ],
                    ),
                  ),

                  // Center gap for the floating cart button
                  const SizedBox(width: 72),

                  // Right side: Order + Profile
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          icon: Icons.assignment,
                          label: 'Order',
                          isSelected: selectedIndex == 2,
                          onTap: () => onItemTapped(2),
                        ),
                        _NavItem(
                          icon: Icons.person,
                          label: 'Profile',
                          isSelected: selectedIndex == 3,
                          onTap: () => onItemTapped(3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Floating Cart Button ───────────────────────────────────────
          Positioned(
            bottom: 50,
            child: Consumer<CartController>(
              builder: (context, cart, _) {
                return GestureDetector(
                  onTap: onCartTapped,
                  behavior: HitTestBehavior.opaque, // Ensures the entire area is tappable
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A5C2E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      if (cart.totalItemCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFCC4E2A),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            child: Text(
                              cart.totalItemCount > 99
                                  ? '99+'
                                  : '${cart.totalItemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFFB5CC30);
    final Color inactiveColor = Colors.white;
    final Color itemColor = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                color: itemColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: itemColor,
                fontSize: 12,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
