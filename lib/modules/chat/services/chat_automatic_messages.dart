import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'chat_service.dart';

/// Serviço para enviar mensagens automáticas quando corrida muda de status
class ChatAutomaticMessages {
  /// Envia mensagem automática baseada no status da corrida
  static Future<void> sendStatusMessage({
    required String corridaId,
    required int indStatusCorrida,
  }) async {
    String messageText = '';

    switch (indStatusCorrida) {
      case ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA:
        messageText = 'Sua corrida foi criada! Estamos buscando um motoboy.';
        break;
      case ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA:
        messageText = 'O motoboy está a caminho do ponto de retirada.';
        break;
      case ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO:
        messageText = 'O item já foi retirado e está indo para o destino.';
        break;
      case ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA:
        messageText = 'Corrida finalizada com sucesso. Obrigado por usar nosso app!';
        break;
      case ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA:
        messageText = 'Sua corrida foi cancelada.';
        break;
      default:
        return; // Não envia mensagem para status desconhecido
    }

    if (messageText.isNotEmpty) {
      await ChatService.sendAutomaticMessage(
        corridaId: corridaId,
        messageText: messageText,
      );
    }
  }
}

