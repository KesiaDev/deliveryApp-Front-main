import 'dart:io';

import 'package:delivery_front/shared/models/CNPJ.dart';
import 'package:dio/dio.dart';

/// Serviço para consulta de CNPJ na API BrasilAPI
/// https://brasilapi.com.br/api/cnpj/v1/{cnpj}
/// 
/// Segue o mesmo padrão do ViaCepService para manter consistência
class CnpjService {
  static BaseOptions options = BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      HttpHeaders.contentTypeHeader: "application/json",
    },
  );

  static Dio dio = Dio(options);

  /// Busca dados do CNPJ na BrasilAPI
  /// 
  /// [cnpj] deve conter apenas números (14 dígitos)
  /// Retorna CnpjResponse com os dados da empresa
  /// 
  /// Lança Exception se a requisição falhar
  static Future<CnpjResponse> fetchCnpj({required String cnpj}) async {
    // Remove formatação do CNPJ (pontos, barras, hífens)
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cnpjLimpo.length != 14) {
      throw Exception('CNPJ deve conter 14 dígitos');
    }

    String url = "https://brasilapi.com.br/api/cnpj/v1/$cnpjLimpo";
    
    try {
      final response = await dio.get(url);
      
      if (response.statusCode == 200) {
        return CnpjResponse.fromJson(response.data);
      } else {
        throw Exception('CNPJ não encontrado ou inválido');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('CNPJ não encontrado');
      } else if (e.response?.statusCode == 400) {
        throw Exception('CNPJ inválido');
      } else {
        throw Exception('Erro ao consultar CNPJ: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro ao consultar CNPJ: $e');
    }
  }
}

