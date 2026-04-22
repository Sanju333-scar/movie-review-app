import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../services/tmdb_service.dart';
import '../../models/tmdb_movie_model.dart';
import '../../config.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'package:flutter_application_7/screens/cine_rev.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TMDBService _tmdbService = TMDBService();
  List<TMDBMovie> _movies = [];
  bool _loading = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? "495284894003-8rfrgebd2cl27k2pdn4m5o5i3cm533rm.apps.googleusercontent.com"
        : null,
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    try {
      final data = await _tmdbService.getPopularMovies();
      setState(() {
        _movies = data.take(8).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching movies: $e");
      setState(() => _loading = false);
    }
  }

  // ================= GOOGLE LOGIN =================

  Future<void> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;

      String? token;
      Map<String, dynamic> body;

      if (kIsWeb) {
        token = auth.accessToken;
        body = {"access_token": token};
      } else {
        token = auth.idToken;
        body = {"id_token": token};
      }

      if (token == null) {
        print("Google token is null");
        return;
      }

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("Google Backend Status: ${response.statusCode}");
      print("Google Backend Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        await prefs.setInt('user_id', data['user_id']);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CineRev()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google login failed")),
        );
      }
    } catch (e) {
      print("Google login error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Colors.greenAccent))
          : Stack(
              children: [
                // 🎞 Carousel
                cs.CarouselSlider.builder(
                  itemCount: _movies.length,
                  options: cs.CarouselOptions(
                    height: double.infinity,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    autoPlayInterval:
                        const Duration(seconds: 4),
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
                  ),
                  itemBuilder: (context, index, _) {
                    final movie = _movies[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          movie.posterUrl ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey[900]),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black87
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 160,
                          left: 20,
                          right: 20,
                          child: Text(
                            movie.title ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // 🔽 Buttons Section
                Positioned(
                  bottom: 60,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      // Log In
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.greenAccent[700],
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const LoginScreen()),
                            );
                          },
                          child: const Text(
                            "Log In",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Sign Up
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.white70),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const SignupScreen()),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Google Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          icon: Image.asset(
                            "assets/google_logo.png",
                            height: 20,
                          ),
                          label: const Text(
                            "Continue with Google",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.white70),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          onPressed: loginWithGoogle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}