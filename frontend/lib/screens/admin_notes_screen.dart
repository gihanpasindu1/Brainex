import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:frontend/screens/admin_dashboard_screen.dart';
import 'package:frontend/screens/admin_users_screen.dart';
import 'package:frontend/screens/admin_past_papers_screen.dart';

class AdminNotesScreen extends StatefulWidget {
  const AdminNotesScreen({super.key});

  @override
  State<AdminNotesScreen> createState() => _AdminNotesScreenState();
}

class _AdminNotesScreenState extends State<AdminNotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // "All" or "Grade"
  
  bool _isLoading = true;
  List<dynamic> _allNotes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final notes = await AdminService().getAllShortNotes();
      if (mounted) {
        setState(() {
          _allNotes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredNotes {
    List<dynamic> filtered = _allNotes;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) {
        final title = (note['title'] ?? '').toString().toLowerCase();
        final desc = (note['desc'] ?? '').toString().toLowerCase();
        final content = (note['content'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery.toLowerCase()) || 
               desc.contains(_searchQuery.toLowerCase()) ||
               content.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by Grade toggle
    if (_selectedFilter == 'Grade') {
      filtered = filtered.where((note) {
        final desc = (note['desc'] ?? '').toString().toLowerCase();
        final title = (note['title'] ?? '').toString().toLowerCase();
        return desc.contains('grade') || title.contains('grade');
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    int recentlyUpdated = 0;
    try {
      final now = DateTime.now();
      recentlyUpdated = _allNotes.where((note) {
        final dateStr = note['date']?.toString();
        if (dateStr == null) return false;
        try {
          final date = DateFormat('MMM dd, yyyy').parse(dateStr);
          return now.difference(date).inDays <= 7;
        } catch (_) {
           return false;
        }
      }).length;
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFF0F1123),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A4EFE), // Blue/Purple gradient top
              Color(0xFF0F1123), // Dark blue/black bottom
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Segment
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 20.0, top: 20.0, bottom: 20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Short Notes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage study notes',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF131427), // Dark background for the main card area
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C36),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Search dynamic notes...',
                              hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: Colors.white54, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Filter Pills
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _selectedFilter = 'All'),
                              child: _buildFilterPill('All', _selectedFilter == 'All'),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => setState(() => _selectedFilter = 'Grade'),
                              child: _buildFilterPill('Grade', _selectedFilter == 'Grade'),
                            ),
                            // Removed "Subject" filter pill here
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Note Items list
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: Color(0xFF4AC4F3)),
                            ),
                          )
                        else if (_filteredNotes.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No notes generated yet or matching search.',
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ),
                          )
                        else
                          ..._filteredNotes.map((note) {
                            final title = note['title']?.toString() ?? 'Untitled Note';
                            final desc = note['desc']?.toString() ?? '';
                            final date = note['date']?.toString() ?? 'Recent';
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildDynamicNoteItem(
                                title: title,
                                subtitle: desc,
                                date: 'Uploaded: $date',
                                noteData: note,
                              ),
                            );
                          }).toList(),

                        const SizedBox(height: 12),

                        // Add New Note Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4AC4F3), Color(0xFFB55DFF)], // Cyan to Purple
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4AC4F3).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Add New Note',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Notes Summary box
                        const Text(
                          'Notes Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C36),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Notes In DB', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  Text('${_allNotes.length}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Recently Updated', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  Text('$recentlyUpdated', style: const TextStyle(color: Color(0xFF4AC4F3), fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Navigation Bar
              Container(
                color: const Color(0xFF131427),
                child: SafeArea(
                  top: false,
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C36),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(context, 'Dashboard', false),
                        _buildNavItem(context, 'Users', false),
                        _buildNavItem(context, 'Notes', true), // Notes selected
                        _buildNavItem(context, 'Papers', false),
                        _buildNavItem(context, 'Settings', false),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF4AC4F3), Color(0xFFB55DFF)], // Cyan to Purple
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSelected ? null : const Color(0xFF1A1C36),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isSelected ? Colors.transparent : Colors.white12),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDynamicNoteItem({
    required String title,
    required String subtitle,
    required String date,
    required Map<String, dynamic> noteData,
  }) {
    // Elegant JSON presentation formatting
    return GestureDetector(
      onTap: () => _showNoteDetails(context, title, subtitle, date, noteData),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C36),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222544),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF4AC4F3), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle.isNotEmpty ? subtitle : 'No description provided',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4AC4F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF4AC4F3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDetails(BuildContext context, String title, String subtitle, String date, Map<String, dynamic> noteData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF131427),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: noteData['content']?.toString() ?? 'No content available.',
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.5),
                        h1: const TextStyle(color: Color(0xFF4AC4F3), fontSize: 18, fontWeight: FontWeight.bold),
                        h2: const TextStyle(color: Color(0xFF4AC4F3), fontSize: 16, fontWeight: FontWeight.bold),
                        h3: const TextStyle(color: Color(0xFF4AC4F3), fontSize: 15, fontWeight: FontWeight.bold),
                        listBullet: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        if (label == 'Dashboard') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
        } else if (label == 'Users') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
        } else if (label == 'Notes') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminNotesScreen()));
        } else if (label == 'Papers') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPastPapersScreen()));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.transparent, // expand tap area
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4AC4F3) : Colors.white54,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String take(int length) {
    if (this.length <= length) return this;
    return substring(0, length);
  }
}
