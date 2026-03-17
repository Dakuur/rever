import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rever_chat/models/return_request.dart';

void main() {
  final fixedTime = DateTime(2024, 6, 15, 9, 0);

  group('ReturnResolution', () {
    test('has all four resolution values', () {
      expect(ReturnResolution.values, contains(ReturnResolution.sizeExchange));
      expect(ReturnResolution.values, contains(ReturnResolution.giftCard));
      expect(ReturnResolution.values, contains(ReturnResolution.refund));
      expect(ReturnResolution.values, contains(ReturnResolution.pending));
    });
  });

  group('ReturnRequest.toMap()', () {
    late ReturnRequest request;

    setUp(() {
      request = ReturnRequest(
        id: 'req-001',
        customerEmail: 'user@example.com',
        orderId: '1234',
        productDescription: 'Blue T-shirt',
        reason: 'Wrong size',
        resolution: ReturnResolution.sizeExchange,
        createdAt: fixedTime,
        userId: 'user-abc',
      );
    });

    test('serialises id', () {
      expect(request.toMap()['id'], 'req-001');
    });

    test('serialises customerEmail', () {
      expect(request.toMap()['customerEmail'], 'user@example.com');
    });

    test('serialises orderId', () {
      expect(request.toMap()['orderId'], '1234');
    });

    test('serialises productDescription', () {
      expect(request.toMap()['productDescription'], 'Blue T-shirt');
    });

    test('serialises reason', () {
      expect(request.toMap()['reason'], 'Wrong size');
    });

    test('serialises resolution as enum name', () {
      expect(request.toMap()['resolution'], 'sizeExchange');
    });

    test('serialises createdAt as Timestamp', () {
      expect(request.toMap()['createdAt'], isA<Timestamp>());
    });

    test('serialises userId', () {
      expect(request.toMap()['userId'], 'user-abc');
    });

    test('serialises null userId', () {
      final r = ReturnRequest(
        id: 'x',
        customerEmail: 'a@b.com',
        orderId: '99',
        productDescription: '',
        reason: '',
        resolution: ReturnResolution.refund,
        createdAt: fixedTime,
      );
      expect(r.toMap()['userId'], isNull);
    });
  });

  group('ReturnRequest.fromMap()', () {
    test('deserialises all fields', () {
      final map = {
        'customerEmail': 'test@test.com',
        'orderId': '5678',
        'productDescription': 'Red sneakers',
        'reason': 'Damaged',
        'resolution': 'giftCard',
        'createdAt': Timestamp.fromDate(fixedTime),
        'userId': 'uid-xyz',
      };
      final r = ReturnRequest.fromMap('doc1', map);
      expect(r.id, 'doc1');
      expect(r.customerEmail, 'test@test.com');
      expect(r.orderId, '5678');
      expect(r.productDescription, 'Red sneakers');
      expect(r.reason, 'Damaged');
      expect(r.resolution, ReturnResolution.giftCard);
      expect(r.userId, 'uid-xyz');
    });

    test('falls back to pending for unknown resolution', () {
      final map = {
        'customerEmail': '',
        'orderId': '',
        'productDescription': '',
        'reason': '',
        'resolution': 'completely_unknown',
        'createdAt': Timestamp.fromDate(fixedTime),
      };
      final r = ReturnRequest.fromMap('doc2', map);
      expect(r.resolution, ReturnResolution.pending);
    });

    test('handles null fields with defaults', () {
      final map = {
        'customerEmail': null,
        'orderId': null,
        'productDescription': null,
        'reason': null,
        'resolution': 'refund',
        'createdAt': Timestamp.fromDate(fixedTime),
      };
      final r = ReturnRequest.fromMap('doc3', map);
      expect(r.customerEmail, '');
      expect(r.orderId, '');
      expect(r.productDescription, '');
      expect(r.reason, '');
    });

    test('handles null createdAt without throwing', () {
      final map = {
        'customerEmail': 'a@b.com',
        'orderId': '1',
        'productDescription': '',
        'reason': '',
        'resolution': 'pending',
        'createdAt': null,
      };
      expect(() => ReturnRequest.fromMap('doc4', map), returnsNormally);
    });

    test('round-trip toMap -> fromMap preserves data', () {
      final original = ReturnRequest(
        id: 'rt-1',
        customerEmail: 'rt@test.com',
        orderId: '999',
        productDescription: 'Jacket',
        reason: 'Too big',
        resolution: ReturnResolution.refund,
        createdAt: fixedTime,
        userId: 'user-rt',
      );
      final restored = ReturnRequest.fromMap('rt-1', original.toMap());
      expect(restored.customerEmail, original.customerEmail);
      expect(restored.orderId, original.orderId);
      expect(restored.resolution, original.resolution);
      expect(restored.userId, original.userId);
    });
  });
}
