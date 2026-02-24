import 'dart:convert';
import 'package:dio/dio.dart';

/// Script para criar motorista de teste AGORA
/// Execute com: dart criar_motorista_teste_agora.dart
void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.foolentregas.com.br/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Dados do motorista de teste - usando email diferente para garantir criação
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'motorista.teste.$timestamp@fool.com';
  final senha = '123456';
  final nome = 'Motorista Teste';
  final cpf = '12345678901'; // CPF de teste (sem formatação)
  final placa = 'ABC1234';
  final tipoMoto = 'Honda CG 160';
  final corMoto = 'Vermelha';
  
  // Endereço completo
  final cep = '01310-100';
  final rua = 'Avenida Paulista';
  final numero = '1000';
  final bairro = 'Bela Vista';
  final cidade = 'São Paulo';
  final estado = 'SP';

  print('');
  print('🚀 ==========================================');
  print('🚀 CRIANDO MOTORISTA DE TESTE');
  print('🚀 ==========================================');
  print('');
  print('📧 Email: $email');
  print('🔑 Senha: $senha');
  print('👤 Nome: $nome');
  print('🆔 CPF: $cpf');
  print('🚗 Placa: $placa');
  print('🏍️ Modelo: $tipoMoto');
  print('');

  // Estrutura EXATA conforme o código do app
  final usuarioJson = {
    'usuario': email,
    'desSenha': senha,
    'desNome': nome,
    'indTipo': 1, // Motorista
    'usuarioResp': {
      'usuario': email,
      'senha': senha,
      'reSenha': senha,
      'desNome': nome,
      'tipPerfil': 1, // Motorista
      'motoristas': [
        {
          'desCpfCnpj': cpf,
          'desRazaoSocial': nome,
          'desPlaca': placa,
          'desTipoMoto': tipoMoto,
          'desCorMoto': corMoto,
          // CNH vazia - pode ser que a API aceite sem CNH inicialmente
          'desCarteira': '',
          'desNomeCarteira': '',
          'enderecos': [
            {
              'desCep': cep,
              'desRua': rua,
              'desNumero': numero,
              'desBairro': bairro,
              'desCidade': cidade,
              'desEstado': estado,
              'desPais': 'Brasil',
            }
          ]
        }
      ]
    }
  };

  try {
    print('📤 Enviando requisição para /public/criarUsuario...');
    print('');
    
    final response = await dio.post(
      '/public/criarUsuario',
      data: json.encode(usuarioJson),
    );

    print('✅ Resposta recebida! Status: ${response.statusCode}');
    print('');

    if (response.statusCode == 200) {
      final data = response.data;
      
      // Normaliza para Map
      Map<String, dynamic> jsonData;
      if (data is Map<String, dynamic>) {
        jsonData = data;
      } else if (data is Map) {
        jsonData = Map<String, dynamic>.from(data);
      } else if (data is String) {
        jsonData = json.decode(data) as Map<String, dynamic>;
      } else {
        throw Exception('Formato de resposta inválido');
      }

      final indSucesso = jsonData['indSucesso'];
      
      if (indSucesso == 1) {
        print('');
        print('✅ ==========================================');
        print('✅ CADASTRO REALIZADO COM SUCESSO!');
        print('✅ ==========================================');
        print('');
        print('📋 CREDENCIAIS DE TESTE:');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📧 Email: $email');
        print('🔑 Senha: $senha');
        print('👤 Nome: $nome');
        print('🚗 Placa: $placa');
        print('🏍️ Modelo: $tipoMoto');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('');
        print('💡 Agora você pode fazer login no app!');
        print('');
        
        if (jsonData['codUsuario'] != null) {
          print('🆔 ID do Usuário: ${jsonData['codUsuario']}');
        }
      } else {
        final msgErro = jsonData['desMsgErro'] ?? 'Erro desconhecido';
        print('');
        print('❌ ==========================================');
        print('❌ CADASTRO FALHOU');
        print('❌ ==========================================');
        print('');
        print('📝 Mensagem da API: $msgErro');
        print('');
        
        if (msgErro.toString().toLowerCase().contains('cnh') || 
            msgErro.toString().toLowerCase().contains('carteira')) {
          print('⚠️ A API exige CNH para motoristas.');
          print('');
          print('💡 SOLUÇÃO: Crie o motorista pelo app:');
          print('   1. Abra o app');
          print('   2. Clique em "CADASTRO MOTORISTA"');
          print('   3. Preencha todos os campos');
          print('   4. Anexe uma foto da CNH');
          print('   5. Use as mesmas credenciais:');
          print('      Email: $email');
          print('      Senha: $senha');
        } else if (msgErro.toString().toLowerCase().contains('já existe') || 
                   msgErro.toString().toLowerCase().contains('duplicado')) {
          print('✅ O usuário JÁ EXISTE!');
          print('');
          print('💡 Você pode fazer login com:');
          print('   Email: $email');
          print('   Senha: $senha');
        } else {
          print('💡 Verifique se todos os campos estão corretos.');
          print('   Ou crie pelo app seguindo o GUIA_CRIAR_MOTORISTA.md');
        }
      }
    }
  } on DioException catch (e) {
    print('');
    print('❌ ==========================================');
    print('❌ ERRO NA REQUISIÇÃO');
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
    
    if (e.response?.statusCode == 400) {
      print('💡 Erro de validação. Verifique os dados enviados.');
    } else if (e.response?.statusCode == 409) {
      print('✅ O usuário JÁ EXISTE!');
      print('');
      print('💡 Você pode fazer login com:');
      print('   Email: $email');
      print('   Senha: $senha');
    } else {
      print('💡 Tente criar pelo app (veja GUIA_CRIAR_MOTORISTA.md)');
    }
  } catch (e) {
    print('');
    print('❌ ERRO INESPERADO:');
    print('   $e');
    print('');
    print('💡 Tente criar pelo app (veja GUIA_CRIAR_MOTORISTA.md)');
  }
  
  print('');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');
}

