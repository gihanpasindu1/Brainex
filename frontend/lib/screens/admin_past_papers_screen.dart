import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:frontend/screens/admin_dashboard_screen.dart';
import 'package:frontend/screens/admin_users_screen.dart';
import 'package:frontend/screens/admin_notes_screen.dart';
import 'package:frontend/screens/admin_mcq_upload_screen.dart'; // Ensure correct import for upload screen

class AdminPastPapersScreen extends StatefulWidget {
  const AdminPastPapersScreen({super.key});

  @override
  State<AdminPastPapersScreen> createState() => _AdminPastPapersScreenState();
}

class _AdminPastPapersScreenState extends State<AdminPastPapersScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<dynamic> _allPapers = [];
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All' or 'Grade'

  @override
  void initState() {
    super.initState();
    _fetchPapers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPapers() async {
    setState(() => _isLoading = true);
    final fetched = await AdminService().getAllPapers();
    if (mounted) {
      setState(() {
        _allPapers = fetched;
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredPapers {
    List<dynamic> filtered = List.from(_allPapers);

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((paper) {
        final title = (paper['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by Grade if selected
    if (_selectedFilter == 'Grade') {
      filtered.sort((a, b) {
        final gA = a['grade']?.toString() ?? '';
        final gB = b['grade']?.toString() ?? '';
        return gB.compareTo(gA); // descending
      });
    }

    return filtered;
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Unknown date';
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPapers = _allPapers.length;
    
    // Count recently added papers (e.g. within last 7 days)
    final now = DateTime.now();
    int recentPapers = _allPapers.where((p) {
      final isoDate = p['created_at'];
      if (isoDate == null) return false;
      try {
        final dt = DateTime.parse(isoDate);
        return now.difference(dt).inDays <= 7;
      } catch (_) {
        return false;
      }
    }).length;

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
                          'Past Papers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage uploaded exam papers',
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
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Search papers...',
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
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Paper Items list dynamically populated
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: Color(0xFF4AC4F3)),
                            ),
                          )
                        else if (_filteredPapers.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No papers found.',
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ),
                          )
                        else
                          ..._filteredPapers.map((paper) {
                            final title = paper['title'] ?? 'Unknown Title';
                            final grade = paper['grade'] ?? 'Unknown Grade';
                            final type = paper['paper_type'] ?? 'Paper';
                            final dateStr = _formatDate(paper['created_at']);
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildPaperItem(
                                title,
                                'Grade $grade • $type',
                                'Uploaded $dateStr',
                              ),
                            );
                          }).toList(),

                        const SizedBox(height: 24),

                        // Upload New Paper Button
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
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              // Navigate to Upload screen and wait for return
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminMcqUploadScreen(),
                                ),
                              );
                              // Refresh papers after returning from upload screen
                              _fetchPapers();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Upload New Paper',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Paper Summary box
                        const Text(
                          'Paper Summary',
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
                                  const Text('Total Papers', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  Text('$totalPapers', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Recently Added (7 days)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  Text('$recentPapers', style: const TextStyle(color: Color(0xFF4AC4F3), fontSize: 16, fontWeight: FontWeight.bold)),
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
                        _buildNavItem(context, 'Notes', false),
                        _buildNavItem(context, 'Papers', true), // Papers selected
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF4AC4F3), Color(0xFFB55DFF)], // Cyan to Purple
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSelected ? null : const Color(0xFF1A1C36),
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildPaperItem(String title, String subtitle, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF4AC4F3), // Cyan color for upload date
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // We removed the static View/Edit buttons here to make the item cleaner,
          // or we can keep a simple icon if we want.
          const Icon(Icons.picture_as_pdf, color: Colors.white38, size: 28),
        ],
      ),
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
