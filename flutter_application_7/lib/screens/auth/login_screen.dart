import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_7/config.dart';
import 'package:flutter_application_7/screens/cine_rev.dart';
import 'package:google_sign_in/google_sign_in.dart';




class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId:
      "495284894003-8rfrgebd2cl27k2pdn4m5o5i3cm533rm.apps.googleusercontent.com",
  scopes: ['email', 'profile'],
);

Future<void> loginWithGoogle() async {
  try {
    final GoogleSignInAccount? account =
        await _googleSignIn.signIn();

    if (account == null) {
      print("User cancelled login");
      return;
    }

    final GoogleSignInAuthentication auth =
        await account.authentication;

    final accessToken = auth.accessToken;

    print("========== GOOGLE TOKENS ==========");
    print("Access Token: $accessToken");
    print("ID Token: ${auth.idToken}");
    print("===================================");

    if (accessToken == null) {
      print("Access token is null");
      return;
    }

    // 🔥 SEND ACCESS TOKEN TO BACKEND
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "access_token": accessToken
      }),
    );

    print("Backend Status: ${response.statusCode}");
    print("Backend Body: ${response.body}");

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
      print("Google login failed: ${response.body}");
    }

  } catch (e) {
    print("Google login error: $e");
  }
}
  // ✅ NORMAL LOGIN
  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        await prefs.setInt('user_id', data['user_id']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CineRev()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${response.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                const SizedBox(height: 60),
                const Icon(Icons.movie_outlined,
                    color: Colors.greenAccent, size: 64),

                const SizedBox(height: 20),
                const Text(
                  "Welcome back!",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Email",
                    filled: true,
                    fillColor: const Color(0xFF2C2F33),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2C2F33),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginUser,
                    child: const Text("Continue"),
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ FIXED GOOGLE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : loginWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text("Sign in with Google"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
