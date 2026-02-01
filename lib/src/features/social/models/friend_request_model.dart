import 'package:cloud_firestore/cloud_firestore.dart';

/// Friend request: from → to, status pending | accepted | rejected
class FriendRequestModel {
  final String id;
  final String from;
  final String to;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime createdAt;

  const FriendRequestModel({
    required this.id,
    required this.from,
    required this.to,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FriendRequestModel(
      id: doc.id,
      from: d['from'] as String,
      to: d['to'] as String,
      status: d['status'] as String? ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'from': from,
        'to': to,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
