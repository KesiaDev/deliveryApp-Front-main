import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_front/home/home_page.dart';
import 'package:delivery_front/shared/components/customException.dart';
import 'package:delivery_front/shared/components/loading_dialog.dart';
import 'package:delivery_front/shared/models/cadastroCemRequest.dart';
import 'package:delivery_front/shared/models/loginRequest.dart';
import 'package:delivery_front/shared/models/usuario.dart';

class EditarCadastroController {
  final BuildContext context;

  UserService _userService = new UserService();

  EditarCadastroController(this.context);

  String email = "";
  String senha = "";
  String nome = "";
  String emailMotoristaAmigo = "";
  int? codCem;
  int? codMotorista;
  String cor = "";
  String carro = "";
  String placa = "";
  String desFotoPerfilBase64 = "";
  String desTipoMoto = "";
  String desCorMoto = "";

  void setEmail(String s) => email = s;
  void setSenha(String s) => senha = s;
  void setNome(String s) => nome = s;
  void setEmailMotoristaAmigo(String s) => emailMotoristaAmigo = s;
  void setCodCem(int s) => codCem = s;
  void setCodMotorista(int s) => codMotorista = s;

  void setPlaca(String s) => placa = s;
  void setCor(String s) => cor = s;
  void setCarro(String s) => carro = s;
  void setDesFotoPerfilBase64(String s) => desFotoPerfilBase64 = s;
  void setDesTipoMoto(String s) => desTipoMoto = s;
  void setDesCorMoto(String s) => desCorMoto = s;

  CadastroCemRequest get credential => CadastroCemRequest(
        email: email,
        senha: senha,
        emailMotoristaAmigo: emailMotoristaAmigo,
        nome: nome,
        codCem: codCem,
        cor: cor,
        placa: placa,
        carro: carro,
      );

  Future<void> atualizarCadastroCem() async {
    try {
      DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));
      
      // Constrói UsuarioResp com a foto se houver
      final usuarioAtual = ApiBaseHelper.userSessao!;
      final usuarioRespAtual = usuarioAtual.usuarioResp;
      
      Usuario? usuarioUpdate;
      if (usuarioRespAtual != null && usuarioRespAtual.empresas != null && usuarioRespAtual.empresas!.isNotEmpty) {
        final empresaAtual = usuarioRespAtual.empresas!.first;
        
        // Cria uma nova empresa com os dados atualizados
        final empresaAtualizada = Empresa(
          codEmpresa: empresaAtual.codEmpresa,
          desCpfCnpj: empresaAtual.desCpfCnpj,
          desNomeFantasia: empresaAtual.desNomeFantasia,
          desRazaoSocial: empresaAtual.desRazaoSocial,
          desCartao: empresaAtual.desCartao,
          desNomeCartao: empresaAtual.desNomeCartao,
          desFotoPerfil: desFotoPerfilBase64.isNotEmpty ? desFotoPerfilBase64 : empresaAtual.desFotoPerfil,
          enderecos: empresaAtual.enderecos,
          contatos: empresaAtual.contatos,
          user: empresaAtual.user,
        );
        
        // Atualiza usuarioResp com a empresa atualizada
        final usuarioRespAtualizado = UsuarioResp(
          codUsuario: usuarioRespAtual.codUsuario,
          desNome: nome.isNotEmpty ? nome : usuarioRespAtual.desNome,
          usuario: email.isNotEmpty ? email : usuarioRespAtual.usuario,
          senha: senha.isNotEmpty ? senha : usuarioRespAtual.senha,
          reSenha: senha.isNotEmpty ? senha : usuarioRespAtual.reSenha,
          dataCriacao: usuarioRespAtual.dataCriacao,
          tipPerfil: usuarioRespAtual.tipPerfil,
          indBloqueado: usuarioRespAtual.indBloqueado,
          dthBloqueio: usuarioRespAtual.dthBloqueio,
          empresas: [empresaAtualizada],
          motoristas: usuarioRespAtual.motoristas,
        );
        
        usuarioUpdate = Usuario(
          desNome: nome.isNotEmpty ? nome : usuarioAtual.desNome,
          desSenha: senha.isNotEmpty ? senha : usuarioAtual.desSenha,
          indTipo: 2,
          usuario: email.isNotEmpty ? email : usuarioAtual.usuario,
          usuarioResp: usuarioRespAtualizado,
        );
        
        usuarioUpdate.codUsuario = usuarioAtual.codUsuario;
        usuarioUpdate.dataCriacao = usuarioAtual.dataCriacao;
        
        if (senha.isNotEmpty) {
          usuarioUpdate.usuarioResp!.reSenha = senha;
          usuarioUpdate.usuarioResp!.senha = senha;
        }
      }
      
