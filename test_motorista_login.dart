import 'dart:convert';
import 'package:dio/dio.dart';

/// Script temporário para testar login do motorista
/// Execute com: dart test_motorista_login.dart
/// 
/// Este script testa se o usuário motorista1@testeadmin existe na API
void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.foolentregas.com.br/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Credenciais do motorista
  final email = 'motorista1@testeadmin';
  final senha = '123';

  print('🔍 Testando login do motorista...');
  print('📧 Email: $email');
  print('🔑 Senha: $senha');
  print('');

  try {
    print('📤 Enviando requisição para /public/login...');
    
    final response = await dio.post(
      '/public/login',
      data: json.encode({
        'username': email,
        'password': senha,
        'desTokenFcm': null,
        'indLogado': false,
      }),
    );

    print('✅ Resposta recebida!');
    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Data:');
    print(json.encode(response.data));
    
    if (response.statusCode == 200) {
      print('');
      print('✅ LOGIN BEM-SUCEDIDO!');
      print('👤 Usuário existe e credenciais estão corretas.');
      
      if (response.data is Map) {
        final data = response.data as Map;
        print('🆔 CodUsuario: ${data['codUsuario']}');
        print('👤 Nome: ${data['desNome']}');
        print('📧 Email: ${data['usuario']}');
        print('🔑 Tipo: ${data['tipPerfil']} (1=Motorista, 2=Empresa, 99=Admin)');
        print('🎫 JWT presente: ${data['jwt'] != null ? 'Sim' : 'Não'}');
      }
    }
  } on DioException catch (e) {
    print('');
    print('❌ ERRO na requisição!');
    print('📊 Status Code: ${e.response?.statusCode}');
    print('📦 Response Data: ${e.response?.data}');
    
    if (e.response?.statusCode == 401) {
      print('');
      print('🔴 USUÁRIO OU SENHA INCORRETOS');
      print('');
      print('Possíveis causas:');
      print('1. O usuário não existe no banco de dados');
      print('2. A senha está incorreta');
      print('3. O email está incorreto');
      print('4. O usuário pode estar bloqueado');
      print('');
      print('💡 Sugestões:');
      print('- Verifique se o usuário existe no banco de dados');
      print('- Confirme a senha correta');
      print('- Teste com outras credenciais conhecidas');
    } else {
      print('');
      print('⚠️ Erro diferente de 401:');
      print('Tipo: ${e.type}');
      print('Mensagem: ${e.message}');
    }
  } catch (e) {
    print('');
    print('❌ ERRO INESPERADO:');
    print(e.toString());
  }
}





