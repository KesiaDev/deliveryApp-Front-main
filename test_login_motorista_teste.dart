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

  // Credenciais que foram tentadas no app
  final email = 'motorista.teste@fool.com';
  final senha = '123456';

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
      print('❌ O usuário "$email" NÃO EXISTE no banco de dados!');
      print('');
      print('💡 SOLUÇÃO:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('1. Abra o app Flutter');
      print('2. Vá para "CADASTRO MOTORISTA"');
      print('3. Preencha os dados:');
      print('   - Email: $email');
      print('   - Senha: $senha');
      print('   - Nome: Motorista Teste');
      print('   - CPF: 123.456.789-01');
      print('   - Placa: ABC1234');
      print('   - Modelo: Honda CG 160');
      print('   - CEP: 01310-100');
      print('   - Anexe a CNH (obrigatório)');
      print('4. Clique em "ENVIAR"');
      print('5. Depois tente fazer login novamente');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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





