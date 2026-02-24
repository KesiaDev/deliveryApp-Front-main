import 'dart:convert';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/admin_service.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:dio/dio.dart';

class AdminRespository {
  final _dio = Dio(ApiBaseHelper.options);

  Future<List<Empresa>> buscaEmpresas({int codEmpresa = -1}) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";

    Map<String, dynamic>? queryParameters = Map<String, dynamic>();

    final response = await _dio.get("/private/empresa/get");

    //Empresa.fromJson(response.data);

    return response.data
        .map<Empresa>((item) => Empresa.fromJson(item))
        .toList();

    // return empresasFromJson(response.data);
  }

  Future<List<Motorista>> buscaMotoristas({int codEmpresa = -1}) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";

    Map<String, dynamic>? queryParameters = Map<String, dynamic>();

    final response = await _dio.get("/private/motorista/get");

    //Empresa.fromJson(response.data);

    return response.data
        .map<Motorista>((item) => Motorista.fromJson(item))
        .toList();

    // return empresasFromJson(response.data);
  }

  Future<void> atualizaBloqueio(int? codUsuario, int indStatus) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    final response = await _dio.post(
      "/private/user/block/${codUsuario}/$indStatus",
    );

    // final response = await _dio.post("/private/user/${motorista.codUsuario}/atualizarlocal/${desLatitude}/${desLongitude}", data: {
    //   "codMotorista": motorista.codUsuario,
    //   "desLatitude": desLatitude,
    //   "desLongitude": desLongitude,
    // });
    // ignore: deprecated_member_use
  }

  Future<List<ValoresTaxas>> buscaConfigTaxas() async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    // ignore: deprecated_member_use

    final response = await _dio.get("/private/sys/vlrTaxa/findAll");

    return response.data
        .map<ValoresTaxas>((item) => ValoresTaxas.fromJson(item))
        .toList();
  }

  Future<void> saveTaxa(ValoresTaxas config) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    // ignore: deprecated_member_use

    final response = await _dio.post(
      "/private/sys/save",
      data: json.encode(config.toJson()),
    );
  }

  /// Exclui uma empresa permanentemente
  /// Tenta TODAS as variações possíveis de endpoints até conseguir excluir
  /// Retorna true se conseguiu excluir, false caso contrário
  Future<bool> excluirEmpresa(int? codUsuario, int? codEmpresa) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    
    // Lista completa de endpoints possíveis para exclusão (DELETE)
    final deleteEndpoints = <String>[];
    
    if (codUsuario != null) {
      deleteEndpoints.addAll([
        "/private/user/${codUsuario}",
        "/private/user/delete/${codUsuario}",
        "/private/user/remove/${codUsuario}",
        "/private/user/excluir/${codUsuario}",
        "/private/user/${codUsuario}/delete",
        "/private/user/${codUsuario}/remove",
        "/private/user/${codUsuario}/excluir",
        "/private/users/${codUsuario}",
        "/private/users/delete/${codUsuario}",
      ]);
    }
    
    if (codEmpresa != null) {
      deleteEndpoints.addAll([
        "/private/empresa/${codEmpresa}",
        "/private/empresa/delete/${codEmpresa}",
        "/private/empresa/remove/${codEmpresa}",
        "/private/empresa/excluir/${codEmpresa}",
        "/private/empresa/${codEmpresa}/delete",
        "/private/empresa/${codEmpresa}/remove",
        "/private/empresa/${codEmpresa}/excluir",
        "/private/empresas/${codEmpresa}",
        "/private/empresas/delete/${codEmpresa}",
      ]);
    }
    
    // Tenta cada endpoint DELETE
    for (final endpoint in deleteEndpoints) {
      try {
        final response = await _dio.delete(endpoint);
        if (response.statusCode == 200 || 
            response.statusCode == 204 || 
            response.statusCode == 201) {
          return true;
        }
      } catch (e) {
        // Continua tentando outros endpoints
        continue;
      }
    }
    
    // Tenta com POST (algumas APIs usam POST para exclusão)
    final postEndpoints = <String>[];
    
    if (codUsuario != null) {
      postEndpoints.addAll([
        "/private/user/delete/${codUsuario}",
        "/private/user/remove/${codUsuario}",
        "/private/user/excluir/${codUsuario}",
        "/private/user/${codUsuario}/delete",
        "/private/user/${codUsuario}/remove",
        "/private/user/${codUsuario}/excluir",
        "/private/users/delete/${codUsuario}",
      ]);
    }
    
    if (codEmpresa != null) {
      postEndpoints.addAll([
        "/private/empresa/delete/${codEmpresa}",
        "/private/empresa/remove/${codEmpresa}",
        "/private/empresa/excluir/${codEmpresa}",
        "/private/empresa/${codEmpresa}/delete",
        "/private/empresa/${codEmpresa}/remove",
        "/private/empresa/${codEmpresa}/excluir",
        "/private/empresas/delete/${codEmpresa}",
      ]);
    }
    
    for (final endpoint in postEndpoints) {
      try {
        final response = await _dio.post(endpoint);
        if (response.statusCode == 200 || 
            response.statusCode == 204 || 
            response.statusCode == 201) {
          return true;
        }
      } catch (e) {
        continue;
      }
    }
    
    // Tenta com PUT (algumas APIs usam PUT para exclusão)
    if (codUsuario != null) {
      try {
        final response = await _dio.put(
          "/private/user/${codUsuario}",
          data: json.encode({"indExcluido": 1, "indAtivo": 0}),
        );
        if (response.statusCode == 200 || 
            response.statusCode == 204 || 
            response.statusCode == 201) {
          return true;
        }
      } catch (e) {
        // Ignora
      }
    }
    
    if (codEmpresa != null) {
      try {
        final response = await _dio.put(
          "/private/empresa/${codEmpresa}",
          data: json.encode({"indExcluido": 1, "indAtivo": 0}),
        );
        if (response.statusCode == 200 || 
            response.statusCode == 204 || 
            response.statusCode == 201) {
          return true;
        }
      } catch (e) {
        // Ignora
      }
    }
    
    return false;
  }

  /// Exclui um motorista permanentemente
  /// Tenta TODAS as variações possíveis de endpoints até conseguir excluir
  /// Retorna true se conseguiu excluir, false caso contrário
  Future<bool> excluirMotorista(int? codUsuario, int? codMotorista) async {
    _dio.options.headers["Authorization"] =
        "Bearer ${ApiBaseHelper.userSessao!.jwt}";
    
    // Lista completa de endpoints possíveis para exclusão (DELETE)
    final deleteEndpoints = <String>[];
    
    if (codUsuario != null) {
      deleteEndpoints.addAll([
        "/private/user/${codUsuario}",
        "/private/user/delete/${codUsuario}",
        "/private/user/remove/${codUsuario}",
        "/private/user/excluir/${codUsuario}",
        "/private/user/${codUsuario}/delete",
        "/private/user/${codUsuario}/remove",
        "/private/user/${codUsuario}/excluir",
        "/private/users/${codUsuario}",
        "/private/users/delete/${codUsuario}",
      ]);
    }
    
    if (codMotorista != null) {
      deleteEndpoints.addAll([
        "/private/motorista/${codMotorista}",
        "/private/motorista/delete/${codMotorista}",
        "/private/motorista/remove/${codMotorista}",
        "/private/motorista/excluir/${codMotorista}",
        "/private/motorista/${codMotorista}/delete",
        "/private/motorista/${codMotorista}/remove",
        "/private/motorista/${codMotorista}/excluir",
        "/private/motoristas/${codMotorista}",
        "/private/motoristas/delete/${codMotorista}",
      ]);
    }
    
    // Tenta cada endpoint DELETE
    for (final endpoint in deleteEndpoints) {
      try {
        final response = await _dio.delete(endpoint);
        if (response.statusCode == 200 || 
            response.statusCode == 204 || 
            response.statusCode == 201) {
          return true;
        }
      } catch (e) {
        // Continua tentando outros endpoints
        continue;
      }
    }
    
    // Tenta com POST (algumas APIs usam POST para exclusão)
    final postEndpoints = <String>[];
    
    if (codUsuario != null) {
      postEndpoints.addAll([
        "/private/user/delete/${codUsuario}",
        "/private/user/remove/${codUsuario}",
        "/private/user/excluir/${codUsuario}",
        "/private/user/${codUsuario}/delete",
        "/private/user/${codUsuario}/remove",
        "/private/user/${codUsuario}/excluir",
        "/private/users/delete/${codUsuario}",
      ]);
    }
    
    if (codMotorista != null) {
      postEndpoints.addAll([
        "/private/motorista/delete/${codMotorista}",
        "/private/motorista/remove/${codMotorista}",
        "/private/motorista/excluir/${codMotorista}",
        "/private/motorista/${codMotorista}/delete",
        "/private/motorista/${codMotorista}/remove",
        "/private/motorista/${codMotorista}/excluir",
        "/private/motoristas/delete/${codMotorista}",
      ]);
    }
    
    for (final endpoint in postEndpoints) {
      try {
        final response = await _dio.post(endpoint);
        if (response.statusCode == 200 || 
            response.statusCode == 204 || 
            response.statusCode == 201) {
          return true;
        }
      } catch (e) {
        continue;
      }
    }
    
    // Tenta com PUT (algumas APIs usam PUT para exclusão)
    if (codUsuario != null) {
      try {
        final response = await _dio.put(
          "/private/user/${codUsuario}",
          data: json.encode({"indExcluido": 1, "indAtivo": 0}),
        );
        if (response.statusCode == 200 || 
            response.statusCode == 204 || 
            response.statusCode == 201) {
          return true;
        }
      } catch (e) {
        // Ignora
      }
    }
    
    if (codMotorista != null) {
      try {
        final response = await _dio.put(
          "/private/motorista/${codMotorista}",
          data: json.encode({"indExcluido": 1, "indAtivo": 0}),
        );
        if (response.statusCode == 200 || 
            response.statusCode == 204 || 
            response.statusCode == 201) {
          return true;
        }
      } catch (e) {
        // Ignora
      }
    }
    
    return false;
  }
}
