/// Modelo de mensagem do sistema de chat
class MessageModel {
  final String id;
  final String corridaId;
  final String senderId;
  final String senderName;
  final String senderType; // 'motorista', 'empresa', 'admin'
  final String content;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.corridaId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      corridaId: json['corridaId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderType: json['senderType'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'corridaId': corridaId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  MessageModel copyWith({
    String? id,
    String? corridaId,
    String? senderId,
    String? senderName,
    String? senderType,
    String? content,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      corridaId: corridaId ?? this.corridaId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}





