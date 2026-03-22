import 'dart:io';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/models/short_note_model.dart';
import 'package:frontend/services/short_notes_service.dart';

class ShortNotesPage extends StatefulWidget {
  const ShortNotesPage({super.key});

  @override
  State<ShortNotesPage> createState() => _ShortNotesPageState();
}

class _ShortNotesPageState extends State<ShortNotesPage> {
  int selectedTab = 0; // 0 = My Notes, 1 = Predefined Notes

  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  String _searchQuery = "";
  List<ShortNoteModel> myNotes = [];
  bool isLoadingNotes = true;
  bool isProcessingScan = false;

  final String userUid =
      FirebaseAuth.instance.currentUser?.uid ?? 'test_user_uid';

  List<Map<String, String>> predefinedNotes = [];
  bool isLoadingPredefined = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedTab);
    _loadMyNotes();
    _loadPredefinedNotes();
  }

  Future<void> _loadPredefinedNotes() async {
    setState(() => isLoadingPredefined = true);
    try {
      final notes = await ShortNotesService.getPredefinedNotes();
      if (!mounted) return;
      setState(() {
        predefinedNotes = notes;
        isLoadingPredefined = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingPredefined = false);
    }
  }

  Future<void> _loadMyNotes() async {
    setState(() => isLoadingNotes = true);
    try {
      final notes = await ShortNotesService.getShortNotes(userUid);
      if (!mounted) return;
      setState(() {
        myNotes = notes.reversed.toList();
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
    _textRecognizer.close();
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

      setState(() => isProcessingScan = true);

      final inputImage = InputImage.fromFile(File(image.path));
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedText = recognizedText.text.trim();

      if (extractedText.isEmpty) {
        if (!mounted) return;
        setState(() => isProcessingScan = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No text detected in image.")),
        );
        return;
      }

      final geminiData =
          await ShortNotesService.generateNoteWithGemini(extractedText);

      if (!mounted) return;
      setState(() => isProcessingScan = false);

      _showEditDialog(
        geminiData['title'] ?? 'Generated Note',
        geminiData['desc'] ?? '',
        geminiData['content'] ?? '',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessingScan = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error scanning: $e")));
    }
  }

  Future<void> _deleteNote(ShortNoteModel note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1326),
        title: const Text('Delete Note', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this short note?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ShortNotesService.deleteShortNote(userUid, note.id);
      if (!mounted) return;
      setState(() {
        myNotes.removeWhere((n) => n.id == note.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting note: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1326),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
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
                  Navigator.pop(sheetContext);
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
                  Navigator.pop(sheetContext);
                  _scanNote(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(String initialTitle, String initialDesc, String initialContent) {
    final titleController = TextEditingController(text: initialTitle);
    final descController = TextEditingController(text: initialDesc);
    final contentController = TextEditingController(text: initialContent);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2DE2E6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Short Description",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2DE2E6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: "Notes Content (Point-wise Markdown)",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2DE2E6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isSaving)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                isSaving
                    ? const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF2DE2E6),
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB13CFF),
                        ),
                        onPressed: () async {
                          setDialogState(() => isSaving = true);
                          try {
                            final savedNote =
                                await ShortNotesService.saveShortNote(
                                  userUid,
                                  titleController.text.trim(),
                                  descController.text.trim(),
                                  contentController.text.trim(),
                                );

                            if (!mounted) return;
                            setState(() {
                              myNotes.insert(0, savedNote);
                            });

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          }
                        },
                        child: const Text(
                          "Save",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ],
            );
          },
        );
      },
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

                            if (selectedTab == 0) ...[
                              isProcessingScan
                                  ? Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF0B1326,
                                        ).withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF2DE2E6),
                                        ),
                                      ),
                                    )
                                  : _GradientActionButton(
                                      icon: Icons.qr_code_scanner_rounded,
                                      label: "Scan New Note",
                                      onTap: _showImageSourceDialog,
                                    ),
                              const SizedBox(height: 14),
                            ],

                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (i) =>
                                    setState(() => selectedTab = i),
                                children: [
                                  // Tab 0: My Notes
                                  isLoadingNotes
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF2DE2E6),
                                          ),
                                        )
                                      : _filteredMyNotes.isEmpty
                                      ? const Center(
                                          child: Text(
                                            "No notes found.",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          itemCount: _filteredMyNotes.length,
                                          itemBuilder: (context, index) {
                                            final note =
                                                _filteredMyNotes[index];
                                            return Column(
                                              children: [
                                                _NoteCard(
                                                  title: note.title,
                                                  desc: note.desc,
                                                  content: note.content,
                                                  dateText: note.date,
                                                  onDelete: () => _deleteNote(note),
                                                ),
                                                const SizedBox(height: 12),
                                              ],
                                            );
                                          },
                                        ),
                                  // Tab 1: Predefined Notes
                                  isLoadingPredefined
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF2DE2E6),
                                          ),
                                        )
                                      : _filteredPredefinedNotes.isEmpty
                                          ? const Center(
                                              child: Text(
                                                "No predefined notes found.",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              itemCount: _filteredPredefinedNotes.length,
                                              itemBuilder: (context, index) {
                                                final note = _filteredPredefinedNotes[index];
                                                return Column(
                                                  children: [
                                                    _NoteCard(
                                                      title: note["title"]!,
                                                      desc: note["desc"]!,
                                                      content: note["content"] ?? "",
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

class _NoteCard extends StatefulWidget {
  final String title;
  final String desc;
  final String content;
  final String dateText;
  final VoidCallback? onDelete;

  const _NoteCard({
    required this.title,
    required this.desc,
    this.content = "",
    required this.dateText,
    this.onDelete,
  });

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1326).withValues(alpha: _isExpanded ? 0.35 : 0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: _isExpanded ? 0.25 : 0.1)),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: _isExpanded ? const Color(0xFF2DE2E6) : Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.desc.isNotEmpty && widget.content.isNotEmpty)
                          Text(
                            widget.desc,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        if (widget.desc.isNotEmpty && widget.content.isNotEmpty)
                          const SizedBox(height: 12),
                        MarkdownBody(
                          data: widget.content.isNotEmpty ? widget.content : widget.desc,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.5),
                            h1: const TextStyle(color: Color(0xFF2DE2E6), fontSize: 18, fontWeight: FontWeight.bold),
                            h2: const TextStyle(color: Color(0xFF2DE2E6), fontSize: 16, fontWeight: FontWeight.bold),
                            h3: const TextStyle(color: Color(0xFF2DE2E6), fontSize: 15, fontWeight: FontWeight.bold),
                            listBullet: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      widget.desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.dateText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    if (widget.onDelete != null)
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        ),
                      ),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
