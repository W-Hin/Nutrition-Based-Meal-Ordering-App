class ReviewModel {
  final String? id;
  final String userId;
  final String storeId;
  final String orderId;
  final int rating; // 1–5
  final String comment;
  final String? adminReply;
  final DateTime? repliedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional denormalised fields (from JOIN queries)
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

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id:         map['id'] as String?,
      userId:     map['user_id'] as String? ?? '',
      storeId:    map['store_id'] as String? ?? '',
      orderId:    map['order_id'] as String? ?? '',
      rating:     map['rating'] as int? ?? 0,
      comment:    map['comment'] as String? ?? '',
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
      userName:   map['users']?['full_name'] as String?,
      storeName:  map['stores']?['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id':  userId,
        'store_id': storeId,
        'order_id': orderId,
        'rating':   rating,
        'comment':  comment,
      };
}
