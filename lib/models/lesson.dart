import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String id;
  final int order;
  final int dayNumber;
  final bool isVisible;
  final int pointsForReading;
  final String titleEn;
  final String contentEn;
  final String imageUrl;
  final int totalQuestions;

  const Lesson({
    required this.id,
    required this.order,
    required this.dayNumber,
    required this.isVisible,
    required this.pointsForReading,
    required this.titleEn,
    required this.contentEn,
    required this.imageUrl,
    required this.totalQuestions,
  });

  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lesson(
      id: doc.id,
      order: (data['order'] as num?)?.toInt() ?? 0,
      dayNumber: (data['dayNumber'] as num?)?.toInt() ?? 0,
      isVisible: data['isVisible'] as bool? ?? false,
      pointsForReading: (data['pointsForReading'] as num?)?.toInt() ?? 0,
      titleEn: data['title_en'] as String? ?? '',
      contentEn: data['content_en'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      totalQuestions: (data['totalQuestions'] as num?)?.toInt() ?? 0,
    );
  }

  String getTitle(String languageCode) => titleEn;
  String getContent(String languageCode) => contentEn;
}
