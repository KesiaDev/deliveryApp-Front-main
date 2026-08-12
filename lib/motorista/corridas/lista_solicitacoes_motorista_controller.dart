import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/modules/chat/services/chat_automatic_messages.dart';
import 'package:delivery_front/modules/tracking/services/tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ListaSolicitacoesMotoristaController extends ChangeNotifier {
  final BuildContext context;
  UserService _userService = new UserService();

  ListaSolicitacoesMotoristaController(this.context);

  Future<List<SolicitacaoMotorista>> buscaListaSolicitacoes(
      {int indBuscaChamadosRaio = -1, bool isAdm = false}) async {
    try {
      var result = null;
      if (isAdm) {
        result = await _userService.fetchSolicitacoesEmpresa(
            indBuscaChamadosRaio: indBuscaChamadosRaio, isAdm: isAdm);
      } else {
        // Sempre usa o endpoint que funciona: /corridas/motorista/{id}/{status}
        // O endpoint /corridas/usuario/{id} (BUG-004) não retorna corridas disponíveis
        result = await _userService.fetchSolicitacoesMotorista(
            indBuscaChamadosRaio: indBuscaChamadosRaio, isAdm: isAdm);
      }

      if (result != null) {
        // Deduplication by numSeq to prevent duplicate entries
        final seen = <int>{};
        return result.where((s) => seen.add(s.numSeq ?? -1)).toList();
      } else {
        LoginControler.showToast(context, "Nenhuma solicitação encontrada.");
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

      await _userService.finalizarChamado(numSeqChamado, indStatusCorrida, motivoCancelamento: motivoCancelamento);
      
      // Envia mensagem automática no chat
      await ChatAutomaticMessages.sendStatusMessage(
        corridaId: numSeqChamado.toString(),
        indStatusCorrida: indStatusCorrida,
      );

      // Para o rastreamento quando corrida é finalizada ou cancelada
      if (indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ||
          indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA) {
        try {
          await TrackingService.stopTracking();
          debugPrint('🛑 Rastreamento parado para corrida $numSeqChamado');
        } catch (e) {
          debugPrint('⚠️ Erro ao parar rastreamento: $e');
        }
      }
      
      notifyListeners();
    } catch (e) {
      LoginControler.showToast(
          context, "Erro ao atualizar corrida tente novamente!");
    } finally {
      //DialogBuilder(context).hideOpenDialog();
    }
  }

  Future<bool> aceitarCorrida(int numSeqChamado, int indStatusCorrida) async {
    try {
      // Block acceptance if driver already has an active delivery
      List? activasResult;
      List? aceitasResult;
      try {
        activasResult = await _userService.fetchSolicitacoesMotorista(
          indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO,
        );
        aceitasResult = await _userService.fetchSolicitacoesMotorista(
          indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA,
        );
      } catch (_) {}
      final totalAtivas = (activasResult?.length ?? 0) + (aceitasResult?.length ?? 0);
      if (totalAtivas > 0) {
        _showMyDialog("Você já possui uma corrida ativa. Conclua-a antes de aceitar outra.");
        return false;
      }

      await _userService.aceitarCorrida(numSeqChamado, indStatusCorrida);

      // Mensagem automática e rastreamento não bloqueiam o fluxo em caso de erro
      try {
        await ChatAutomaticMessages.sendStatusMessage(
          corridaId: numSeqChamado.toString(),
          indStatusCorrida: indStatusCorrida,
        );
      } catch (e) {
        debugPrint('⚠️ Erro ao enviar mensagem automática: $e');
      }

      // Inicia rastreamento automaticamente quando motorista aceita corrida
      final user = ApiBaseHelper.userSessao;
      if (user != null && indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA) {
        try {
          await TrackingService.startTracking(
            corridaId: numSeqChamado.toString(),
            userId: user.codUsuario?.toString() ?? '0',
          );
          debugPrint('✅ Rastreamento iniciado automaticamente para corrida $numSeqChamado');
        } catch (e) {
          debugPrint('⚠️ Erro ao iniciar rastreamento: $e');
        }
      }

      notifyListeners();
      return true;
    } on PlatformException catch (e) {
      if (e.message != null && e.message!.contains("outro motorista")) {
        _showMyDialog("Corrida já aceita por outro motorista, aguarde uma próxima");
      } else {
        LoginControler.showToast(context, "Erro ao atualizar chamado tente novamente!");
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao aceitar corrida: $e');
      LoginControler.showToast(context, "Erro ao aceitar corrida, tente novamente.");
      return false;
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
}
