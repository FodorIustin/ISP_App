import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

class RegisterProfileScreen extends StatefulWidget {
  const RegisterProfileScreen({super.key});

  @override
  State<RegisterProfileScreen> createState() =>
      _RegisterProfileScreenState();
}

class _RegisterProfileScreenState extends State<RegisterProfileScreen> {
  final _nameController = TextEditingController();
  String? _country;
  String? _photoPath;
  bool _loading = false;

  static const _countries = [
    ('🇬🇧', 'United Kingdom'),
    ('🇷🇴', 'Romania'),
    ('🇵🇱', 'Poland'),
    ('🇩🇪', 'Germany'),
    ('🇭🇺', 'Hungary'),
    ('🇨🇿', 'Czech Republic'),
    ('🇸🇰', 'Slovakia'),
    ('🇧🇬', 'Bulgaria'),
    ('🇺🇦', 'Ukraine'),
    ('🇷🇺', 'Russia'),
    ('🇪🇸', 'Spain'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile != null) setState(() => _photoPath = xfile.path);
  }

  Future<void> _onComplete() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final language =
          prefs.getString('selected_language') ?? 'English';
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await AuthService().saveProfile(
        uid: uid,
        name: _nameController.text.trim(),
        country: _country!,
        language: language,
        photoPath: _photoPath,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
      setState(() => _loading = false);
    }
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty && _country != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Set up your profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff003e6d),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tell us a bit about yourself',
                style: TextStyle(fontSize: 13, color: Color(0xff888888)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Photo picker
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xff007398),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                        image: _photoPath != null
                            ? DecorationImage(
                                image: FileImage(File(_photoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: const Color(0xfff5f5f5),
                      ),
                      child: _photoPath == null
                          ? const Icon(Icons.camera_alt_outlined,
                              color: Color(0xff007398), size: 32)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xff007398),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Name field
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Full name',
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xffe0ddd6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xff007398)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Country dropdown
              DropdownButtonFormField<String>(
                initialValue: _country,
                hint: const Text('Country'),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xffe0ddd6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xff007398)),
                  ),
                ),
                items: _countries
                    .map((c) => DropdownMenuItem(
                          value: c.$2,
                          child: Row(
                            children: [
                              Text(c.$1,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Text(c.$2),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _country = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_canSubmit && !_loading) ? _onComplete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff003e6d),
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Complete setup',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