      var result = await _userService.registraCem(credential, login2: usuarioUpdate);

      if (result != null) {
        // Se houver foto, atualiza no resultado
        if (desFotoPerfilBase64.isNotEmpty && result.usuarioResp != null && 
            result.usuarioResp!.empresas != null && result.usuarioResp!.empresas!.isNotEmpty) {
          // A foto será salva através do usuarioResp completo
          // Se o backend suportar, a foto estará no objeto empresa
        }
        
        await _userService.saveLocalDB(result);
        showToast(context, "Cadastro Atualizado com sucesso!!!");
        Navigator.pop(context, 1);
      } else {
        showToast(context, "E-mail ou senha inválidos, tente novamente");
      }
    } on CustomException catch (e) {
      showToast(
          context, "Erro ao efetuar cadastro, tente novamente: " + e.message);
    } catch (e) {
      showToast(context, "Erro ao efetuar cadastro, tente novamente");
    } finally {
      DialogBuilder(context).hideOpenDialog();
    }
  }

  Future<void> atualizarCadastroMotorista() async {
    try {
      DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));
      
      // Constrói UsuarioResp com os novos campos
      final usuarioAtual = ApiBaseHelper.userSessao!;
      final usuarioRespAtual = usuarioAtual.usuarioResp;
      
      if (usuarioRespAtual != null && usuarioRespAtual.motoristas != null && usuarioRespAtual.motoristas!.isNotEmpty) {
        final motoristaAtual = usuarioRespAtual.motoristas!.first;
        
        // Atualiza campos existentes
        if (desFotoPerfilBase64.isNotEmpty) {
          motoristaAtual.desFotoPerfil = desFotoPerfilBase64;
        }
        if (desTipoMoto.isNotEmpty) {
          motoristaAtual.desTipoMoto = desTipoMoto;
        }
        if (desCorMoto.isNotEmpty) {
          motoristaAtual.desCorMoto = desCorMoto;
        }
        if (placa.isNotEmpty) {
          motoristaAtual.desPlaca = placa;
        }
        if (carro.isNotEmpty) {
          // Mantém compatibilidade com campo existente se necessário
        }
        if (cor.isNotEmpty) {
          // Mantém compatibilidade com campo existente se necessário
        }
      }
      
      // Usa atualizaUsuario que envia o usuarioResp completo
      final usuarioUpdate = Usuario(
        desNome: nome,
        desSenha: senha,
        indTipo: 1,
        usuario: email,
        usuarioResp: usuarioRespAtual,
      );
      
      usuarioUpdate.usuarioResp!.codUsuario = usuarioAtual.codUsuario;
      usuarioUpdate.usuarioResp!.dataCriacao = usuarioAtual.dataCriacao;
      usuarioUpdate.usuarioResp!.indOffline = usuarioAtual.usuarioResp?.indOffline;
      usuarioUpdate.usuarioResp!.senha = usuarioAtual.usuarioResp?.senha;
      
      if (senha.isNotEmpty) {
        usuarioUpdate.usuarioResp!.reSenha = senha;
        usuarioUpdate.usuarioResp!.senha = senha;
      }
      
      var result = await _userService.atualizaUsuario(credential, login2: usuarioUpdate);

      if (result != null) {
        await _userService.saveLocalDB(result);
        showToast(context, "Cadastro Atualizado com sucesso!!!");
        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context, 1);
      } else {
        showToast(context, "E-mail ou senha inválidos, tente novamente");
      }
    } on CustomException catch (e) {
      showToast(
          context, "Erro ao efetuar cadastro, tente novamente: " + e.message);
    } catch (e) {
      showToast(context, "Erro ao efetuar cadastro, tente novamente");
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
