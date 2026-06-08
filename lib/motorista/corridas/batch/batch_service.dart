import 'dart:convert';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/motorista/corridas/batch/batch_group_model.dart';

class BatchService {
  static String get _base => '${ApiBaseHelper.baseUrl}/batch';

  /// Busca candidatos de agrupamento para a corrida indicada.
  static Future<List<BatchGroupModel>> buscarCandidatos(int corridaId) async {
    try {
      final res = await ApiBaseHelper.dio.get('$_base/candidatos/$corridaId');
      final data = res.data as List<dynamic>;
      return data
          .map((e) => BatchGroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Cria grupo confirmado (motorista aceitou a oferta de batch).
  static Future<bool> criarGrupo({
    required int corridaPrincipalId,
    required int corridaSecundariaId,
    required int motoristaId,
  }) async {
    try {
      final res = await ApiBaseHelper.dio.post('$_base/criar', data: {
        'corridaPrincipalId': corridaPrincipalId,
        'corridaSecundariaId': corridaSecundariaId,
        'motoristaId': motoristaId,
      });
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Rejeita oferta de batch (motorista prefere entrega simples).
  static Future<void> rejeitarGrupo(int groupId) async {
    try {
      await ApiBaseHelper.dio.put('$_base/$groupId/rejeitar',
          data: {'motivo': 'rejeitado pelo motorista'});
    } catch (_) {}
  }

  /// Marca item individual como entregue.
  static Future<bool> marcarEntregue(int groupId, int itemId) async {
    try {
      final res = await ApiBaseHelper.dio
          .put('$_base/$groupId/items/$itemId/entregar');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Busca grupos ativos do motorista.
  static Future<List<BatchGroupModel>> buscarAtivos(int motoristaId) async {
    try {
      final res = await ApiBaseHelper.dio
          .get('$_base/ativos', queryParameters: {'motoristaId': motoristaId});
      final data = res.data as List<dynamic>;
      return data
          .map((e) => BatchGroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
