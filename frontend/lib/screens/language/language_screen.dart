import 'package:flutter/material.dart';
import 'package:frontend/providers/locale_provider.dart';
import 'package:frontend/screens/authentication/authenticate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  Future<void> _onLanguageSelected(String code) async {
    debugPrint("Language selected: $code");

    // Use the provider to set the locale
    Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(code));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Authenticate()),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkSavedLanguage();
  }

  Future<void> _checkSavedLanguage() async {
    // The provider handles basic loading, but if we need to skip this screen:
    final prefs = await SharedPreferences.getInstance();
    // Check the key used by LocaleProvider ('language_code'), NOT 'selected_language'
    final saved = prefs.getString('language_code');

    if (saved != null && saved.isNotEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Authenticate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1026), Color(0xFF060A1F), Color(0xFF050818)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // 🔹 Top Logo Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1C1B5E), Color(0xFF120E3F)],
                    ),
                  ),
                  child: Row(
                    children: [
                      // 🔹 LOGO CONTAINER (FIXED)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF6C63FF),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/brainex_logo.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Text(
                        "BraineX",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // 🔹 Title
                const Text(
                  "Choose your language",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Select a language to continue",
                  style: TextStyle(fontSize: 14, color: Colors.white60),
                ),

                const SizedBox(height: 30),

                // ✅ Language Cards with ripple effect (InkWell)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _onLanguageSelected("en"),
                    child: languageTile(
                      leading: "EN",
                      title: "English",
                      subtitle: "Continue in English",
                      isActive: true,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _onLanguageSelected("si"),
                    child: languageTile(
                      leading: "සි",
                      title: "Sinhala",
                      subtitle: "ඉදිරියට යන්න",
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _onLanguageSelected("ta"),
                    child: languageTile(
                      leading: "த",
                      title: "Tamil",
                      subtitle: "தமிழில் தொடருங்கள்",
                    ),
                  ),
                ),

                const Spacer(),

                // 🔹 Footer
                const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Center(
                    child: Text(
                      "You can change language later in Settings",
                      style: TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Language Tile Widget
  Widget languageTile({
    required String leading,
    required String title,
    required String subtitle,
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1E6D), Color(0xFF0F123F)],
        ),
        border: Border.all(
          color: const Color(0xFF4F6BFF).withValues(alpha: 0.1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6C63FF), width: 1.4),
            ),
            child: Text(
              leading,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right, color: Colors.white70, size: 26),
        ],
      ),
    );
  }
}
