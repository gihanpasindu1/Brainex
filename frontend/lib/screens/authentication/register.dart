import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:frontend/screens/wrapper.dart';
import 'package:frontend/services/auth.dart';
// 1. Import your localization service
import 'package:frontend/services/localization_service.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _isObscured = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  final AuthServices _auth = AuthServices();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    final tr = AppLocalizations.of(context);
    String t(String key) => tr?.translate(key) ?? key;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t("error_email_password"))));
      return;
    }

    setState(() => _loading = true);

    // Call Firebase Registration
    dynamic result = await _auth.registerWithEmailPassword(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t("error_register_failed"))));
    } else {
      // Success -> Navigate to Home (via Wrapper or directly)
      // Since Wrapper listens to auth changes, we can just pop users or pushAndRemoveUntil
      // pushAndRemoveUntil is safer to clear back stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Wrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. Initialize Localization helper
    final tr = AppLocalizations.of(context);
    String t(String key) => tr?.translate(key) ?? key;

    return Scaffold(
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
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t("register_title"), // "Create Account"
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t("register_subtitle"), // "Join Brainex Today"
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 35),

                  _label(t("email_label")),
                  _inputField(t("email_hint"), _emailController),
                  const SizedBox(height: 20),

                  _label(t("password_label")),
                  _passwordField(t("register_pass_hint"), _passwordController),
                  const SizedBox(height: 30),

                  _gradientButton(t("btn_signup"), _handleSignUp),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      t("already_have_acc"), // "Already have an account?"
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Pops back to Login Page
                      Navigator.pop(context);
                    },
                    child: Text(
                      t("link_login"), // "Login"
                      style: const TextStyle(color: Color(0xFF21CBF3)),
                    ),
                  ),

                  const Divider(color: Colors.white24),
                  const SizedBox(height: 20),

                  _socialButton(
                    t("signup_google"),
                    "assets/images/icons8-google-100.png",
                    () {},
                  ),
                  const SizedBox(height: 10),
                  _socialButton(
                    t("signup_apple"),
                    "assets/images/apple-512.png",
                    () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

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
      keyboardType: TextInputType.emailAddress,
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
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
            Image.asset(
              icon,
              height: 22,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image, color: Colors.white),
            ),
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

// Ensure GlassCard is defined here or imported
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
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
