/// Script para testar login da empresa empresa@admin
/// Execute com: dart test_empresa_login.dart

import 'dart:convert';
import 'dart:io';

void main() async {
  final email = 'empresa@admin';
  final senha = '123';

  print('🔍 Testando login da empresa...');
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
    print('📤 Body: $body');
    print('');
    
    request.write(body);
    final response = await request.close();
    
    print('📥 Status Code: ${response.statusCode}');
    print('📥 Headers: ${response.headers}');
    print('');
    
    final responseBody = await response.transform(utf8.decoder).join();
    print('📥 Response Body:');
    print(responseBody);
    print('');
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      
      print('✅ Login bem-sucedido!');
      print('');
      print('📊 Dados recebidos:');
      print('   - JWT: ${data['jwt'] != null ? "Presente (${data['jwt'].toString().substring(0, 20)}...)" : "Ausente"}');
      print('   - codUsuario: ${data['codUsuario']}');
      print('   - usuario: ${data['usuario']}');
      print('   - desNome: ${data['desNome']}');
      print('   - tipPerfil: ${data['tipPerfil']} (1=Motorista, 2=Empresa, 99=Admin)');
      print('   - indSucesso: ${data['indSucesso']}');
      print('   - desMsgErro: ${data['desMsgErro']}');
      
      if (data['usuarioResp'] != null) {
        print('   - usuarioResp: Presente');
        if (data['usuarioResp']['empresas'] != null) {
          print('   - empresas: ${data['usuarioResp']['empresas'].length} encontrada(s)');
        }
      } else {
        print('   - usuarioResp: Ausente ⚠️');
      }
    } else {
      print('❌ Login falhou!');
      print('   Status Code: ${response.statusCode}');
      
      try {
        final errorData = json.decode(responseBody);
        print('   Mensagem: ${errorData['message'] ?? errorData['mensagem'] ?? errorData['error'] ?? responseBody}');
      } catch (e) {
        print('   Resposta: $responseBody');
      }
    }
    
    client.close();
  } catch (e) {
    print('❌ Erro ao fazer requisição:');
    print('   $e');
  }
}





