import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/lesson_service.dart';

// ─── Question data model (hardcoded until Firebase questions are built) ───────

enum _QType { multipleChoice, openText }

class _Question {
  const _Question({
    required this.index,
    required this.type,
    required this.text,
    this.options = const [],
    this.correctIndex = -1,
    this.points = 0,
  });

  final int index;
  final _QType type;
  final String text;
  final List<String> options;
  final int correctIndex;
  final int points;
}

const _lesson1Questions = <_Question>[
  _Question(
    index: 0,
    type: _QType.multipleChoice,
    text:
        'According to the lesson, what happens when teachers gather with a shared purpose?',
    options: [
      'They compete for the best teaching methods',
      'The walls separating them dissolve and belonging replaces isolation',
      'They focus only on curriculum development',
      'They become more independent in their work',
    ],
    correctIndex: 1,
    points: 20,
  ),
  _Question(
    index: 1,
    type: _QType.multipleChoice,
    text:
        'What does the book of Proverbs say about people sharpening each other?',
    options: [
      'As water shapes stone, so patience shapes character',
      'As light guides the path, so wisdom guides people',
      'As iron sharpens iron, so one person sharpens another',
      'As wind bends the tree, so hardship builds strength',
    ],
    correctIndex: 2,
    points: 20,
  ),
  _Question(
    index: 2,
    type: _QType.openText,
    text:
        'Reflect on a time when community made a difference in your teaching. What happened and what did you learn?',
  ),
  _Question(
    index: 3,
    type: _QType.multipleChoice,
    text: 'What is the ISP vision according to this lesson?',
    options: [
      'To build the largest network of Christian schools worldwide',
      'To provide funding for teachers in developing countries',
      'A community of Christ-directed teachers that can transform classrooms, cities and nations',
      'To translate the Bible into every language through teachers',
    ],
    correctIndex: 2,
    points: 20,
  ),
];

