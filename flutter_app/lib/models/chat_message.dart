import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageRole { user, assistant }

enum ChatMode { prePurchase, postPurchase }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
  });

  factory ChatMessage.loading() => ChatMessage(
        id: 'loading',
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isLoading: true,
      );

  Map<String, dynamic> toMap() => {
        'role': role.name,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        role: MessageRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => MessageRole.assistant,
        ),
        content: map['content'] as String? ?? '',
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
