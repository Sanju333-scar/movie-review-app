import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_application_7/screens/auth/landing_page.dart';
import 'package:flutter_application_7/screens/reset_password_screen.dart';

/// Global navigator key to allow navigation from anywhere (even before build)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  /// Initialize deep link handling (cinirev://reset-password?token=XYZ)
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // ✅ Handle cold start (app opened via deep link)
    try {
      final Uri? initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint("❌ Error getting initial deep link: $e");
    }

    // ✅ Handle links when app is already open
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleUri(uri);
    }, onError: (err) {
      debugPrint("❌ Deep link stream error: $err");
    });
  }

  /// Handles deep link navigation safely using navigatorKey
  void _handleUri(Uri uri) {
    debugPrint("📩 Deep link received: $uri");

    if (uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        // ✅ Use navigatorKey instead of context
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: token),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ add this
      title: 'CineRev',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}
