import 'message_model.dart';

/// Modelo de sala de chat (uma por corrida)
class ChatRoomModel {
  final String id;
  final String corridaId;
  final String motoristaId;
  final String motoristaName;
  final String empresaId;
  final String empresaName;
  final List<MessageModel> messages;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  ChatRoomModel({
    required this.id,
    required this.corridaId,
    required this.motoristaId,
    required this.motoristaName,
    required this.empresaId,
    required this.empresaName,
    this.messages = const [],
    required this.createdAt,
    this.lastMessageAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] ?? '',
      corridaId: json['corridaId'] ?? '',
      motoristaId: json['motoristaId'] ?? '',
      motoristaName: json['motoristaName'] ?? '',
      empresaId: json['empresaId'] ?? '',
      empresaName: json['empresaName'] ?? '',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => MessageModel.fromJson(m))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'corridaId': corridaId,
      'motoristaId': motoristaId,
      'motoristaName': motoristaName,
      'empresaId': empresaId,
      'empresaName': empresaName,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
    };
  }

  String get lastMessage {
    if (messages.isEmpty) return 'Nenhuma mensagem';
    return messages.last.content;
  }

  int get unreadCount {
    return messages.where((m) => !m.isRead).length;
  }
}





