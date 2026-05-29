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
    );
  }

  String getTitle(String languageCode) => titleEn;
}
