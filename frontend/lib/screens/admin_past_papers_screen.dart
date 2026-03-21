import 'package:flutter/material.dart';

class AdminPastPapersScreen extends StatelessWidget {
  const AdminPastPapersScreen({super.key});

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
                          child: const TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search papers...',
                              hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Filter Pills
                        Row(
                          children: [
                            _buildFilterPill('All', true),
                            const SizedBox(width: 12),
                            _buildFilterPill('Grade', false),
                            const SizedBox(width: 12),
                            _buildFilterPill('Subject', false),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Paper Items list
                        _buildPaperItem(
                          'ICT 2023 Term Test',
                          'Grade 13 • Paper • PDF',
                          'Uploaded 2 days ago',
                        ),
                        const SizedBox(height: 12),
                        _buildPaperItem(
                          'Maths 2022 Model Paper',
                          'Grade 12 • Paper • PDF',
                          'Uploaded 5 days ago',
                        ),
                        const SizedBox(height: 12),
                        _buildPaperItem(
                          'Science 2021 Final Exam',
                          'Grade 11 • Paper • PDF',
                          'Uploaded 1 week ago',
                        ),

                        const SizedBox(height: 24),

                        // Upload New Paper Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4AC4F3), Color(0xFFB55DFF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                              Text('Total Papers: 542', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              SizedBox(height: 12),
                              Text('Recently Added: 18', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                        _buildNavItem('Dashboard', false),
                        _buildNavItem('Users', false),
                        _buildNavItem('Papers', true), // Papers selected
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

  Widget _buildFilterPill(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF4AC4F3), Color(0xFFB55DFF)], // Cyan to Outline
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
          Column(
            children: [
              _buildSmallButton('View'),
              const SizedBox(height: 8),
              _buildSmallButton('Edit'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(String label) {
    return Container(
      width: 60,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF222544),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
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
