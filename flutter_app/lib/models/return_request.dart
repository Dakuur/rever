import 'package:cloud_firestore/cloud_firestore.dart';

enum ReturnResolution { sizeExchange, giftCard, refund, pending }

class ReturnRequest {
  final String id;
  final String customerEmail;
  final String orderId;
  final String productDescription;
  final String reason;
  final ReturnResolution resolution;
  final DateTime createdAt;
  final String? userId;

  const ReturnRequest({
    required this.id,
    required this.customerEmail,
    required this.orderId,
    required this.productDescription,
    required this.reason,
    required this.resolution,
    required this.createdAt,
    this.userId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerEmail': customerEmail,
        'orderId': orderId,
        'productDescription': productDescription,
        'reason': reason,
        'resolution': resolution.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'userId': userId,
      };

  factory ReturnRequest.fromMap(String id, Map<String, dynamic> map) =>
      ReturnRequest(
        id: id,
        customerEmail: map['customerEmail'] as String? ?? '',
        orderId: map['orderId'] as String? ?? '',
        productDescription: map['productDescription'] as String? ?? '',
        reason: map['reason'] as String? ?? '',
        resolution: ReturnResolution.values.firstWhere(
          (r) => r.name == map['resolution'],
          orElse: () => ReturnResolution.pending,
        ),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        userId: map['userId'] as String?,
      );
}
