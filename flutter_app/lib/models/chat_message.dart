import 'package:cloud_firestore/cloud_firestore.dart';
import 'shopify_product.dart';

enum MessageRole { user, assistant }

enum ChatMode { prePurchase, postPurchase }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isLoading;

  /// When non-null this message renders as a product offer card instead of text.
  /// Not persisted to Firestore (ephemeral UI state).
  final ShopifyProduct? offer;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
    this.offer,
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
