import '../models/rating_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Serviço de avaliações integrado com Firebase Firestore
class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _ratingsCollection = _firestore.collection('ratings');

  /// Envia uma avaliação
  static Future<RatingModel> submitRating({
    required String corridaId,
    required String avaliadorId,
    required String avaliadorName,
    required String avaliadorType,
    required String avaliadoId,
    required String avaliadoName,
    required String avaliadoType,
    required int rating,
    String? comment,
  }) async {
    try {
      // Verifica se já existe avaliação para esta corrida deste avaliador
      final existingRating = await getCorridaRating(corridaId, avaliadorId);
      if (existingRating != null) {
        // Atualiza avaliação existente
        await _ratingsCollection.doc(existingRating.id).update({
          'rating': rating,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        return RatingModel(
          id: existingRating.id,
          corridaId: corridaId,
          avaliadorId: avaliadorId,
          avaliadorName: avaliadorName,
          avaliadorType: avaliadorType,
          avaliadoId: avaliadoId,
          avaliadoName: avaliadoName,
          avaliadoType: avaliadoType,
          rating: rating,
          comment: comment,
          createdAt: DateTime.now(),
        );
      }

      // Cria nova avaliação
      final ratingData = {
        'corridaId': corridaId,
        'avaliadorId': avaliadorId,
        'avaliadorName': avaliadorName,
        'avaliadorType': avaliadorType,
        'avaliadoId': avaliadoId,
        'avaliadoName': avaliadoName,
        'avaliadoType': avaliadoType,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _ratingsCollection.add(ratingData);

      final newRating = RatingModel(
        id: docRef.id,
        corridaId: corridaId,
        avaliadorId: avaliadorId,
        avaliadorName: avaliadorName,
        avaliadorType: avaliadorType,
        avaliadoId: avaliadoId,
        avaliadoName: avaliadoName,
        avaliadoType: avaliadoType,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      // Envia notificação push para o usuário avaliado
      await _sendRatingNotification(newRating);

      return newRating;
    } catch (e) {
      debugPrint('Erro ao enviar avaliação: $e');
      rethrow;
    }
  }

  /// Envia notificação push quando uma avaliação é recebida
  static Future<void> _sendRatingNotification(RatingModel rating) async {
    try {
      // Busca o token FCM do usuário avaliado no Firestore
      // Estrutura: /users/{userId}/fcmToken
      final userDoc = await _firestore
          .collection('users')
          .doc(rating.avaliadoId)
          .get();

      if (!userDoc.exists) {
        debugPrint('Usuário não encontrado para notificação: ${rating.avaliadoId}');
        return;
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('Token FCM não encontrado para usuário: ${rating.avaliadoId}');
        return;
      }

      // Em produção, isso seria feito via Cloud Functions ou backend
      // Aqui está a estrutura para referência
      debugPrint('📬 Enviando notificação de avaliação para: ${rating.avaliadoName}');
      debugPrint('📬 Token FCM: $fcmToken');
      debugPrint('📬 Nota: ${rating.rating} estrelas');

      // TODO: Integrar com Cloud Functions ou backend para enviar push notification
      // Exemplo de payload:
      // {
      //   "to": fcmToken,
      //   "notification": {
      //     "title": "Nova Avaliação Recebida!",
      //     "body": "${rating.avaliadorName} te avaliou com ${rating.rating} estrelas"
      //   },
      //   "data": {
      //     "type": "rating",
      //     "ratingId": rating.id,
      //     "corridaId": rating.corridaId,
      //     "avaliadorId": rating.avaliadorId,
      //   }
      // }
    } catch (e) {
      debugPrint('Erro ao enviar notificação de avaliação: $e');
      // Não bloqueia o fluxo se houver erro na notificação
    }
  }

  /// Busca avaliações de um usuário
  static Future<List<RatingModel>> getUserRatings(String userId) async {
    try {
      final querySnapshot = await _ratingsCollection
          .where('avaliadoId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RatingModel.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
        });
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar avaliações: $e');
      return [];
    }
  }

  /// Busca avaliação de uma corrida específica
  static Future<RatingModel?> getCorridaRating(
    String corridaId,
    String avaliadorId,
  ) async {
    try {
      final querySnapshot = await _ratingsCollection
          .where('corridaId', isEqualTo: corridaId)
          .where('avaliadorId', isEqualTo: avaliadorId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      
      return RatingModel.fromJson({
        'id': doc.id,
        ...data,
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Erro ao buscar avaliação da corrida: $e');
      return null;
    }
  }

  /// Verifica se já existe avaliação para uma corrida
  static Future<bool> hasRated(String corridaId, String avaliadorId) async {
    final rating = await getCorridaRating(corridaId, avaliadorId);
    return rating != null;
  }

  /// Calcula estatísticas de avaliação de um usuário
  static Future<RatingStats> getUserRatingStats(String userId) async {
    final userRatings = await getUserRatings(userId);
    return RatingStats.fromRatings(userRatings);
  }

  /// Limpa dados (útil para testes)
  static void clear() {
    // Não limpa Firestore em produção, apenas para testes locais
    debugPrint('⚠️ clear() chamado - não limpa Firestore');
  }
}





