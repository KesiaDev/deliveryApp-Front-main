/// Script para testar login do admin
/// Execute com: dart test_admin_login.dart

import 'dart:convert';
import 'dart:io';

void main() async {
  final email = 'liocer123@admin';
  final senha = '1234';

  print('🔍 Testando login do admin...');
  print('📧 Email: $email');
  print('🔑 Senha: $senha');
  print('');

  try {
    final client = HttpClient();
    final uri = Uri.parse('https://api.foolentregas.com.br/v1/public/login');
    
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    
    final body = json.encode({
      'username': email,
      'password': senha,
      'desTokenFcm': null,
      'indLogado': false,
    });
    
    print('📤 Enviando requisição...');
    
    request.write(body);
    final response = await request.close();
    
    print('📥 Status Code: ${response.statusCode}');
    print('');
    
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      print('✅ Login bem-sucedido!');
      print('   - codUsuario: ${data['codUsuario']}');
      print('   - tipPerfil: ${data['tipPerfil']} (1=Motorista, 2=Empresa, 99=Admin)');
    } else {
      print('❌ Login falhou!');
      print('   Resposta: $responseBody');
    }
    
    client.close();
  } catch (e) {
    print('❌ Erro: $e');
  }
}





