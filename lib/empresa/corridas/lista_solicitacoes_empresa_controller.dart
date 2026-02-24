import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:delivery_front/shared/components/loading_dialog.dart';
import 'package:delivery_front/shared/models/DadosCorrida.dart';
import 'package:delivery_front/shared/models/consultaRequest.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/modules/chat/services/chat_automatic_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ListaSolicitacoesEmpresaController extends ChangeNotifier {
  final BuildContext context;
  UserService _userService = new UserService();

  ListaSolicitacoesEmpresaController(this.context);

  Future<List<SolicitacaoMotorista>> buscaListaSolicitacoes(
      {int indBuscaChamadosRaio = -1, ConsultaRequest? req}) async {
    try {
      //DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));
      var result = null;
      if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
          indBuscaChamadosRaio) {
        result = await _userService.fetchSolicitacoesEmpresa(
            indBuscaChamadosRaio: indBuscaChamadosRaio, req: req);
      } else {
        result = await _userService.fetchSolicitacoesEmpresa(
            indBuscaChamadosRaio: indBuscaChamadosRaio, req: req);
      }

      if (result != null) {
        return result;
      } else {
        LoginControler.showToast(context, "Não foram encontrados Solicitações");
        List<SolicitacaoMotorista> listResponse = [];
        return listResponse;
      }
    } catch (e) {
      LoginControler.showToast(
          context, "Erro ao buscar solicitações, tente novamente");
      List<SolicitacaoMotorista> listResponse = [];
      return listResponse;
    } finally {
      //DialogBuilder(context).hideOpenDialog();
    }
  }

  Future<List<SolicitacaoMotorista>> buscaListaNovasSolicitacoes(
      {int indBuscaChamadosRaio = -1, ConsultaRequest? req}) async {
    try {
      //DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));
      var result = null;
      if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
          indBuscaChamadosRaio) {
        result = await _userService.fetchNovasCorridasMotorista(
            indBuscaChamadosRaio: indBuscaChamadosRaio);
      } else {
        result = await _userService.fetchSolicitacoesMotorista();
      }

      if (result != null) {
        return result;
      } else {
        LoginControler.showToast(context, "Não foram encontrados Solicitações");
        List<SolicitacaoMotorista> listResponse = [];
        return listResponse;
      }
    } catch (e) {
      LoginControler.showToast(
          context, "Erro ao buscar solicitações, tente novamente");
      List<SolicitacaoMotorista> listResponse = [];
      return listResponse;
    } finally {
      //DialogBuilder(context).hideOpenDialog();
    }
  }

  Future<void> finalizarChamado(int numSeqChamado, int indStatusCorrida, {String? motivoCancelamento}) async {
    try {
      DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));

      await _userService.finalizarChamado(numSeqChamado, indStatusCorrida, motivoCancelamento: motivoCancelamento);
      
      // Envia mensagem automática no chat
      await ChatAutomaticMessages.sendStatusMessage(
        corridaId: numSeqChamado.toString(),
        indStatusCorrida: indStatusCorrida,
      );
      
      notifyListeners();
    } catch (e) {
      LoginControler.showToast(
          context, "Erro ao atualizar corrida tente novamente!");
    } finally {
      DialogBuilder(context).hideOpenDialog();
    }
  }

  Future<void> aceitarCorrida(int numSeqChamado, int indStatusCorrida) async {
    try {
      //DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));

      await _userService.aceitarCorrida(numSeqChamado, indStatusCorrida);
      
      // Envia mensagem automática no chat
      await ChatAutomaticMessages.sendStatusMessage(
        corridaId: numSeqChamado.toString(),
        indStatusCorrida: indStatusCorrida,
      );
      
      notifyListeners();
    } on PlatformException catch (e) {
      if (e.message != null && e.message!.contains("outro motorista")) {
        _showMyDialog(
            "Corrida já aceita por outro motorista, aguarde uma próxima");
      } else {
        LoginControler.showToast(
            context, "Erro ao atualizar chamado tente novamente!");
      }
    } finally {
      //DialogBuilder(context).hideOpenDialog();
    }
  }

  Future<void> _showMyDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atenção'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<DadosCorridas>> buscaTotaisCorrida(
      {int? codEmpresa,
      int? codMotorista,
      DateTime? dtaIni,
      DateTime? dtaFim}) async {
    try {
      //DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));
      var result = null;
      result = await _userService.buscaDadosCorrida(
          codEmpresa: codEmpresa,
          codMotorista: codMotorista,
          dtaIni: dtaIni,
          dtaFim: dtaFim);

      if (result != null) {
        return result;
      } else {
        LoginControler.showToast(context, "Não foram encontrados Solicitações");
        List<DadosCorridas> listResponse = [];
        return listResponse;
      }
    } catch (e) {
      LoginControler.showToast(
          context, "Erro ao buscar solicitações, tente novamente");
      List<DadosCorridas> listResponse = [];
      return listResponse;
    } finally {
      //DialogBuilder(context).hideOpenDialog();
    }
  }
}
