/// Script para bloquear/excluir todos os clientes (empresas) cadastrados
/// 
/// IMPORTANTE: Este script bloqueia todas as empresas (indBloqueado = 1)
/// Para executar, você precisa estar logado como ADMIN no app
/// 
/// Execute com: dart excluir_todos_clientes.dart

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  print('🚨 ATENÇÃO: Este script irá BLOQUEAR todas as empresas/clientes cadastradas!');
  print('⚠️  Certifique-se de que você tem permissão de ADMIN');
  print('');
  
  // Credenciais do admin
  final adminEmail = 'liocer123@admin';
  final adminSenha = '1234';
  
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.foolentregas.com.br/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  try {
    // 1. Fazer login como admin
    print('📤 Fazendo login como admin...');
    final loginResponse = await dio.post(
      '/public/login',
      data: json.encode({
        'username': adminEmail,
        'password': adminSenha,
        'desTokenFcm': null,
        'indLogado': false,
      }),
    );

    if (loginResponse.statusCode != 200) {
      print('❌ Erro ao fazer login: ${loginResponse.statusCode}');
      return;
    }

    final jwt = loginResponse.data['jwt'] as String?;
    if (jwt == null) {
      print('❌ JWT não recebido no login');
      return;
    }

    print('✅ Login realizado com sucesso!');
    print('');

    // 2. Buscar todas as empresas
    print('📤 Buscando todas as empresas cadastradas...');
    dio.options.headers['Authorization'] = 'Bearer $jwt';
    
    final empresasResponse = await dio.get('/private/empresa/get');
    
    if (empresasResponse.statusCode != 200) {
      print('❌ Erro ao buscar empresas: ${empresasResponse.statusCode}');
      return;
    }

    final empresas = empresasResponse.data as List;
    print('✅ Encontradas ${empresas.length} empresa(s) cadastrada(s)');
    print('');

    if (empresas.isEmpty) {
      print('ℹ️  Nenhuma empresa encontrada para bloquear.');
      return;
    }

    // 3. Listar empresas encontradas
    print('📋 Empresas encontradas:');
    for (var i = 0; i < empresas.length; i++) {
      final empresa = empresas[i];
      final codUsuario = empresa['user']?['codUsuario'] ?? empresa['codUsuario'];
      final nome = empresa['desNomeFantasia'] ?? empresa['desRazaoSocial'] ?? 'Sem nome';
      final email = empresa['user']?['usuario'] ?? 'Sem email';
      final bloqueado = empresa['user']?['indBloqueado'] == 1 ? 'BLOQUEADO' : 'ATIVO';
      
      print('  ${i + 1}. $nome ($email) - Status: $bloqueado');
    }
    print('');

    // 4. Confirmar ação
    print('⚠️  Você está prestes a BLOQUEAR ${empresas.length} empresa(s)');
    print('Digite "CONFIRMAR" para continuar ou qualquer outra coisa para cancelar:');
    
    final confirmacao = stdin.readLineSync();
    
    if (confirmacao?.toUpperCase() != 'CONFIRMAR') {
      print('❌ Operação cancelada pelo usuário.');
      return;
    }

    // 5. Bloquear todas as empresas
    print('');
    print('🔄 Bloqueando empresas...');
    int sucesso = 0;
    int erros = 0;

    for (var i = 0; i < empresas.length; i++) {
      final empresa = empresas[i];
      final codUsuario = empresa['user']?['codUsuario'] ?? empresa['codUsuario'];
      final nome = empresa['desNomeFantasia'] ?? empresa['desRazaoSocial'] ?? 'Empresa ${i + 1}';
      
      if (codUsuario == null) {
        print('  ⚠️  Empresa "$nome" não tem codUsuario, pulando...');
        erros++;
        continue;
      }

      try {
        // Bloquear empresa (indStatus = 1 significa bloqueado)
        await dio.post(
          '/private/user/block/$codUsuario/1',
        );
        
        print('  ✅ Bloqueada: $nome (codUsuario: $codUsuario)');
        sucesso++;
      } catch (e) {
        print('  ❌ Erro ao bloquear "$nome": $e');
        erros++;
      }
    }

    print('');
    print('📊 Resumo:');
    print('  ✅ Bloqueadas com sucesso: $sucesso');
    print('  ❌ Erros: $erros');
    print('  📦 Total processadas: ${empresas.length}');
    print('');
    print('✅ Processo concluído!');

  } on DioException catch (e) {
    print('');
    print('❌ Erro na requisição:');
    if (e.response != null) {
      print('   Status: ${e.response!.statusCode}');
      print('   Mensagem: ${e.response!.data}');
    } else {
      print('   ${e.message}');
    }
  } catch (e, stackTrace) {
    print('');
    print('❌ Erro inesperado: $e');
    print('Stack trace: $stackTrace');
  }
}


