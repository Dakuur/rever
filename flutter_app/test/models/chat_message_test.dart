import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rever_chat/models/chat_message.dart';
import 'package:rever_chat/models/shopify_product.dart';

void main() {
  group('MessageRole', () {
    test('has user and assistant values', () {
      expect(MessageRole.values, contains(MessageRole.user));
      expect(MessageRole.values, contains(MessageRole.assistant));
    });
  });

  group('ChatMode', () {
    test('has prePurchase and postPurchase values', () {
      expect(ChatMode.values, contains(ChatMode.prePurchase));
      expect(ChatMode.values, contains(ChatMode.postPurchase));
    });
  });

  group('ChatMessage', () {
    final fixedTime = DateTime(2024, 6, 1, 10, 30);

    test('constructs with required fields', () {
      final msg = ChatMessage(
        id: 'abc',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: fixedTime,
      );
      expect(msg.id, 'abc');
      expect(msg.role, MessageRole.user);
      expect(msg.content, 'Hello');
      expect(msg.timestamp, fixedTime);
      expect(msg.isLoading, false);
      expect(msg.offer, isNull);
    });

    test('loading() factory creates a loading message', () {
      final msg = ChatMessage.loading();
      expect(msg.id, 'loading');
      expect(msg.role, MessageRole.assistant);
      expect(msg.content, '');
      expect(msg.isLoading, true);
    });

    test('toMap() serialises role as string', () {
      final msg = ChatMessage(
        id: 'x',
        role: MessageRole.user,
        content: 'Hi',
        timestamp: fixedTime,
      );
      final map = msg.toMap();
      expect(map['role'], 'user');
    });

    test('toMap() serialises content', () {
      final msg = ChatMessage(
        id: 'x',
        role: MessageRole.assistant,
        content: 'Hello back',
        timestamp: fixedTime,
      );
      expect(msg.toMap()['content'], 'Hello back');
    });

    test('toMap() serialises timestamp as Timestamp', () {
      final msg = ChatMessage(
        id: 'x',
        role: MessageRole.user,
        content: '',
        timestamp: fixedTime,
      );
      expect(msg.toMap()['timestamp'], isA<Timestamp>());
    });

    test('toMap() does NOT include offer (ephemeral field)', () {
      final product = ShopifyProduct(
        id: 'p1',
        title: 'T-shirt',
        description: 'A shirt',
        handle: 't-shirt',
        price: '29.99',
        currencyCode: 'EUR',
        availableForSale: true,
        variants: [],
      );
      final msg = ChatMessage(
        id: 'x',
        role: MessageRole.assistant,
        content: 'Check this out',
        timestamp: fixedTime,
        offer: product,
      );
      expect(msg.toMap().containsKey('offer'), false);
    });

    test('fromMap() deserialises user role', () {
      final map = {
        'role': 'user',
        'content': 'test content',
        'timestamp': Timestamp.fromDate(fixedTime),
      };
      final msg = ChatMessage.fromMap('id1', map);
      expect(msg.id, 'id1');
      expect(msg.role, MessageRole.user);
      expect(msg.content, 'test content');
    });

    test('fromMap() deserialises assistant role', () {
      final map = {
        'role': 'assistant',
        'content': 'reply',
        'timestamp': Timestamp.fromDate(fixedTime),
      };
      final msg = ChatMessage.fromMap('id2', map);
      expect(msg.role, MessageRole.assistant);
    });

    test('fromMap() falls back to assistant for unknown role', () {
      final map = {
        'role': 'unknown_role',
        'content': '',
        'timestamp': Timestamp.fromDate(fixedTime),
      };
      final msg = ChatMessage.fromMap('id3', map);
      expect(msg.role, MessageRole.assistant);
    });

    test('fromMap() handles null content gracefully', () {
      final map = {
        'role': 'user',
        'content': null,
        'timestamp': Timestamp.fromDate(fixedTime),
      };
      final msg = ChatMessage.fromMap('id4', map);
      expect(msg.content, '');
    });

    test('fromMap() handles null timestamp gracefully', () {
      final map = {
        'role': 'user',
        'content': 'Hi',
        'timestamp': null,
      };
      // Should not throw; uses DateTime.now() as fallback
      expect(() => ChatMessage.fromMap('id5', map), returnsNormally);
    });

    test('round-trip: toMap() -> fromMap() preserves data', () {
      final original = ChatMessage(
        id: 'rt1',
        role: MessageRole.user,
        content: 'Round trip',
        timestamp: fixedTime,
      );
      final map = original.toMap();
      final restored = ChatMessage.fromMap('rt1', map);
      expect(restored.id, original.id);
      expect(restored.role, original.role);
      expect(restored.content, original.content);
      expect(restored.timestamp.millisecondsSinceEpoch,
          original.timestamp.millisecondsSinceEpoch);
    });
  });
}
