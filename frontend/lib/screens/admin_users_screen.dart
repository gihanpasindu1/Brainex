import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:frontend/screens/admin_dashboard_screen.dart';
import 'package:frontend/screens/admin_notes_screen.dart';
import 'package:frontend/screens/admin_past_papers_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<dynamic> _allUsers = [];
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Active', 'Blocked'

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await AdminService().getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBlockStatus(String userId, bool currentStatus) async {
    final success = await AdminService().updateUserStatus(userId, !currentStatus);
    if (success) {
      // Refresh the list to reflect changes
      _fetchUsers();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user status')),
        );
      }
    }
  }

  List<dynamic> get _filteredUsers {
    List<dynamic> filtered = _allUsers;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final email = (user['email'] ?? '').toString().toLowerCase();
        return email.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Role/Status filter
    if (_selectedFilter == 'Active') {
      filtered = filtered.where((user) => user['is_blocked'] != true).toList();
    } else if (_selectedFilter == 'Blocked') {
      filtered = filtered.where((user) => user['is_blocked'] == true).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    int totalUsers = _allUsers.length;
    int blockedUsers = _allUsers.where((u) => u['is_blocked'] == true).length;
    int activeUsers = totalUsers - blockedUsers;

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
                          'Users',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage student accounts',
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
                              hintText: 'Search user email...',
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
                              onTap: () => setState(() => _selectedFilter = 'Active'),
                              child: _buildFilterPill('Active', _selectedFilter == 'Active'),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                               onTap: () => setState(() => _selectedFilter = 'Blocked'),
                               child: _buildFilterPill('Blocked', _selectedFilter == 'Blocked'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // User Items list
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: Color(0xFF4AC4F3)),
                            ),
                          )
                        else if (_filteredUsers.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No users found matching filters.',
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ),
                          )
                        else
                          ..._filteredUsers.map((user) {
                            final email = user['email']?.toString() ?? 'Unknown User';
                            final name = email.split('@').first;
                            final isBlocked = user['is_blocked'] == true;
                            final totalXp = user['total_xp']?.toString() ?? '0';
                            final userId = user['user_id']?.toString() ?? '';
                            final avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildUserItem(
                                userId: userId,
                                name: name,
                                status: '$totalXp XP • ${isBlocked ? "Blocked" : "Active"}',
                                avatarLetter: avatarLetter,
                                isBlocked: isBlocked,
                              ),
                            );
                          }).toList(),

                        const SizedBox(height: 24),

                        // User Summary box
                        const Text(
                          'User Summary',
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
                                  const Text('Total Users', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  Text('$totalUsers', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Active Users', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  Text('$activeUsers', style: const TextStyle(color: Color(0xFF4AC4F3), fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Blocked Users', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  Text('$blockedUsers', style: const TextStyle(color: Color(0xFFB55DFF), fontSize: 16, fontWeight: FontWeight.bold)),
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
                        _buildNavItem(context, 'Users', true), // Users selected
                        _buildNavItem(context, 'Notes', false),
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

  Widget _buildUserItem({
    required String userId,
    required String name,
    required String status,
    required String avatarLetter,
    required bool isBlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF4AC4F3), Color(0xFFB55DFF)], // Cyan to Purple
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: isBlocked ? const Color(0xFFB55DFF) : const Color(0xFF4AC4F3),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  _toggleBlockStatus(userId, isBlocked);
                },
                child: _buildSmallButton(isBlocked ? 'Unblock' : 'Block', isAccent: isBlocked),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(String label, {bool isAccent = false}) {
    return Container(
      width: 72,
      height: 30,
      decoration: BoxDecoration(
        color: isAccent ? const Color(0xFFB55DFF).withOpacity(0.1) : const Color(0xFF222544),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isAccent ? const Color(0xFFB55DFF).withOpacity(0.5) : Colors.white12),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isAccent ? const Color(0xFFB55DFF) : Colors.white70,
            fontSize: 12,
            fontWeight: isAccent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
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
