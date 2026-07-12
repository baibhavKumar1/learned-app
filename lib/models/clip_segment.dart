class ClipSegment {
  final String segmentId;
  final String docId;
  final String videoUrl;
  final String topic;
  final String summary;
  final double startSec;
  final double endSec;
  final String courseTitle;

  const ClipSegment({
    required this.segmentId,
    required this.docId,
    required this.videoUrl,
    required this.topic,
    required this.summary,
    required this.startSec,
    required this.endSec,
    required this.courseTitle,
  });

  factory ClipSegment.fromMap(Map<String, dynamic> map) {
    return ClipSegment(
      segmentId: map['segmentId'] as String? ?? '',
      docId: map['docId'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      topic: map['topic'] as String? ?? 'Untitled Topic',
      summary: map['summary'] as String? ?? '',
      startSec: (map['startSec'] as num?)?.toDouble() ?? 0.0,
      endSec: (map['endSec'] as num?)?.toDouble() ?? 0.0,
      courseTitle: map['courseTitle'] as String? ?? 'Unknown Course',
    );
  }
}
