import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// controllers
import 'package:nutrition_based_meal_ordering_app/controller/cart_controller.dart';
import 'package:nutrition_based_meal_ordering_app/controller/order_controller.dart';
import 'package:nutrition_based_meal_ordering_app/controller/menu_controller.dart';
import 'package:nutrition_based_meal_ordering_app/controller/bowl_controller.dart';
import 'package:nutrition_based_meal_ordering_app/controller/store_controller.dart';
import 'package:nutrition_based_meal_ordering_app/controller/auth_controller.dart';
import 'package:nutrition_based_meal_ordering_app/controller/onboarding_controller.dart';
import 'package:nutrition_based_meal_ordering_app/controller/profile_controller.dart';
import 'package:nutrition_based_meal_ordering_app/controller/review_controller.dart';

// pages
import 'package:nutrition_based_meal_ordering_app/view/pages/welcome_page.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/login_page.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/register_page.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/terms_page.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/dashboard_page.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/profile_page.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/onboarding/onboarding_personal_page.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/onboarding/onboarding_bmi_page.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/onboarding/onboarding_address_page.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/cart.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/menu_page.dart';
import 'package:nutrition_based_meal_ordering_app/view/pages/my_orders.dart';
import 'package:nutrition_based_meal_ordering_app/view/widgets/navigation_bar.dart';
import 'package:nutrition_based_meal_ordering_app/view/admin/admin_shell.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cjsxgpiahswppkyackpk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqc3hncGlhaHN3cHBreWFja3BrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwOTE0MDksImV4cCI6MjA5MTY2NzQwOX0.E_2q_i5PqmuY2Csx06e7U0In-DAoLak_n_KC-IgKOkc',
  );

  Stripe.publishableKey = 'pk_test_51TMrO1AwDwRCAOhEWqQejM3jhLwBpAKuGgKkBgtajtvXzu0vLshRm0FJxs2Mt7B5sCP9oXue0VOVNtUzHOQcbw5W00crERJXIQ';
  await Stripe.instance.applySettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => StoreController()),
        ChangeNotifierProxyProvider<StoreController, FoodMenuController>(
          create: (_) => FoodMenuController(),
          update: (context, storeController, foodMenuController) {
            final controller = foodMenuController ?? FoodMenuController();
            final storeId = storeController.selectedStore?.id;
            if (storeId != null) {
              controller.fetchMeals(storeId: storeId);
            }
            return controller;
          },
        ),
        ChangeNotifierProvider(create: (_) => BowlController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => OnboardingController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => ReviewController()),
      ],
      child: const MyApp(),
    ),
  );
}

// allow mouse and trackpad scrolling
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

// root app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'NuBurn',
    scrollBehavior: AppScrollBehavior(),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E4620)),
      fontFamily: 'Roboto',
    ),
    home: const AuthWrapper(),
    routes: {
      '/auth':              (_) => const AuthWrapper(),
      '/login':             (_) => const LoginPage(),
      '/register':          (_) => const RegisterPage(),
      '/terms':             (_) => const TermsPage(),
      '/onboarding':        (_) => const OnboardingPersonalPage(),
      '/onboarding/bmi':    (_) => const OnboardingBmiPage(),
      '/onboarding/address':(_) => const OnboardingAddressPage(),
      '/home':              (_) => const MainShell(),
    },
  );
  }
}

// auth wrapper - check session and route user accordingly
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const WelcomePage();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _resolveDestination(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            if (snap.hasError || snap.data == null) {
              return const WelcomePage();
            }

            final role       = snap.data!['role'] as String? ?? 'user';
            final hasProfile = snap.data!['hasProfile'] as bool? ?? false;

            if (role == 'admin') {
              return const AdminShell();
            }
            if (!hasProfile) {
              return const OnboardingPersonalPage();
            }
            return const MainShell();
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _resolveDestination() async {
    final ctrl = context.read<AuthController>();
    final role       = await ctrl.getUserRole() ?? 'user';
    final hasProfile = await ctrl.hasProfile();
    return {'role': role, 'hasProfile': hasProfile};
  }
}

// loading screen
class _LoadingScreen extends StatelessWidget {
  static const _cream  = Color(0xFFF5F0E8);
  static const _orange = Color(0xFFD95B2B);
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _cream,
      body: Center(
        child: CircularProgressIndicator(color: _orange),
      ),
    );
  }
}

// main shell - bottom nav for customer
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final _tabNotifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeDashboardPage(),
      MenuPage(onBack: () => setState(() => _selectedIndex = 0)),
      MyOrdersPage(tabNotifier: _tabNotifier),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() => _selectedIndex = index);
          _tabNotifier.value = index;
          // Reload dashboard when returning to Home tab
          if (index == 0) {
            context.read<ProfileController>().loadDashboardData();
          }
        },
        onCartTapped: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartPage()),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartController>().loadCart();
    });
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }
}


