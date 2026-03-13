import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:frontend/widgets/premium_bottom_nav.dart';
import 'package:frontend/screens/profile screen/profile_screen.dart';
import 'package:frontend/screens/ai_studyplan/ai_study_plan_2.dart';

class ShortNotesPage extends StatefulWidget {
  const ShortNotesPage({super.key});

  @override
  State<ShortNotesPage> createState() => _ShortNotesPageState();
}

class _ShortNotesPageState extends State<ShortNotesPage> {
  int selectedTab = 0; // 0 = My Notes, 1 = Predefined Notes
  int bottomIndex = -1; // -1 = nothing highlighted

  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Dummy Data for My Notes
  final List<Map<String, String>> myNotes = [
    {
      "title": "Chapter 3: Thermodynamics",
      "desc":
          "Thermodynamics deals with heat, work and energy transfer in physical systems...",
      "date": "Oct 12, 2023",
    },
    {
      "title": "Calculus II: Integration",
      "desc":
          "Integration is the reverse process of differentiation, finding area under curves and accumulation...",
      "date": "Oct 10, 2023",
    },
    {
      "title": "Organic Chemistry Reactions",
      "desc":
          "Organic reactions describe how molecules combine, rearrange and transform into new compounds...",
      "date": "Oct 9, 2023",
    },
  ];

  // Dummy Data for Predefined Notes
  final List<Map<String, String>> predefinedNotes = [
    {
      "title": "Physics Formula Sheet",
      "desc":
          "A complete list of formulas for Mechanics, Waves, and Thermodynamics...",
      "date": "Updated: Sep 2023",
    },
    {
      "title": "Math Cheat Sheet",
      "desc":
          "Quick reference for Algebra, Trigonometry, and Calculus identities...",
      "date": "Updated: Aug 2023",
    },
    {
      "title": "Chemistry Periodic Table",
      "desc":
          "High definition periodic table with atomic properties and trends...",
      "date": "Updated: Jul 2023",
    },
    {
      "title": "English Grammar Rules",
      "desc":
          "Comprehensive grammar guide covering tenses, voice, and speech...",
      "date": "Updated: Jun 2023",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedTab);
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredMyNotes {
    if (_searchQuery.isEmpty) return myNotes;
    return myNotes
        .where(
          (note) =>
              note["title"]!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              note["desc"]!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, String>> get _filteredPredefinedNotes {
    if (_searchQuery.isEmpty) return predefinedNotes;
    return predefinedNotes
        .where(
          (note) =>
              note["title"]!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              note["desc"]!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<void> _scanNote(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);

      if (image == null) return;

      final inputImage = InputImage.fromFile(File(image.path));
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      final extractedText = recognizedText.text;

      if (extractedText.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No text detected.")));
        return;
      }

      _showEditDialog(extractedText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error scanning: $e")));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1326),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _scanNote(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _scanNote(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(String text) {
    final controller = TextEditingController(text: text);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Scanned Note"),
        content: TextField(controller: controller, maxLines: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                myNotes.insert(0, {
                  "title": "Scanned Note",
                  "desc": controller.text,
                  "date": DateTime.now().toString().split(' ')[0],
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // soft dark overlay / shapes
              Positioned(
                right: -120,
                top: 120,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(140),
                  ),
                ),
              ),

              Column(
                children: [
                  _TopHeader(
                    title: "Short Notes",
                    subtitle: "Brainex Short Notes Library",
                    onBack: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _GlassPanel(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Column(
                          children: [
                            _SegmentedTabs(
                              leftText: "My Notes",
                              rightText: "Predefined Notes",
                              selectedIndex: selectedTab,
                              onChanged: (i) {
                                setState(() => selectedTab = i);
                                _pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            _SearchBar(
                              controller: _searchController,
                              hint: "Search notes by topic or keyword",
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                            ),
                            const SizedBox(height: 14),

                            _GradientActionButton(
                              icon: Icons.qr_code_scanner_rounded,
                              label: "Scan New Note",
                              onTap: _showImageSourceDialog,
                            ),
                            const SizedBox(height: 14),

                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (i) =>
                                    setState(() => selectedTab = i),
                                children: [
                                  // Tab 0: My Notes
                                  ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    itemCount: _filteredMyNotes.length,
                                    itemBuilder: (context, index) {
                                      final note = _filteredMyNotes[index];
                                      return Column(
                                        children: [
                                          _NoteCard(
                                            title: note["title"]!,
                                            desc: note["desc"]!,
                                            dateText: note["date"]!,
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      );
                                    },
                                  ),
                                  // Tab 1: Predefined Notes
                                  ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    itemCount: _filteredPredefinedNotes.length,
                                    itemBuilder: (context, index) {
                                      final note =
                                          _filteredPredefinedNotes[index];
                                      return Column(
                                        children: [
                                          _NoteCard(
                                            title: note["title"]!,
                                            desc: note["desc"]!,
                                            dateText: note["date"]!,
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: bottomIndex,
        onTap: (index) {
          setState(() => bottomIndex = index);
          if (index == 0) {
            Navigator.maybePop(context);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIStudyPlanPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }
}

/* ----------------------------- TOP HEADER ----------------------------- */

class _TopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _TopHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- GLASS PANEL ---------------------------- */

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1222).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ---------------------------- SEGMENTED TABS --------------------------- */

class _SegmentedTabs extends StatelessWidget {
  final String leftText;
  final String rightText;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.leftText,
    required this.rightText,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1326).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabPill(
              text: leftText,
              selected: selectedIndex == 0,
              gradient: const LinearGradient(
                colors: [Color(0xFF2DE2E6), Color(0xFFB13CFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _TabPill(
              text: rightText,
              selected: selectedIndex == 1,
              gradient: const LinearGradient(
                colors: [Color(0xFF2DE2E6), Color(0xFFB13CFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String text;
  final bool selected;
  final Gradient gradient;
  final VoidCallback onTap;

  const _TabPill({
    required this.text,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? gradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ SEARCH BAR ---------------------------- */

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  const _SearchBar({
    required this.hint,
    required this.onChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF071024).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2DE2E6), Color(0xFFB13CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------- GRADIENT ACTION BTN ------------------------ */

class _GradientActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GradientActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2DE2E6), Color(0xFFB13CFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------- NOTE CARD --------------------------- */

class _NoteCard extends StatelessWidget {
  final String title;
  final String desc;
  final String dateText;

  const _NoteCard({
    required this.title,
    required this.desc,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1326).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dateText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
