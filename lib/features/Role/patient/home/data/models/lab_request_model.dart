import '../../domain/entities/lab_request.dart';

/// Serialisation layer for [LabRequest].
class LabRequestModel extends LabRequest {
  const LabRequestModel({
    required super.id,
    required super.category,
    required super.priority,
    required super.title,
    required super.requestedBy,
    super.status,
  });

  factory LabRequestModel.fromJson(Map<String, dynamic> json) {
    return LabRequestModel(
      id: json['id']?.toString() ?? '',
      category: json['category'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      title: json['title'] as String? ?? '',
      requestedBy: json['requested_by'] as String? ?? '',
      status: _statusFrom(json['status'] as String?),
    );
  }

  static LabRequestStatus _statusFrom(String? value) {
    return switch (value) {
      'in_progress' => LabRequestStatus.inProgress,
      'ready' => LabRequestStatus.ready,
      _ => LabRequestStatus.requestSent,
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'priority': priority,
    'title': title,
    'requested_by': requestedBy,
    'status': status.name,
  };
}
