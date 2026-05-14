import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selected;

  static const _languages = [
    ('English', '🇬🇧'),
    ('Romanian', '🇷🇴'),
    ('Polish', '🇵🇱'),
    ('German', '🇩🇪'),
    ('Hungarian', '🇭🇺'),
    ('Czech', '🇨🇿'),
    ('Slovak', '🇸🇰'),
    ('Bulgarian', '🇧🇬'),
    ('Ukrainian', '🇺🇦'),
    ('Russian', '🇷🇺'),
    ('Spanish', '🇪🇸'),
  ];

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', _selected!);
    if (mounted) context.go('/access-code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Image.asset('assets/images/logo.png', width: 160),
              const SizedBox(height: 24),
              const Text(
                'Choose your language',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff003e6d),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: _languages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, i) {
                    final (name, flag) = _languages[i];
                    final selected = _selected == name;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xfff0f7ff)
                              : Colors.white,
                          border: Border.all(
                            color: selected
                                ? const Color(0xff007398)
                                : const Color(0xffe0ddd6),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(flag,
                                style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff003e6d),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff003e6d),
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Continue',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
