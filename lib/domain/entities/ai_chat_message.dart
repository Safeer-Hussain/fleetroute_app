import 'package:equatable/equatable.dart';

class AiChatMessage extends Equatable {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final String timestamp;
  final bool isStreaming;

  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  AiChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    String? timestamp,
    bool? isStreaming,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  factory AiChatMessage.fromMap(Map<String, dynamic> map) {
    return AiChatMessage(
      id: map['id'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      content: map['content'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      isStreaming: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'role': role, 'content': content, 'timestamp': timestamp};
  }

  @override
  List<Object?> get props => [id, role, content, timestamp, isStreaming];
}
