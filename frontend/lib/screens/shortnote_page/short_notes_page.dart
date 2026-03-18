import 'dart:ui';
import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:frontend/services/localization_service.dart';
=======
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:frontend/widgets/premium_bottom_nav.dart';
import 'package:frontend/screens/profile screen/profile_screen.dart';
import 'package:frontend/screens/ai_studyplan/ai_study_plan_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/models/short_note_model.dart';
import 'package:frontend/services/short_notes_service.dart';
>>>>>>> Stashed changes

class ShortNotesPage extends StatefulWidget {
  const ShortNotesPage({super.key});

  @override
  State<ShortNotesPage> createState() => _ShortNotesPageState();
}

class _ShortNotesPageState extends State<ShortNotesPage> {
  int selectedTab = 0; // 0 = My Notes, 1 = Predefined Notes
  int bottomIndex = 1; // default highlight like screenshot (Plan)

  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

<<<<<<< Updated upstream
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
=======
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  List<ShortNoteModel> myNotes = [];
  bool isLoadingNotes = true;
  bool isProcessingScan = false;

  final String userUid = FirebaseAuth.instance.currentUser?.uid ?? 'test_user_uid';
>>>>>>> Stashed changes

  // Dummy Data for Predefined Notes
  final List<Map<String, String>> predefinedNotes = [
    {
      "title": "Physics Formula Sheet",
      "desc": "A complete list of formulas for Mechanics, Waves, and Thermodynamics...",
      "date": "Updated: Sep 2023",
    },
    {
      "title": "Math Cheat Sheet",
      "desc": "Quick reference for Algebra, Trigonometry, and Calculus identities...",
      "date": "Updated: Aug 2023",
    },
    {
      "title": "Chemistry Periodic Table",
      "desc": "High definition periodic table with atomic properties and trends...",
      "date": "Updated: Jul 2023",
    },
    {
      "title": "English Grammar Rules",
      "desc": "Comprehensive grammar guide covering tenses, voice, and speech...",
      "date": "Updated: Jun 2023",
    },
  ];

  @override
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedTab);
    _loadMyNotes();
  }

  Future<void> _loadMyNotes() async {
    setState(() => isLoadingNotes = true);
    try {
      final notes = await ShortNotesService.getShortNotes(userUid);
      setState(() {
        myNotes = notes.reversed.toList(); // newest first
        isLoadingNotes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingNotes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load notes: $e")),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ShortNoteModel> get _filteredMyNotes {
    if (_searchQuery.isEmpty) return myNotes;
    return myNotes
        .where(
          (note) =>
              note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              note.desc.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, String>> get _filteredPredefinedNotes {
    if (_searchQuery.isEmpty) return predefinedNotes;
    return predefinedNotes
        .where(
          (note) =>
              note["title"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              note["desc"]!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

<<<<<<< Updated upstream
=======
  Future<void> _scanNote(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => isProcessingScan = true);

      // OCR
      final inputImage = InputImage.fromFile(File(image.path));
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedText = recognizedText.text;

      if (extractedText.isEmpty) {
        if (!mounted) return;
        setState(() => isProcessingScan = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No text detected in image.")));
        return;
      }

      // Gemini Processing
      final geminiData = await ShortNotesService.generateNoteWithGemini(extractedText);
      
      if (!mounted) return;
      setState(() => isProcessingScan = false);

      _showEditDialog(geminiData['title'] ?? 'Generated Note', geminiData['desc'] ?? '');

    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessingScan = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error scanning: $e")));
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
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                title: const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _scanNote(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
                title: const Text('Gallery', style: TextStyle(color: Colors.white)),
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

  void _showEditDialog(String initialTitle, String initialDesc) {
    final titleController = TextEditingController(text: initialTitle);
    final descController = TextEditingController(text: initialDesc);

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0B1326),
              title: const Text(
                "Finalize Note",
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Title",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2DE2E6))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: "Note Description",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2DE2E6))),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isSaving)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                  ),
                isSaving
                    ? const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF2DE2E6))),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB13CFF)),
                        onPressed: () async {
                          setDialogState(() => isSaving = true);
                          try {
                            final savedNote = await ShortNotesService.saveShortNote(
                              userUid,
                              titleController.text,
                              descController.text,
                            );

                            if (!mounted) return;
                            setState(() {
                              myNotes.insert(0, savedNote);
                            });
                            
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (!context.mounted) return;
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            }
                          }
                        },
                        child: const Text("Save", style: TextStyle(color: Colors.white)),
                      ),
              ],
            );
          }
        );
      },
    );
  }

>>>>>>> Stashed changes
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
                              onChanged: (val) => setState(() => _searchQuery = val),
                            ),
                            const SizedBox(height: 14),
<<<<<<< Updated upstream

                            _GradientActionButton(
                              icon: Icons.qr_code_scanner_rounded,
                              label: "Scan New Note",
                              onTap: () {},
                            ),
=======
                            isProcessingScan
                                ? Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B1326).withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(Color(0xFF2DE2E6)),
                                      ),
                                    ),
                                  )
                                : _GradientActionButton(
                                    icon: Icons.qr_code_scanner_rounded,
                                    label: "Scan New Note",
                                    onTap: _showImageSourceDialog,
                                  ),
>>>>>>> Stashed changes
                            const SizedBox(height: 14),
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (i) => setState(() => selectedTab = i),
                                children: [
                                  // Tab 0: My Notes
                                  isLoadingNotes
                                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF2DE2E6)))
                                      : _filteredMyNotes.isEmpty
                                          ? const Center(child: Text("No notes found.", style: TextStyle(color: Colors.white70)))
                                          : ListView.builder(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              itemCount: _filteredMyNotes.length,
                                              itemBuilder: (context, index) {
                                                final note = _filteredMyNotes[index];
                                                return Column(
                                                  children: [
                                                    _NoteCard(
                                                      title: note.title,
                                                      desc: note.desc,
                                                      dateText: note.date,
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
                                      final note = _filteredPredefinedNotes[index];
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
      bottomNavigationBar: _BottomNav(
        currentIndex: bottomIndex,
        onChanged: (i) => setState(() => bottomIndex = i),
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
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.5),
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
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            maxLines: 4,
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

/* ------------------------------ BOTTOM NAV ---------------------------- */

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _BottomNav({required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    String t(String key) => tr?.translate(key) ?? key;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: t('nav_home'),
                  active: currentIndex == 0,
                  onTap: () {
                    onChanged(0);
                    Navigator.maybePop(context);
                  },
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: t('nav_plan'),
                  active: currentIndex == 1,
                  onTap: () => onChanged(1),
                ),
                _NavItem(
                  icon: Icons.emoji_events_rounded,
                  label: t('nav_leaderboard'),
                  active: currentIndex == 2,
                  onTap: () => onChanged(2),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: t('nav_profile'),
                  active: currentIndex == 3,
                  onTap: () => onChanged(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: active
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withValues(alpha: 0.9),
                    Colors.purpleAccent.withValues(alpha: 0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.22),
                    blurRadius: 16,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? Colors.white : Colors.white60),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: active ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
