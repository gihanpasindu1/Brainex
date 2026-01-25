import 'package:flutter/material.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/screens/wrapper.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscured = true;
  final _auth = AuthServices();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password required")),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await _auth.signInWithEmailPassword(email, password);

    setState(() => _loading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Check email/password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The main background image remains the same
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            // The GlassCard handles the transparent container
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Welcome to Brainex",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "A/L ICT Exam Helper",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 35),

                  _label("Email"),
                  _inputField("Enter your email", _emailController),
                  const SizedBox(height: 20),

                  _label("Password"),

                  _passwordField("Enter your password", _passwordController),

                  const SizedBox(height: 30),

                  _gradientButton("Login", _handleLogin),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      print("Navigate to Register");
                    },
                    child: const Text(
                      "Create an Account!",
                      style: TextStyle(color: Color(0xFF21CBF3)),
                    ),
                  ),

                  const Divider(color: Colors.white24),
                  const SizedBox(height: 20),

                  _socialButton(
                    "Continue with Google",
                    "assets/images/icons8-google-100.png",
                    () {
                      print("Google Button Clicked");
                    },
                  ),

                  const SizedBox(height: 10),

                  _socialButton(
                    "Continue with Apple",
                    "assets/images/apple-512.png",
                    () {
                      print("Apple Button Clicked");
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _passwordField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: _isObscured,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
          ),
          onPressed: () => setState(() => _isObscured = !_isObscured),
        ),
      ),
    );
  }

  Widget _gradientButton(String text, VoidCallback onPressed) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF21CBF3), Color(0xFF9242F6)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _socialButton(String text, String icon, VoidCallback onPressed) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, height: 22),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      filled: true,
      fillColor: const Color(0xFF14141E).withOpacity(0.6),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white38, width: 1.2),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 1.2),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        // --- MAIN CHANGE HERE ---
        // Changed opacity from 0.85 to 0.3.
        // Lower number = more transparent.
        color: const Color(0xFF1E1E2C).withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
        // Added a slight blur effect for realism (optional)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      // Adding a Blur filter for real glass effect
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(padding: const EdgeInsets.all(10), child: child),
        ),
      ),
    );
  }
}
