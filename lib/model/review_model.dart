class ReviewModel {
  final String?   id;
  final String    userId;
  final String    storeId;
  final int       orderId;   // bigint in DB — must be int here
  final int       rating;    // 1–5
  final String    comment;
  final String?   adminReply;
  final DateTime? repliedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Denormalised fields from JOIN queries
  final String? userName;
  final String? storeName;

  const ReviewModel({
    this.id,
    required this.userId,
    required this.storeId,
    required this.orderId,
    required this.rating,
    required this.comment,
    this.adminReply,
    this.repliedAt,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.storeName,
  });

  // fromMap
  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    // User name: join may arrive as `user` (our alias) or as `users`
    final userMap = map['user'] ?? map['users'];
    String? userName;
    if (userMap is Map) {
      final first = (userMap['first_name'] as String? ?? '').trim();
      final last  = (userMap['last_name']  as String? ?? '').trim();
      userName = [first, last].where((s) => s.isNotEmpty).join(' ');
      if (userName.isEmpty) userName = userMap['full_name'] as String?;
    }

    return ReviewModel(
      id:         map['id']         as String?,
      userId:     map['user_id']    as String? ?? '',
      storeId:    map['store_id']   as String? ?? '',
      orderId:    (map['order_id']  as num?)?.toInt() ?? 0,
      rating:     (map['rating']    as num?)?.toInt() ?? 0,
      comment:    map['comment']    as String? ?? '',
      adminReply: map['admin_reply'] as String?,
      repliedAt:  map['replied_at'] != null
          ? DateTime.tryParse(map['replied_at'])
          : null,
      createdAt:  map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
      updatedAt:  map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'])
          : null,
      userName:  userName,
      storeName: (map['stores'] as Map?)?['name'] as String?,
    );
  }

  // toMap (for INSERT)
  Map<String, dynamic> toMap() => {
        'user_id':  userId,
        'store_id': storeId,
        'order_id': orderId.toString(),  // DB column is text type
        'rating':   rating,
        'comment':  comment,
      };

  // copyWith
  ReviewModel copyWith({
    String?   id,
    String?   userId,
    String?   storeId,
    int?      orderId,
    int?      rating,
    String?   comment,
    String?   adminReply,
    DateTime? repliedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String?   userName,
    String?   storeName,
  }) {
    return ReviewModel(
      id:         id         ?? this.id,
      userId:     userId     ?? this.userId,
      storeId:    storeId    ?? this.storeId,
      orderId:    orderId    ?? this.orderId,
      rating:     rating     ?? this.rating,
      comment:    comment    ?? this.comment,
      adminReply: adminReply ?? this.adminReply,
      repliedAt:  repliedAt  ?? this.repliedAt,
      createdAt:  createdAt  ?? this.createdAt,
      updatedAt:  updatedAt  ?? this.updatedAt,
      userName:   userName   ?? this.userName,
      storeName:  storeName  ?? this.storeName,
    );
  }
}
