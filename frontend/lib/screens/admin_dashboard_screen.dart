import 'package:flutter/material.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:frontend/screens/admin_past_papers_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Brainex dashboard',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                      onPressed: () async {
                        await AuthServices().signOut();
                      },
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
                        const Text(
                          'Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Overview Grid
                        FutureBuilder<Map<String, dynamic>?>(
                          future: AdminService().getAdminStats(),
                          builder: (context, snapshot) {
                            String users = '...';
                            String papers = '...';
                            String notes = '...';
                            String challenges = '...';

                            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                              users = snapshot.data!['users']?.toString() ?? '0';
                              papers = snapshot.data!['papers']?.toString() ?? '0';
                              notes = snapshot.data!['notes']?.toString() ?? '0';
                              challenges = snapshot.data!['challenges']?.toString() ?? '0';
                            }

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildMetricCard('Users', users)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildMetricCard('Papers', papers)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _buildMetricCard('Notes', notes)),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildMetricCard('Challenges', challenges)),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick Action Buttons
                        _buildPrimaryActionButton(
                          'Add Past Paper',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminPastPapersScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSecondaryActionButton('Add Note', null),
                        const SizedBox(height: 12),
                        _buildSecondaryActionButton('Manage Users', null),
                        const SizedBox(height: 12),
                        _buildSecondaryActionButton('MCQ Bank Upload', null),

                        const SizedBox(height: 32),

                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recent Activity Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('• SQL paper uploaded',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 12),
                              Text('• New short note added',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom Navigation Bar lookalike (as shown in design)
              Container(
                color: const Color(0xFF131427),
                child: SafeArea(
                  top: false,
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem('Dashboard', true),
                        _buildNavItem('Users', false),
                        _buildNavItem('Content', false),
                        _buildNavItem('Settings', false),
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

  Widget _buildMetricCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton(String title, VoidCallback? onTap) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4AC4F3), // Cyan
            Color(0xFFB55DFF), // Purple
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionButton(String title, VoidCallback? onTap) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C36), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, bool isSelected) {
    return Text(
      label,
      style: TextStyle(
        color: isSelected ? const Color(0xFF4AC4F3) : Colors.white54,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }
}
