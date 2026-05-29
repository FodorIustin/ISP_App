import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeLanguageScreen extends StatefulWidget {
  const ChangeLanguageScreen({super.key});

  @override
  State<ChangeLanguageScreen> createState() => _ChangeLanguageScreenState();
}

class _ChangeLanguageScreenState extends State<ChangeLanguageScreen> {
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
    ('Portuguese', '🇵🇹'),
    ('Albanian', '🇦🇱'),
    ('Armenian', '🇦🇲'),
    ('Greek', '🇬🇷'),
    ('Dutch', '🇳🇱'),
    ('Macedonian', '🇲🇰'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selected_language');
    if (mounted && saved != null) {
      setState(() => _selected = saved);
    }
  }

  Future<void> _save() async {
    if (_selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', _selected!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Language updated successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff003e6d),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Language',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Choose your preferred language',
              style: TextStyle(fontSize: 13, color: Color(0xff888888)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _languages.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                          Text(flag, style: const TextStyle(fontSize: 32)),
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
                onPressed: _selected == null ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff003e6d),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Save', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
