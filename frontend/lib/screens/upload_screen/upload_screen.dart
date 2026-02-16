import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:permission_handler/permission_handler.dart';

class UploadPaperScreen extends StatefulWidget {
  const UploadPaperScreen({super.key});

  @override
  State<UploadPaperScreen> createState() => _UploadPaperScreenState();
}

class _UploadPaperScreenState extends State<UploadPaperScreen> {
  File? selectedFile;
  String? fileName;
  int? fileSize;

  final ImagePicker _picker = ImagePicker();

  // 📷 Camera
  Future<void> pickFromCamera() async {
    var status = await Permission.camera.request();

    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          selectedFile = File(image.path);
          fileName = image.name;
          fileSize = selectedFile!.lengthSync();
        });
      }
    }
  }

  // 🖼 Gallery
  Future<void> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedFile = File(image.path);
        fileName = image.name;
        fileSize = selectedFile!.lengthSync();
      });
    }
  }

  // 📄 PDF / File Picker
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        fileName = result.files.single.name;
        fileSize = result.files.single.size;
      });
    }
  }

  void removeFile() {
    setState(() {
      selectedFile = null;
      fileName = null;
      fileSize = null;
    });
  }

  String formatSize(int size) {
    double kb = size / 1024;
    return "${kb.toStringAsFixed(1)} KB";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔙 Back
              const Icon(Icons.arrow_back, color: Colors.white),

              const SizedBox(height: 20),

              // 🟣 Title
              const Text(
                "Upload Paper and Correct your MCQs",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Scan your answers and get instant marking + weak topic update",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 30),

              // 📄 Upload Box
              DottedBorder(
                color: Colors.white30,
                borderType: BorderType.RRect,
                radius: const Radius.circular(20),
                dashPattern: const [6, 4],
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF1B1B2E),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        size: 50,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Drop PDF / Image here",
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Supports JPG, PNG, PDF • Max 10MB",
                        style: TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 20),

                      // Choose File Button
                      GestureDetector(
                        onTap: pickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4FACFE), Color(0xFF8E2DE2)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            "Choose File",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 📷 Camera + Gallery Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: pickFromCamera,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Capture Photo",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: pickFromGallery,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "From Gallery",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 📄 Selected Paper
              if (selectedFile != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B2E),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName ?? "",
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              fileSize != null ? formatSize(fileSize!) : "",
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: removeFile,
                        child: const Text(
                          "Remove",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // 🚀 Submit Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FACFE), Color(0xFF8E2DE2)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    "Submit for Marking",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
}
