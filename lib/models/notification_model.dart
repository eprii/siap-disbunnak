import 'package:cloud_firestore/cloud_firestore.dart';

enum SiapNotificationCategory {
  information,
  warning,
  system,
}

class SiapNotificationModel {
  final String id;
  final String recipientId;
  final String recipientRole;
  final String senderId;
  final String eventType;
  final SiapNotificationCategory category;
  final String sourceCollection;
  final String sourceDocumentId;
  final String sourceOwnerId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;
  final String dedupKey;

  const SiapNotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.senderId,
    required this.eventType,
    required this.category,
    required this.sourceCollection,
    required this.sourceDocumentId,
    required this.sourceOwnerId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.readAt,
    required this.dedupKey,
  });

  bool get hasSource =>
      sourceCollection.trim().isNotEmpty ||
      sourceDocumentId.trim().isNotEmpty ||
      sourceOwnerId.trim().isNotEmpty;

  factory SiapNotificationModel.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();

    return SiapNotificationModel(
      id: document.id,
      recipientId: _readString(data['recipient_id']),
      recipientRole: _readString(data['recipient_role']),
      senderId: _readString(data['sender_id']),
      eventType: _readString(data['event_type']),
      category: parseSiapNotificationCategory(data['category']),
      sourceCollection: _readString(data['source_collection']),
      sourceDocumentId: _readString(data['source_document_id']),
      sourceOwnerId: _readString(data['source_owner_id']),
      title: _readString(data['title']).isEmpty
          ? 'Notifikasi SIAP'
          : _readString(data['title']),
      message: _readString(data['message']),
      isRead: data['is_read'] == true,
      createdAt: _readDateTime(data['created_at']),
      readAt: _readDateTime(data['read_at']),
      dedupKey: _readString(data['dedup_key']),
    );
  }
}

SiapNotificationCategory parseSiapNotificationCategory(
  dynamic value,
) {
  final String normalized = value?.toString().trim().toLowerCase() ?? '';

  if (normalized == 'warning' ||
      normalized == 'peringatan' ||
      normalized == 'alert') {
    return SiapNotificationCategory.warning;
  }

  if (normalized == 'system' || normalized == 'sistem') {
    return SiapNotificationCategory.system;
  }

  return SiapNotificationCategory.information;
}

String siapNotificationCategoryValue(
  SiapNotificationCategory category,
) {
  switch (category) {
    case SiapNotificationCategory.information:
      return 'information';
    case SiapNotificationCategory.warning:
      return 'warning';
    case SiapNotificationCategory.system:
      return 'system';
  }
}

String siapNotificationCategoryLabel(
  SiapNotificationCategory category,
) {
  switch (category) {
    case SiapNotificationCategory.information:
      return 'Informasi';
    case SiapNotificationCategory.warning:
      return 'Peringatan';
    case SiapNotificationCategory.system:
      return 'Sistem';
  }
}

String _readString(dynamic value) =>
    value?.toString().trim() ?? '';

DateTime? _readDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
