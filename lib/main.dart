// Updated Main.dart with Enhanced Navigation System
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// Import providers
import 'providers/auth_provider.dart';
import 'providers/favourites_provider.dart';
import 'controllers/navigation_controller.dart';

// Import services
import 'services/auth_service.dart';

// Import screens
import 'screens/login_screen.dart';
import 'widgets/splash_screen.dart';
import 'screens/enhanced_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print("🚀 Starting Crave Food App with Enhanced Navigation...");
  
  try {
    // Load environment variables
    print("📄 Loading environment variables...");
    await dotenv.load(fileName: ".env");
    print("✅ Environment variables loaded");
  } catch (e) {
    print("⚠️ Error loading .env file: $e");
    print("💡 Make sure .env file exists in project root");
  }
  
  try {
    // Initialize Firebase
    print("🔥 Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
    // Continue anyway - app can still work for UI testing
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FavouritesProvider()),
        
        // NEW: Navigation provider for gesture management
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'Crave Food',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        // Add navigation shortcuts for desktop/web
        builder: (context, child) {
          return NavigationShortcuts(child: child ?? const SizedBox());
        },
      ),
    );
  }

  // Modern Light Theme for Food App
  ThemeData _buildLightTheme() {
    const primaryColor = Color(0xFFFF6B35); // Vibrant orange-red
    const secondaryColor = Color(0xFFFFB627); // Golden yellow
    const accentColor = Color(0xFF4ECDC4); // Teal
    const surfaceColor = Color(0xFFFAFAFA); // Light grey
    const errorColor = Color(0xFFE74C3C); // Red

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A1A1A),
        onError: Colors.white,
        outline: Color(0xFFE0E0E0),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF808080), fontSize: 14),
        labelStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF808080),
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 24),
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }

  // Modern Dark Theme for Food App
  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFFFF6B35); // Vibrant orange-red
    const secondaryColor = Color(0xFFFFB627); // Golden yellow
    const accentColor = Color(0xFF4ECDC4); // Teal
    const surfaceColor = Color(0xFF1E1E1E); // Dark grey
    const errorColor = Color(0xFFE74C3C); // Red

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFE0E0E0),
        onError: Colors.white,
        outline: Color(0xFF404040),
      ),

      // App Bar Theme for Dark Mode
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),

      // Card Theme for Dark Mode
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Elevated Button Theme for Dark Mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme for Dark Mode
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          color: Color(0xFF808080),
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom Navigation Bar Theme for Dark Mode
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF808080),
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 24),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),

      // Chip Theme for Dark Mode
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF2A2A2A),
        selectedColor: primaryColor,
        secondarySelectedColor: secondaryColor,
        labelStyle: TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Divider Theme for Dark Mode
      dividerTheme: const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 1,
        space: 16,
      ),

      // Icon Theme for Dark Mode
      iconTheme: const IconThemeData(
        color: Color(0xFFB0B0B0),
        size: 24,
      ),

      // Primary Icon Theme for Dark Mode
      primaryIconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
    );
  }
}

// Auth Wrapper with Enhanced Navigation Integration
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const SplashScreen();
        }
        
        if (authProvider.user != null) {
          // Use the enhanced home screen with IndexedStack navigation
          return const EnhancedHomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}

// Performance Monitor Widget (Debug Mode Only)
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  
  const PerformanceMonitor({super.key, required this.child});

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  @override
  void initState() {
    super.initState();
    
    // Only enable performance monitoring in debug mode
    assert(() {
      _startPerformanceMonitoring();
      return true;
    }());
  }

  void _startPerformanceMonitoring() {
    // Monitor frame rendering performance
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final frameTime = timing.totalSpan.inMilliseconds;
        if (frameTime > 16) { // 60 FPS = 16.67ms per frame
          debugPrint('⚠️ Slow frame detected: ${frameTime}ms');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// App Lifecycle Manager
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> 
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed');
        // Restore navigation state if needed
        _restoreNavigationState();
        break;
      case AppLifecycleState.paused:
        debugPrint('📱 App paused');
        // Save navigation state
        _saveNavigationState();
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App detached');
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('📱 App hidden');
        break;
    }
  }

  void _saveNavigationState() {
    try {
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      NavigationStatePersistence.saveNavigationState(navProvider.selectedIndex);
    } catch (e) {
      debugPrint('Error saving navigation state: $e');
    }
  }

  void _restoreNavigationState() {
    try {
      final persistedIndex = NavigationStatePersistence.getPersistedIndex();
      if (persistedIndex != null) {
        final navProvider = Provider.of<NavigationProvider>(context, listen: false);
        navProvider.setSelectedIndex(persistedIndex);
      }
    } catch (e) {
      debugPrint('Error restoring navigation state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Error Boundary for Navigation
class NavigationErrorBoundary extends StatefulWidget {
  final Widget child;
  
  const NavigationErrorBoundary({super.key, required this.child});

  @override
  State<NavigationErrorBoundary> createState() => _NavigationErrorBoundaryState();
}

class _NavigationErrorBoundaryState extends State<NavigationErrorBoundary> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Navigation Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _resetError,
                child: const Text('Reset App'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }

  void _resetError() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    
    // Reset navigation state
    try {
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      navProvider.setSelectedIndex(0);
    } catch (e) {
      debugPrint('Error resetting navigation: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Listen for navigation errors
    FlutterError.onError = (details) {
      if (details.toString().contains('navigation') || 
          details.toString().contains('gesture')) {
        setState(() {
          _hasError = true;
          _errorMessage = 'A navigation error occurred. Please restart the app.';
        });
      }
    };
  }
}