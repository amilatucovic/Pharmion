class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final int? reservationId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.reservationId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? true,
        readAt: json['readAt'] != null
            ? DateTime.tryParse('${json['readAt']}Z')
            : null,
        createdAt:
            DateTime.tryParse('${json['createdAt']}Z') ?? DateTime.now(),
        reservationId: json['reservationId'] as int?,
      );
}