import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';
import '../services/chat_service.dart';
import 'dart:async';

/// Controller isolado para gerenciar estado do chat
class ChatController extends ChangeNotifier {
  ChatRoomModel? _currentRoom;
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  final TextEditingController messageController = TextEditingController();
  StreamSubscription? _messagesSubscription;

  ChatRoomModel? get currentRoom => _currentRoom;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  /// Inicializa o chat para uma corrida
  Future<void> initializeChat({
    required String corridaId,
    required String motoristaId,
    required String motoristaName,
    required String empresaId,
    required String empresaName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentRoom = await ChatService.getOrCreateChatRoom(
        corridaId: corridaId,
        motoristaId: motoristaId,
        motoristaName: motoristaName,
        empresaId: empresaId,
        empresaName: empresaName,
      );

      _messages = await ChatService.getMessages(_currentRoom!.id);
      
      // Escuta novas mensagens em tempo real
      ChatService.listenMessages(_currentRoom!.id, _onNewMessage);
      
      // Adiciona listener para compatibilidade
      ChatService.addMessageListener(_onNewMessage);
    } catch (e) {
      debugPrint('Erro ao inicializar chat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envia uma mensagem
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String senderType,
  }) async {
    if (messageController.text.trim().isEmpty || _currentRoom == null) {
      return;
    }

    final content = messageController.text.trim();
    messageController.clear();

    try {
      await ChatService.sendMessage(
        chatRoomId: _currentRoom!.id,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        content: content,
      );

      // Atualiza mensagens localmente
      _messages = await ChatService.getMessages(_currentRoom!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao enviar mensagem: $e');
    }
  }

  /// Callback para novas mensagens recebidas
  void _onNewMessage(String chatRoomId, MessageModel message) {
    if (_currentRoom?.id == chatRoomId) {
      _messages = [..._messages, message];
      notifyListeners();
    }
  }

  /// Marca mensagens como lidas
  Future<void> markAsRead(String userId) async {
    if (_currentRoom != null) {
      await ChatService.markAsRead(_currentRoom!.id, userId);
      _messages = await ChatService.getMessages(_currentRoom!.id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    _messagesSubscription?.cancel();
    if (_currentRoom != null) {
      ChatService.stopListening(_currentRoom!.id);
    }
    ChatService.removeMessageListener(_onNewMessage);
    super.dispose();
  }
}





