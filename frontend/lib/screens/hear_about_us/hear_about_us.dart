import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/screens/root_screen.dart';
import 'package:frontend/screens/admin_dashboard_screen.dart';
import 'package:frontend/services/user_profile_service.dart';

class HearAboutUs extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  const HearAboutUs({super.key, required this.onboardingData});

  @override
  State<HearAboutUs> createState() => _HearAboutUsPageState();
}

class _HearAboutUsPageState extends State<HearAboutUs> {
  String selected = "";
  bool _isLoading = false;
  final UserProfileService _profileService = UserProfileService();

  Future<void> _submitOnboarding() async {
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final finalData = Map<String, dynamic>.from(widget.onboardingData);
    finalData['hear_about_us'] = selected;

    final success = await _profileService.completeOnboarding(user.uid, finalData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (user.uid == '2zJK3J7TClQ7Sk6uTKMqHgOwpsu2') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => RootScreen(userId: user.uid)),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000428), Color(0xFF004e92)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "How did you hear about us?",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                _radio("Friend / Classmate"),
                _radio("Teacher / School"),
                _radio("Social Media"),
                _radio("YouTube"),
                _radio("Google Search"),
                _radio("Other"),

                const Spacer(),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Finish Setup", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _radio(String title) {
    return RadioListTile<String>(
      value: title,
      groupValue: selected,
      onChanged: (value) {
        setState(() => selected = value.toString());
      },
      title: Text(title, style: const TextStyle(color: Colors.white)),
      activeColor: Colors.cyanAccent,
    );
  }
}
