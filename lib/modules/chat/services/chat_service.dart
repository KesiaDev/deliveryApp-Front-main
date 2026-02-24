import '../models/message_model.dart';
import '../models/chat_room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Serviço de chat integrado com Firebase Firestore
class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _chatRoomsCollection = _firestore.collection('chatRooms');
  static final List<Function(String, MessageModel)> _messageListeners = [];
  static final Map<String, StreamSubscription> _activeSubscriptions = {};

  /// Busca ou cria uma sala de chat para uma corrida
  static Future<ChatRoomModel> getOrCreateChatRoom({
    required String corridaId,
    required String motoristaId,
    required String motoristaName,
    required String empresaId,
    required String empresaName,
  }) async {
    try {
      // Tenta buscar sala existente
      final querySnapshot = await _chatRoomsCollection
          .where('corridaId', isEqualTo: corridaId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return ChatRoomModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }

      // Cria nova sala
      final newRoomData = {
        'corridaId': corridaId,
        'motoristaId': motoristaId,
        'motoristaName': motoristaName,
        'empresaId': empresaId,
        'empresaName': empresaName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _chatRoomsCollection.add(newRoomData);
      
      return ChatRoomModel(
        id: docRef.id,
        corridaId: corridaId,
        motoristaId: motoristaId,
        motoristaName: motoristaName,
        empresaId: empresaId,
        empresaName: empresaName,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erro ao buscar/criar sala de chat: $e');
      rethrow;
    }
  }

  /// Envia uma mensagem
  static Future<MessageModel> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String content,
  }) async {
    try {
      // Busca corridaId da sala
      final roomDoc = await _chatRoomsCollection.doc(chatRoomId).get();
      final roomData = roomDoc.data() as Map<String, dynamic>?;
      final corridaId = roomData?['corridaId'] ?? '';
      
      final messageData = {
        'corridaId': corridaId,
        'senderId': senderId,
        'senderName': senderName,
        'senderType': senderType,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Adiciona mensagem à subcoleção
      final messageRef = await _chatRoomsCollection
          .doc(chatRoomId)
          .collection('messages')
          .add(messageData);

      // Atualiza lastMessageAt da sala
      await _chatRoomsCollection.doc(chatRoomId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      final message = MessageModel(
        id: messageRef.id,
        corridaId: messageData['corridaId'] as String,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Notifica listeners locais
      for (var listener in _messageListeners) {
        listener(chatRoomId, message);
      }

      // Envia notificação push (será implementado no backend)
      // FirebaseMessagingService.sendPushNotification(...)

      return message;
    } catch (e) {
      debugPrint('Erro ao enviar mensagem: $e');
      rethrow;
    }
  }

  /// Envia mensagem automática do sistema
  static Future<void> sendAutomaticMessage({
    required String corridaId,
    required String messageText,
  }) async {
    try {
      // Busca ou cria sala
      final querySnapshot = await _chatRoomsCollection
          .where('corridaId', isEqualTo: corridaId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('Sala de chat não encontrada para corrida: $corridaId');
        return;
      }

      final roomDoc = querySnapshot.docs.first;
      final roomData = roomDoc.data() as Map<String, dynamic>;

      await sendMessage(
        chatRoomId: roomDoc.id,
        senderId: 'system',
        senderName: 'Sistema',
        senderType: 'system',
        content: messageText,
      );
    } catch (e) {
      debugPrint('Erro ao enviar mensagem automática: $e');
    }
  }

  /// Busca mensagens de uma sala
  static Future<List<MessageModel>> getMessages(String chatRoomId) async {
    try {
      final querySnapshot = await _chatRoomsCollection
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel(
          id: doc.id,
          corridaId: data['corridaId'] ?? '',
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? '',
          senderType: data['senderType'] ?? '',
          content: data['content'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar mensagens: $e');
      return [];
    }
  }

  /// Escuta novas mensagens em tempo real
  static void listenMessages(String chatRoomId, Function(String, MessageModel) onNewMessage) {
    // Remove listener anterior se existir
    _activeSubscriptions[chatRoomId]?.cancel();

    final subscription = _chatRoomsCollection
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final message = MessageModel(
          id: doc.id,
          corridaId: data['corridaId'] ?? '',
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? '',
          senderType: data['senderType'] ?? '',
          content: data['content'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
        );
        onNewMessage(chatRoomId, message);
      }
    });

    _activeSubscriptions[chatRoomId] = subscription;
  }

  /// Para de escutar mensagens
  static void stopListening(String chatRoomId) {
    _activeSubscriptions[chatRoomId]?.cancel();
    _activeSubscriptions.remove(chatRoomId);
  }

  /// Marca mensagens como lidas
  static Future<void> markAsRead(String chatRoomId, String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _chatRoomsCollection
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Erro ao marcar mensagens como lidas: $e');
    }
  }

  /// Lista todas as salas de chat do usuário
  static Future<List<ChatRoomModel>> getUserChatRooms(String userId) async {
    try {
      final querySnapshot = await _chatRoomsCollection
          .where(Filter.or(
            Filter('motoristaId', isEqualTo: userId),
            Filter('empresaId', isEqualTo: userId),
          ))
          .orderBy('lastMessageAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatRoomModel(
          id: doc.id,
          corridaId: data['corridaId'] ?? '',
          motoristaId: data['motoristaId'] ?? '',
          motoristaName: data['motoristaName'] ?? '',
          empresaId: data['empresaId'] ?? '',
          empresaName: data['empresaName'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar salas de chat: $e');
      return [];
    }
  }

  /// Adiciona listener para novas mensagens (compatibilidade)
  static void addMessageListener(Function(String, MessageModel) listener) {
    _messageListeners.add(listener);
  }

  /// Remove listener
  static void removeMessageListener(Function(String, MessageModel) listener) {
    _messageListeners.remove(listener);
  }

  /// Limpa todos os listeners
  static void clear() {
    for (var subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
    _messageListeners.clear();
  }
}
