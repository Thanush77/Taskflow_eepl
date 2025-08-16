class TaskFile {
  final int id;
  final int taskId;
  final String fileName;
  final String originalName;
  final String mimeType;
  final int size;
  final String url;
  final int uploadedBy;
  final String? uploadedByName;
  final DateTime uploadedAt;

  const TaskFile({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.url,
    required this.uploadedBy,
    this.uploadedByName,
    required this.uploadedAt,
  });

  factory TaskFile.fromJson(Map<String, dynamic> json) {
    return TaskFile(
      id: json['id'] as int,
      taskId: json['task_id'] ?? json['taskId'] as int,
      fileName: json['file_name'] ?? json['fileName'] as String,
      originalName: json['original_name'] ?? json['originalName'] as String,
      mimeType: json['mime_type'] ?? json['mimeType'] as String,
      size: json['size'] as int,
      url: json['url'] as String,
      uploadedBy: json['uploaded_by'] ?? json['uploadedBy'] as int,
      uploadedByName: json['uploaded_by_name'] ?? json['uploadedByName'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? json['uploadedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'file_name': fileName,
      'original_name': originalName,
      'mime_type': mimeType,
      'size': size,
      'url': url,
      'uploaded_by': uploadedBy,
      'uploaded_by_name': uploadedByName,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  TaskFile copyWith({
    int? id,
    int? taskId,
    String? fileName,
    String? originalName,
    String? mimeType,
    int? size,
    String? url,
    int? uploadedBy,
    String? uploadedByName,
    DateTime? uploadedAt,
  }) {
    return TaskFile(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      fileName: fileName ?? this.fileName,
      originalName: originalName ?? this.originalName,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      url: url ?? this.url,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  String get displayName => originalName.isNotEmpty ? originalName : fileName;
  
  String get extension {
    final parts = originalName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isPdf => mimeType == 'application/pdf';
  bool get isDocument => mimeType.contains('word') || 
                        mimeType.contains('document') || 
                        mimeType.startsWith('text/');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TaskFile{id: $id, taskId: $taskId, originalName: $originalName, size: $size}';
  }
}