List<_Question> _questionsFor(String lessonId) {
  if (lessonId == 'lesson_1') return _lesson1Questions;
  return [];
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LessonQuestionsScreen extends StatefulWidget {
  const LessonQuestionsScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  State<LessonQuestionsScreen> createState() => _LessonQuestionsScreenState();
}

class _LessonQuestionsScreenState extends State<LessonQuestionsScreen> {
  final _service = LessonService();
  final _textController = TextEditingController();
  late final List<_Question> _questions;

  int _currentIndex = 0;
  int? _selectedOption;
  bool _hasSubmitted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _questions = _questionsFor(widget.lessonId);
    _checkIfAlreadyAnswered();
  }

  Future<void> _checkIfAlreadyAnswered() async {
    final answered =
        await _service.hasAnsweredQuestions(widget.lessonId);
    if (!mounted || !answered) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('You have already answered these questions'),
      backgroundColor: Color(0xff007398),
      duration: Duration(seconds: 3),
    ));
    context.go('/home');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  _Question get _q => _questions[_currentIndex];
  bool get _isLast => _currentIndex == _questions.length - 1;

  void _selectOption(int index) {
    if (_hasSubmitted) return;
    setState(() => _selectedOption = index);
  }

  Future<void> _submitMultipleChoice() async {
    if (_isSaving || _selectedOption == null || _hasSubmitted) return;
    final selected = _selectedOption!;
    final isCorrect = selected == _q.correctIndex;

    setState(() {
      _hasSubmitted = true;
      _isSaving = true;
    });

    await _service.saveQuestionAnswer(
      lessonId: widget.lessonId,
      questionIndex: _q.index,
      isCorrect: isCorrect,
      points: isCorrect ? _q.points : 0,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isCorrect ? 'Correct! +${_q.points} pts' : 'Not quite right'),
      backgroundColor:
          isCorrect ? const Color(0xff2e7d32) : const Color(0xffE24B4A),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _submitOpenText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    await _service.saveQuestionAnswer(
      lessonId: widget.lessonId,
      questionIndex: _q.index,
      answerText: text,
      isCorrect: false,
      points: 0,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Reflection saved!'),
      backgroundColor: Color(0xff007398),
      duration: Duration(seconds: 2),
    ));

    _advance();
  }

  void _advance() {
    if (_isLast) {
      context.go('/lesson-results/${widget.lessonId}');
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _hasSubmitted = false;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _appBar(),
        body: const Center(
          child: Text('No questions available.',
              style: TextStyle(color: Color(0xff888888))),
        ),
      );
    }

    final q = _q;
    final bottomButton = _buildBottomButton();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(),
      body: Column(
        children: [
          _ProgressHeader(
            current: _currentIndex + 1,
            total: _questions.length,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question number pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xffe3f0ff),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Question ${_currentIndex + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff003e6d),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Question text
                  Text(
                    q.text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff0f1923),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Answer area
                  if (q.type == _QType.multipleChoice)
                    _OptionList(
                      options: q.options,
                      selectedIndex: _selectedOption,
                      correctIndex:
                          _hasSubmitted ? q.correctIndex : null,
                      hasSubmitted: _hasSubmitted,
                      onSelect: _selectOption,
                    )
                  else
                    _OpenTextField(
                      controller: _textController,
                      enabled: !_isSaving,
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (bottomButton != null)
            _BottomContainer(child: bottomButton),
        ],
      ),
    );
  }

  Widget? _buildBottomButton() {
    final q = _q;

    if (q.type == _QType.openText) {
      return _PrimaryButton(
        label: 'Submit reflection',
        color: const Color(0xff007398),
        onTap: _isSaving ? null : _submitOpenText,
        loading: _isSaving,
      );
    }

    if (_hasSubmitted) {
      return _PrimaryButton(
        label: _isLast ? 'See results' : 'Next question →',
        color: const Color(0xff003e6d),
        onTap: _advance,
      );
    }

    if (_selectedOption != null) {
      return _PrimaryButton(
        label: 'Submit answer',
        color: const Color(0xff003e6d),
        onTap: _isSaving ? null : _submitMultipleChoice,
        loading: _isSaving,
      );
    }

    return null;
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: const Color(0xff003e6d),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      title: const Text(
        'Questions',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Progress header ──────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Question $current of $total',
            style: const TextStyle(fontSize: 11, color: Color(0xff888888)),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 4,
            child: Stack(
              children: [
                Container(
                    width: constraints.maxWidth,
                    color: const Color(0xffe0ddd6)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: constraints.maxWidth * current / total,
                  color: const Color(0xfff9b625),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Multiple choice options ──────────────────────────────────────────────────

class _OptionList extends StatelessWidget {
  const _OptionList({
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    required this.hasSubmitted,
    required this.onSelect,
  });

  final List<String> options;
  final int? selectedIndex;
  final int? correctIndex; // null = not yet revealed
  final bool hasSubmitted;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          _OptionCard(
            text: options[i],
            isSelected: selectedIndex == i,
            isCorrect: hasSubmitted && correctIndex == i,
            isWrong: hasSubmitted && selectedIndex == i && i != correctIndex,
            onTap: hasSubmitted ? null : () => onSelect(i),
          ),
          if (i < options.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color borderColor;
    final double borderWidth;
    Widget? trailing;

    if (isCorrect) {
      bg = const Color(0xffe8f5e9);
      borderColor = const Color(0xff2e7d32);
      borderWidth = 1.5;
      trailing = const Icon(Icons.check_circle,
          color: Color(0xff2e7d32), size: 18);
    } else if (isWrong) {
      bg = const Color(0xfffce8e8);
      borderColor = const Color(0xffE24B4A);
      borderWidth = 1.5;
      trailing =
          const Icon(Icons.cancel, color: Color(0xffE24B4A), size: 18);
    } else if (isSelected) {
      bg = const Color(0xffe3f0ff);
      borderColor = const Color(0xff003e6d);
      borderWidth = 1.5;
      trailing = null;
    } else {
      bg = const Color(0xfff8f7f4);
      borderColor = const Color(0xffe0ddd6);
      borderWidth = 1.0;
      trailing = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xff0f1923)),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Open text input ──────────────────────────────────────────────────────────

class _OpenTextField extends StatelessWidget {
  const _OpenTextField(
      {required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: 5,
      style: const TextStyle(fontSize: 14, color: Color(0xff0f1923)),
      decoration: InputDecoration(
        hintText: 'Write your reflection here...',
        hintStyle: const TextStyle(
            color: Color(0xffbbbbbb), fontSize: 14),
        contentPadding: const EdgeInsets.all(16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffe0ddd6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffe0ddd6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xff003e6d), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffe0ddd6)),
        ),
      ),
    );
  }
}

// ─── Bottom container ─────────────────────────────────────────────────────────

class _BottomContainer extends StatelessWidget {
  const _BottomContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Color(0xffeeeeee), width: 0.5)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
