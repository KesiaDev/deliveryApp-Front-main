import 'dart:convert';
import 'package:dio/dio.dart';

/// Script para testar login do motorista.teste@fool.com
void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.foolentregas.com.br/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  final email = 'motorista.teste@fool.com';
  final senha = '123456';

  print('');
  print('🔍 ==========================================');
  print('🔍 TESTANDO LOGIN DO MOTORISTA');
  print('🔍 ==========================================');
  print('');
  print('📧 Email: $email');
  print('🔑 Senha: $senha');
  print('');

  final loginJson = {
    'username': email,
    'password': senha,
    'desTokenFcm': null,
    'indLogado': false,
  };

  try {
    print('📤 Enviando requisição de login...');
    print('');
    
    final response = await dio.post(
      '/public/login',
      data: json.encode(loginJson),
    );

    print('✅ Resposta recebida! Status: ${response.statusCode}');
    print('');

    if (response.statusCode == 200) {
      final data = response.data;
      
      Map<String, dynamic> jsonData;
      if (data is Map<String, dynamic>) {
        jsonData = data;
      } else if (data is Map) {
        jsonData = Map<String, dynamic>.from(data);
      } else if (data is String) {
        jsonData = json.decode(data) as Map<String, dynamic>;
      } else {
        throw Exception('Formato inválido');
      }

      print('✅ ==========================================');
      print('✅ LOGIN FUNCIONOU!');
      print('✅ ==========================================');
      print('');
      print('📋 DADOS DO USUÁRIO:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🆔 ID: ${jsonData['codUsuario'] ?? 'N/A'}');
      print('👤 Nome: ${jsonData['desNome'] ?? 'N/A'}');
      print('📧 Email: ${jsonData['usuario'] ?? 'N/A'}');
      print('👥 Tipo: ${jsonData['tipPerfil'] ?? 'N/A'} (1=Motorista)');
      print('🔐 JWT: ${jsonData['jwt'] != null ? 'Recebido ✅' : 'Não recebido ❌'}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      print('💡 CREDENCIAIS VÁLIDAS PARA LOGIN:');
      print('   Email: $email');
      print('   Senha: $senha');
      print('');
    }
  } on DioException catch (e) {
    print('');
    print('❌ ==========================================');
    print('❌ LOGIN FALHOU');
    print('❌ ==========================================');
    print('');
    print('📊 Status Code: ${e.response?.statusCode}');
    
    if (e.response?.data != null) {
      print('📦 Response:');
      try {
        final errorData = e.response!.data;
        if (errorData is Map) {
          print('   ${json.encode(errorData)}');
        } else {
          print('   $errorData');
        }
      } catch (_) {
        print('   ${e.response!.data}');
      }
    }
    
    print('');
    
    if (e.response?.statusCode == 401) {
      print('❌ Usuário ou senha incorretos!');
      print('');
      print('💡 POSSÍVEIS CAUSAS:');
      print('   1. A senha não é "123456"');
      print('   2. O email está incorreto');
      print('   3. O usuário pode estar bloqueado');
      print('');
      print('💡 SOLUÇÕES:');
      print('   - Tente resetar a senha pelo app');
      print('   - Ou crie um novo motorista com outro email');
      print('   - Ou verifique com o admin se o usuário está ativo');
    } else {
      print('💡 Erro diferente. Verifique a conexão com a API.');
    }
  } catch (e) {
    print('');
    print('❌ ERRO INESPERADO:');
    print('   $e');
  }
  
  print('');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');
}

