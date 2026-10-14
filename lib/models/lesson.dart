import 'package:cloud_firestore/cloud_firestore.dart';

class LessonSection {
  final int order;
  final String titleEn;
  final bool isMainTitle;
  final String contentEn;

  const LessonSection({
    required this.order,
    required this.titleEn,
    required this.isMainTitle,
    required this.contentEn,
  });

  factory LessonSection.fromMap(Map<String, dynamic> map) {
    return LessonSection(
      order: (map['order'] as num?)?.toInt() ?? 0,
      titleEn: map['title_en'] as String? ?? '',
      isMainTitle: map['isMainTitle'] as bool? ?? false,
      contentEn: map['content_en'] as String? ?? '',
    );
  }

  String getTitle(String languageCode) => titleEn;
  String getContent(String languageCode) => contentEn;
}

class LessonQuestion {
  final int order;
  final String type;
  final String textEn;
  final List<String> optionsEn;
  final int correctIndex;
  final int points;

  const LessonQuestion({
    required this.order,
    required this.type,
    required this.textEn,
    required this.optionsEn,
    required this.correctIndex,
    required this.points,
  });

  factory LessonQuestion.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'open';
    final isMultipleChoice = type == 'multiple_choice';
    return LessonQuestion(
      order: (map['order'] as num?)?.toInt() ?? 0,
      type: type,
      textEn: map['text_en'] as String? ?? '',
      optionsEn: isMultipleChoice
          ? ((map['options_en'] as List?)?.whereType<String>().toList() ??
              const [])
          : const [],
      correctIndex:
          isMultipleChoice ? (map['correctIndex'] as num?)?.toInt() ?? -1 : -1,
      points: (map['points'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isMultipleChoice => type == 'multiple_choice';
  bool get isOpen => type == 'open';
}

class Lesson {
  final String id;
  final int order;
  final int dayNumber;
  final bool isVisible;
  final int pointsForReading;
  final String titleEn;
  final String imageUrl;
  final int totalQuestions;
  final List<LessonSection> sections;
  final List<LessonQuestion> questions;

  const Lesson({
    required this.id,
    required this.order,
    required this.dayNumber,
    required this.isVisible,
    required this.pointsForReading,
    required this.titleEn,
    required this.imageUrl,
    required this.totalQuestions,
    required this.sections,
    required this.questions,
  });

  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final rawSections = data['sections'];
    List<LessonSection> sections;
    if (rawSections is List) {
      sections = rawSections
          .whereType<Map<String, dynamic>>()
          .map(LessonSection.fromMap)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } else {
      sections = [];
    }

    final rawQuestions = data['questions'];
    List<LessonQuestion> questions;
    if (rawQuestions is List) {
      questions = rawQuestions
          .whereType<Map<String, dynamic>>()
          .map(LessonQuestion.fromMap)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } else {
      questions = [];
    }

    return Lesson(
      id: doc.id,
      order: (data['order'] as num?)?.toInt() ?? 0,
      dayNumber: (data['dayNumber'] as num?)?.toInt() ?? 0,
      isVisible: data['isVisible'] as bool? ?? false,
      pointsForReading: (data['pointsForReading'] as num?)?.toInt() ?? 0,
      titleEn: data['title_en'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      totalQuestions: (data['totalQuestions'] as num?)?.toInt() ?? 0,
      sections: sections,
      questions: questions,
    );
  }

  String getTitle(String languageCode) => titleEn;
}
