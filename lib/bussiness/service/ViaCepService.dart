import 'dart:io';

import 'package:delivery_front/shared/models/CEP.dart';
import 'package:dio/dio.dart';

class ViaCepService {
  static BaseOptions options = BaseOptions(
    connectTimeout: const Duration(seconds: 50),
    headers: {
      HttpHeaders.contentTypeHeader: "application/json",
    },
  );

  static Dio dio = Dio(options);

  static Future<ResultCep> fetchCep({required String cep}) async {
    String url = "https://viacep.com.br/ws/$cep/json/";
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      return ResultCep.fromJson(response.data);
    } else {
      throw Exception('Requisição inválida!');
    }
  }
}
