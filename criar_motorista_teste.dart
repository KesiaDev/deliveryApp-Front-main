import 'dart:convert';
import 'package:dio/dio.dart';

/// Script para criar um novo motorista de teste
/// Execute com: dart criar_motorista_teste.dart
/// 
/// Este script cria um novo motorista na API para testes
void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.foolentregas.com.br/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Dados do novo motorista de teste
  final email = 'motorista.teste@fool.com';
  final senha = '123456';
  final nome = 'Motorista Teste';
  final cpf = '12345678901'; // CPF de teste (11 dígitos)
  final placa = 'ABC1234';
  final modelo = 'Honda CG 160';
  
  // Endereço de teste
  final cep = '01310-100';
  final rua = 'Avenida Paulista';
  final numero = '1000';
  final bairro = 'Bela Vista';
  final cidade = 'São Paulo';
  final estado = 'SP';
  final pais = 'Brasil';

  print('🚀 Criando novo motorista de teste...');
  print('📧 Email: $email');
  print('🔑 Senha: $senha');
  print('👤 Nome: $nome');
  print('');

  // Monta o JSON conforme a estrutura esperada pela API
  final usuarioJson = {
    'usuario': email,
    'desSenha': senha,
    'desNome': nome,
    'indTipo': 1, // 1 = Motorista
    'usuarioResp': {
      'usuario': email,
      'senha': senha,
      'reSenha': senha,
      'desNome': nome,
      'tipPerfil': 1, // 1 = Motorista
      'motoristas': [
        {
          'desCpfCnpj': cpf,
          'desRazaoSocial': nome,
          'desPlaca': placa,
          'desModelo': modelo,
          'enderecos': [
            {
              'desCep': cep,
              'desRua': rua,
              'desNumero': numero,
              'desBairro': bairro,
              'desCidade': cidade,
              'desEstado': estado,
              'desPais': pais,
            }
          ]
        }
      ]
    }
  };

  try {
    print('📤 Enviando requisição para /public/criarUsuario...');
    print('📦 JSON sendo enviado:');
    print(json.encode(usuarioJson));
    print('');
    
    final response = await dio.post(
      '/public/criarUsuario',
      data: json.encode(usuarioJson),
    );

    print('✅ Resposta recebida!');
    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Data:');
    print(json.encode(response.data));
    print('');
    
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map) {
        final indSucesso = data['indSucesso'];
        if (indSucesso == 1) {
          print('✅ CADASTRO BEM-SUCEDIDO!');
          print('👤 Usuário criado com sucesso!');
          print('');
          print('📋 CREDENCIAIS DE TESTE:');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('📧 Email: $email');
          print('🔑 Senha: $senha');
          print('👤 Nome: $nome');
          print('🚗 Placa: $placa');
          print('🏍️ Modelo: $modelo');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('');
          print('💡 Agora você pode fazer login com essas credenciais!');
          
          if (data['codUsuario'] != null) {
            print('🆔 CodUsuario: ${data['codUsuario']}');
          }
        } else {
          final msgErro = data['desMsgErro'] ?? 'Erro desconhecido';
          print('❌ CADASTRO FALHOU!');
          print('📝 Mensagem: $msgErro');
          print('');
          if (msgErro.toString().contains('já existe') || 
              msgErro.toString().contains('duplicado')) {
            print('💡 O usuário já existe. Tente com outro email.');
          }
        }
      }
    }
  } on DioException catch (e) {
    print('');
    print('❌ ERRO na requisição!');
    print('📊 Status Code: ${e.response?.statusCode}');
    print('📦 Response Data: ${e.response?.data}');
    
    if (e.response?.statusCode == 400) {
      print('');
      print('🔴 ERRO DE VALIDAÇÃO');
      print('Verifique se todos os campos estão preenchidos corretamente.');
    } else if (e.response?.statusCode == 409) {
      print('');
      print('🔴 USUÁRIO JÁ EXISTE');
      print('O email $email já está cadastrado. Tente com outro email.');
    } else {
      print('');
      print('⚠️ Erro diferente:');
      print('Tipo: ${e.type}');
      print('Mensagem: ${e.message}');
    }
  } catch (e) {
    print('');
    print('❌ ERRO INESPERADO:');
    print(e.toString());
  }
}





