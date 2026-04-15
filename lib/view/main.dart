import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../controller/cart_controller.dart';
import '../controller/order_controller.dart';
import '../controller/menu_controller.dart';
import '../controller/bowl_controller.dart';
import 'widgets/navigation_bar.dart';
import '../view/pages/cart.dart';
import '../view/pages/menu_page.dart';

import '../controller/store_controller.dart';

void main() {
  runApp(
    // ChangeNotifierProvider makes Controllers available to the whole app
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => FoodMenuController()), 
        ChangeNotifierProvider(create: (_) => BowlController()),
        ChangeNotifierProvider(create: (_) => StoreController()),
      ],
      child: const MyApp(),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E4620)),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Home Page')),
    const MenuPage(), // Explore Page
    const Center(child: Text('Order Page')),
    const Center(child: Text('Profile Page')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Page content ──
          IndexedStack(index: _selectedIndex, children: _pages),

          // ── Floating cart button (top-right) ──
          Positioned(
            top: 48,
            right: 16,
            child: _CartFab(),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// ── Cart FAB — green circle with badge ────────────────────────────────────────

class _CartFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CartController>(
      builder: (context, cart, _) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartPage()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Green circle
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFF285430),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              // Red badge — only shows when cart has items
              if (cart.totalItemCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFBF5D32),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      // Cap display at 99, show 99+ beyond that
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
    );
  }
}