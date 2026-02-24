import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/shared/components/customException.dart';
import 'package:delivery_front/shared/components/loading_dialog.dart';
import 'package:delivery_front/shared/models/cadastroCemRequest.dart';
import 'package:delivery_front/shared/models/loginRequest.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class CadastroController {
  final BuildContext context;

  UserService _userService = new UserService();

  CadastroController(this.context);

  String email = "";
  String senha = "";
  String nome = "";
  String emailMotoristaAmigo = "";
  int indTipo = 1;
  int indTipoPagina = 1;

  //db_motoristas
  String cpf = "";
  String des_placa = "";
  String des_modelo = "";

  //db_enderecos
  String desCep = "";
  String desRua = "";
  String desNumero = "";
  String desCidade = "";
  String desEstado = "";
  String desBairro = "";
  String desCarteiraBase64 = "";
  String desNomeCarteira = "";
  String desCartaoBae64 = "";
  String desNomeCartao = "";
  String desFotoPerfilBase64 = "";
  String desTipoMoto = "";
  String desCorMoto = "";

  void setEmail(String s) => email = s;
  void setSenha(String s) => senha = s;
  void setNome(String s) => nome = s;
  void setEmailMotoristaAmigo(String s) => emailMotoristaAmigo = s;

  void setDesCarteiraBase64(String s) => desCarteiraBase64 = s;
  void setDesNomeCarteira(String s) => desNomeCarteira = s;
  void setDesCartaoBae64(String s) => desCartaoBae64 = s;
  void setDesNomeCartao(String s) => desNomeCartao = s;
  void setDesFotoPerfilBase64(String s) => desFotoPerfilBase64 = s;
  void setDesTipoMoto(String s) => desTipoMoto = s;
  void setDesCorMoto(String s) => desCorMoto = s;

  void setCpf(String s) => cpf = s;
  void setDesPlaca(String s) => des_placa = s;
  void desModelo(String s) => des_modelo = s;

  //db_enderecos
  void setDesCep(String s) => desCep = s;
  void setDesRua(String s) => desRua = s;
  void setDesNumero(String s) => desNumero = s;
  void setDesCidade(String s) => desCidade = s;
  void setDesEstado(String s) => desEstado = s;
  void setDesBairro(String s) => desBairro = s;

  CadastroCemRequest get credential2 => CadastroCemRequest(
      email: email,
      senha: senha,
      emailMotoristaAmigo: emailMotoristaAmigo,
      nome: nome);

  Future<void> registraCem(int indTipoProcesso) async {
    try {
      DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));

      // Normaliza email para lowercase e trim para garantir consistência
      final emailNormalizado = email.trim().toLowerCase();
      print('🟢 [CADASTRO_CONTROLLER] Criando UsuarioResp...');
      print('🟢 [CADASTRO_CONTROLLER] Email normalizado: $emailNormalizado');
      print('🟢 [CADASTRO_CONTROLLER] Nome: $nome');
      print('🟢 [CADASTRO_CONTROLLER] Tipo: $indTipo');
      
      UsuarioResp res = UsuarioResp(
          desNome: nome,
          reSenha: senha,
          senha: senha,
          tipPerfil: indTipo,
          usuario: emailNormalizado);

      if (indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
        Motorista moto = new Motorista();
        if (indTipoProcesso == 2) {
          moto = ApiBaseHelper.userSessao!.usuarioResp!.motoristas!.first;
          moto.desCpfCnpj = cpf;
          moto.desRazaoSocial = nome;
          moto.desPlaca = des_placa;

          if (desCarteiraBase64 != null && desCarteiraBase64.isNotEmpty)
            moto.desCarteira = desCarteiraBase64;
          if (desNomeCarteira != null && desNomeCarteira.isNotEmpty)
            moto.desNomeCarteira = desNomeCarteira;
          if (desCartaoBae64 != null && desCartaoBae64.isNotEmpty)
            moto.desCartao = desCartaoBae64;
          if (desNomeCartao != null && desNomeCartao.isNotEmpty)
            moto.desNomeCartao = desNomeCartao;
          if (desFotoPerfilBase64 != null && desFotoPerfilBase64.isNotEmpty)
            moto.desFotoPerfil = desFotoPerfilBase64;
          if (desTipoMoto != null && desTipoMoto.isNotEmpty)
            moto.desTipoMoto = desTipoMoto;
          if (desCorMoto != null && desCorMoto.isNotEmpty)
            moto.desCorMoto = desCorMoto;
        } else {
          moto = Motorista(
              desCpfCnpj: cpf, desRazaoSocial: nome, desPlaca: des_placa);
          moto.desCarteira = desCarteiraBase64;
          moto.desNomeCarteira = desNomeCarteira;
          moto.desCartao = desCartaoBae64;
          moto.desNomeCartao = desNomeCartao;
          moto.desFotoPerfil = desFotoPerfilBase64;
          moto.desTipoMoto = desTipoMoto;
          moto.desCorMoto = desCorMoto;
        }

        List<Motorista> listMoto = <Motorista>[];
        listMoto.add(moto);
        res.motoristas = listMoto;

        Endereco end = Endereco();

        if (indTipoProcesso == 2) {
          end = ApiBaseHelper
              .userSessao!.usuarioResp!.motoristas!.first.enderecos!.first;
          end.desBairro = desBairro;
          end.desCep = desCep;
          end.desCidade = desCidade;
          end.desEstado = desEstado;
          end.desNumero = desNumero;
          end.desPais = "Brasil";
          end.desRua = desRua;
        } else {
          end = Endereco(
              desBairro: desBairro,
              desCep: desCep,
              desCidade: desCidade,
              desEstado: desEstado,
              desNumero: desNumero,
              desPais: "Brasil",
              desRua: desRua);
        }

        List<Endereco> listEnderecos = <Endereco>[];
        listEnderecos.add(end);

        moto.enderecos = listEnderecos;
      } else {
        Empresa empre = new Empresa();
        if (indTipoProcesso == 2) {
          empre = ApiBaseHelper.userSessao!.usuarioResp!.empresas!.first;
          empre.desCpfCnpj = cpf;
          empre.desRazaoSocial = nome;
          empre.desNomeFantasia = nome;
          if (desCartaoBae64 != null && desCartaoBae64.isNotEmpty)
            empre.desCartao = desCartaoBae64;
          if (desNomeCartao != null && desNomeCartao.isNotEmpty)
            empre.desNomeCartao = desNomeCartao;
        } else {
          empre = Empresa(
              desCpfCnpj: cpf, desRazaoSocial: nome, desNomeFantasia: nome);
          empre.desCartao = desCartaoBae64;
          empre.desNomeCartao = desNomeCartao;
        }

        List<Empresa> listEmpre = <Empresa>[];
        listEmpre.add(empre);
        res.empresas = listEmpre;

        Endereco end = Endereco();

        if (indTipoProcesso == 2) {
          end = ApiBaseHelper
              .userSessao!.usuarioResp!.empresas!.first.enderecos!.first;
          end.desBairro = desBairro;
          end.desCep = desCep;
          end.desCidade = desCidade;
          end.desEstado = desEstado;
          end.desNumero = desNumero;
          end.desPais = "Brasil";
          end.desRua = desRua;
        } else {
          end = Endereco(
              desBairro: desBairro,
              desCep: desCep,
              desCidade: desCidade,
              desEstado: desEstado,
              desNumero: desNumero,
              desPais: "Brasil",
              desRua: desRua);
        }

        List<Endereco> listEnderecos = <Endereco>[];
        listEnderecos.add(end);

        empre.enderecos = listEnderecos;
      }

      Usuario userCadastro = Usuario(
          desNome: nome,
          desSenha: senha,
          indTipo: indTipo,
          usuario: emailNormalizado,
          usuarioResp: res);
      if (indTipoProcesso == 1) {
        CadastroCemRequest cem = CadastroCemRequest(
            email: '', emailMotoristaAmigo: '', nome: '', senha: '');

        var result = await _userService.registraCem(cem, login2: userCadastro);

        if (result != null) {
          if (ApiBaseHelper.userSessao != null &&
              ApiBaseHelper.userSessao!.codUsuario != null) {
            Navigator.pop(context);
          } else {
            // Garante que o email está normalizado
            result.usuario = emailNormalizado;
            result.desSenha = senha;

            await _userService.logoffLocalDB();
            print('🟢 [CADASTRO_CONTROLLER] Tentando fazer login automático após cadastro...');
            print('🟢 [CADASTRO_CONTROLLER] Email normalizado: $emailNormalizado');
            print('🟢 [CADASTRO_CONTROLLER] Senha length: ${senha.length}');
            LoginRequest req = LoginRequest(email: emailNormalizado, senha: senha);
            var userLogin = await _userService.login(req);

            if (result.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA ||
                result.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA) {
              if (kIsWeb) {
                showToast(context,
                    "Cadastro concluído com sucesso. Login permitido somente via plataformas mobile.");
                if (!kDebugMode) return;
              }
            }

            await _userService.saveLocalDB(userLogin!);
            await Navigator.pushReplacementNamed(
              context,
              AppRoutes.home,
            );
          }
        } else {
          showToast(context, "E-mail ou senha inválidos, tente novamente");
        }
      } else {
        CadastroCemRequest cem = CadastroCemRequest(
            email: '', emailMotoristaAmigo: '', nome: '', senha: '');

        userCadastro.usuarioResp!.codUsuario =
            ApiBaseHelper.userSessao!.codUsuario;

        userCadastro.usuarioResp!.dataCriacao =
            ApiBaseHelper.userSessao!.dataCriacao;

        userCadastro.usuarioResp!.indOffline =
            ApiBaseHelper.userSessao!.usuarioResp!.indOffline;

        userCadastro.usuarioResp!.senha =
            ApiBaseHelper.userSessao!.usuarioResp!.senha;
        if (senha != null && !senha.isEmpty) {
          userCadastro.usuarioResp!.reSenha = senha;
          userCadastro.usuarioResp!.senha = senha;
        }

        var result =
            await _userService.atualizaUsuario(cem, login2: userCadastro);

        if (result != null) {
          // Garante que o email está normalizado
          result.usuario = emailNormalizado;
          result.desSenha = senha;

          if (senha != null && !senha.isEmpty) {
            await _userService.logoffLocalDB();
            print('🟢 [CADASTRO_CONTROLLER] Tentando fazer login automático após atualização...');
            print('🟢 [CADASTRO_CONTROLLER] Email normalizado: $emailNormalizado');
            print('🟢 [CADASTRO_CONTROLLER] Senha length: ${senha.length}');
            LoginRequest req = LoginRequest(email: emailNormalizado, senha: senha);
            var userLogin = await _userService.login(req);

            if (result.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA ||
                result.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA) {
              if (kIsWeb) {
                showToast(context,
                    "Cadastro concluído com sucesso. Login permitido somente via plataformas mobile.");
                if (!kDebugMode) return;
              }
            }
            await _userService.saveLocalDB(userLogin!);
          } else {
            await _userService.saveLocalDB(result);
          }
          await Navigator.pushReplacementNamed(
            context,
            AppRoutes.home,
          );
        } else {
          showToast(context, "E-mail ou senha inválidos, tente novamente");
        }
      }
    } on ApiException catch (e) {
      final friendlyMessage = ErrorHandler.handleError(e);
      showToast(context, friendlyMessage);
    } on CustomException catch (e) {
      Logger.logError(
        e,
        meta: {'email': email, 'tipo': indTipo},
        tag: 'CadastroController.registraCem',
      );
      // Melhora a mensagem de erro - evita duplicação
      String errorMessage = e.message ?? 'Erro ao efetuar cadastro';
      if (errorMessage.contains('Erro ao efetuar cadastro') && 
          errorMessage.split('Erro ao efetuar cadastro').length > 2) {
        // Remove duplicação se a mensagem já contém o prefixo
        errorMessage = errorMessage.replaceFirst('Erro ao efetuar cadastro: ', '');
      }
      
      // Se o erro for "usuário já existe", sugere email alternativo
      if (errorMessage.toLowerCase().contains('já existe') || 
          errorMessage.toLowerCase().contains('duplicado') ||
          errorMessage.toLowerCase().contains('already exists')) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final emailBase = email.split('@')[0];
        final emailDomain = email.contains('@') ? email.split('@')[1] : 'fool.com';
        final emailSugerido = '$emailBase.$timestamp@$emailDomain';
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Usuário já existe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Este email já está cadastrado no sistema.\n\n'
                  'Isso pode acontecer se:\n'
                  '• O usuário foi bloqueado mas não excluído\n'
                  '• O email já foi usado anteriormente\n\n'
                  'Sugestão: Use um email diferente.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email sugerido:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        emailSugerido,
                        style: const TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showToast(context, errorMessage);
      }
    } catch (e, stackTrace) {
      final friendlyMessage = ErrorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: {'email': email, 'tipo': indTipo},
      );
      showToast(context, friendlyMessage);
    } finally {
      DialogBuilder(context).hideOpenDialog();
    }
  }

  static void showToast(BuildContext context, String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}
