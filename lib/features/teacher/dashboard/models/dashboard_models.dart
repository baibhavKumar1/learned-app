import 'package:cloud_firestore/cloud_firestore.dart';

class ActionItem {
  final String id;
  final String title;
  final String subtitle;
  final String type; // e.g., 'student_stuck', 'doubt', 'review_pending'
  final String actionText;
  final DateTime createdAt;
  final bool isResolved;
  final Map<String, dynamic>? metadata; // to hold studentId, assignmentId, etc.

  ActionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.actionText,
    required this.createdAt,
    required this.isResolved,
    this.metadata,
  });

  factory ActionItem.fromMap(Map<String, dynamic> map, String documentId) {
    return ActionItem(
      id: documentId,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      type: map['type'] ?? 'unknown',
      actionText: map['actionText'] ?? 'View',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isResolved: map['isResolved'] ?? false,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'actionText': actionText,
      'createdAt': Timestamp.fromDate(createdAt),
      'isResolved': isResolved,
      'metadata': metadata,
    };
  }
}

class ActivityItem {
  final String id;
  final String title;
  final String type; // e.g., 'upvote', 'comment', 'discussion'
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityItem({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityItem.fromMap(Map<String, dynamic> map, String documentId) {
    return ActivityItem(
      id: documentId,
      title: map['title'] ?? '',
      type: map['type'] ?? 'unknown',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}
