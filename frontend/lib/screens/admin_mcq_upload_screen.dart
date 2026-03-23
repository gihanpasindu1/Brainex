import 'package:flutter/material.dart';

class AdminMcqUploadScreen extends StatefulWidget {
  const AdminMcqUploadScreen({super.key});

  @override
  State<AdminMcqUploadScreen> createState() => _AdminMcqUploadScreenState();
}

class _AdminMcqUploadScreenState extends State<AdminMcqUploadScreen> {
  bool _skipDuplicates = false;

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
                          'MCQ Bank Upload',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Upload JSON file to mcq_bank',
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
                        // Upload JSON File Box
                        _buildSectionTitle('Upload JSON File'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C36),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: const [
                              Text(
                                'Choose File',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'mcq_bank_term1.json',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Validation Result Box
                        _buildSectionTitle('Validation Result'),
                        const SizedBox(height: 12),
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
                            children: const [
                              Text('Total Questions: 120', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 10),
                              Text('Valid Questions: 116', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 10),
                              Text('Invalid Questions: 4', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 10),
                              Text('Duplicate Questions: 3', style: TextStyle(color: Color(0xFF4AC4F3), fontSize: 13)), // Cyan color
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Error Preview Box
                        _buildSectionTitle('Error Preview'),
                        const SizedBox(height: 12),
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
                            children: const [
                              Text('• Question 15: missing answer', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 10),
                              Text('• Question 27: missing options', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 10),
                              Text('• Question 40: duplicate question', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 10),
                              Text('• Question 52: wrong answer key', style: TextStyle(color: Color(0xFF4AC4F3), fontSize: 13)), // Cyan color
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sample Preview Box
                        _buildSectionTitle('Sample Preview'),
                        const SizedBox(height: 12),
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
                            children: const [
                              Text('Topic: Logic Gates', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 16),
                              Text(
                                'Question: What is the output of a NAND gate\nwhen inputs are 1 and 1?',
                                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                              ),
                              SizedBox(height: 16),
                              Text('A. 0 B. 1 C. Both D. None', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 16),
                              Text('Answer: A', style: TextStyle(color: Color(0xFF4AC4F3), fontSize: 13)), // Cyan color
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Skip Duplicates Checkbox
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _skipDuplicates = !_skipDuplicates;
                                });
                              },
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _skipDuplicates ? const Color(0xFF4AC4F3) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _skipDuplicates ? const Color(0xFF4AC4F3) : Colors.white54,
                                  ),
                                ),
                                child: _skipDuplicates
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Skip duplicates',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Bottom Actions
                        Row(
                          children: [
                            _buildActionButton('Cancel', Colors.transparent, Colors.white12, Colors.white),
                            const SizedBox(width: 12),
                            _buildActionButton('Validate', Colors.transparent, Colors.white12, Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGradientButton('Import'),
                            ),
                          ],
                        ),
                        // Add some extra space at the bottom just in case
                        const SizedBox(height: 20),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActionButton(String label, Color bgColor, Color borderColor, Color textColor) {
    return Expanded(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
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
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String label) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4AC4F3), Color(0xFFB55DFF)], // Cyan to Outline
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
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
