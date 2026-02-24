import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/modules/rating/services/rating_service.dart';
import 'package:flutter/material.dart';

/// Serviço para gerenciar abertura automática de avaliação após corrida concluída
class RatingAutomaticService {
  /// Abre a tela de avaliação após corrida ser concluída
  /// 
  /// Parâmetros:
  /// - context: BuildContext para navegação
  /// - corridaId: ID da corrida
  /// - solicitacao: Objeto SolicitacaoMotorista com dados da corrida
  /// - currentUserType: Tipo do usuário atual ('motorista' ou 'empresa')
  static Future<void> openRatingScreenAfterCompletion({
    required BuildContext context,
    required String corridaId,
    required dynamic solicitacao,
    required String currentUserType,
  }) async {
    try {
      // Aguarda um pouco para garantir que a corrida foi finalizada
      await Future.delayed(const Duration(milliseconds: 500));

      // Obtém informações do avaliador (quem está avaliando)
      String avaliadorId;
      String avaliadorName;
      
      // Obtém informações do avaliado (quem está sendo avaliado)
      String avaliadoId;
      String avaliadoName;
      String avaliadoType;

      if (currentUserType == 'motorista') {
        // Motorista está avaliando a empresa
        avaliadorId = solicitacao.codMotorista?.toString() ?? '';
        avaliadorName = solicitacao.dbMotoristasByCodMotorista?.desNomeFantasia ?? 
                       solicitacao.dbMotoristasByCodMotorista?.desRazaoSocial ?? 
                       'Motorista';
        
        avaliadoId = solicitacao.codEmpresa?.toString() ?? '';
        avaliadoName = solicitacao.dbEmpresasByCodEmpresa?.desNomeFantasia ?? 
                      solicitacao.dbEmpresasByCodEmpresa?.desRazaoSocial ?? 
                      'Empresa';
        avaliadoType = 'empresa';
      } else {
        // Empresa está avaliando o motorista
        avaliadorId = solicitacao.codEmpresa?.toString() ?? '';
        avaliadorName = solicitacao.dbEmpresasByCodEmpresa?.desNomeFantasia ?? 
                       solicitacao.dbEmpresasByCodEmpresa?.desRazaoSocial ?? 
                       'Empresa';
        
        avaliadoId = solicitacao.codMotorista?.toString() ?? '';
        avaliadoName = solicitacao.dbMotoristasByCodMotorista?.desNomeFantasia ?? 
                      solicitacao.dbMotoristasByCodMotorista?.desRazaoSocial ?? 
                      'Motorista';
        avaliadoType = 'motorista';
      }

      // Verifica se já existe avaliação para esta corrida
      final hasRated = await RatingService.hasRated(corridaId, avaliadorId);
      if (hasRated) {
        // Já avaliou, não abre a tela novamente
        return;
      }

      // Abre a tela de avaliação
      if (!context.mounted) return;
      
      Navigator.pushNamed(
        context,
        AppRoutes.rating,
        arguments: {
          'corridaId': corridaId,
          'avaliadorId': avaliadorId,
          'avaliadorName': avaliadorName,
          'avaliadorType': currentUserType,
          'avaliadoId': avaliadoId,
          'avaliadoName': avaliadoName,
          'avaliadoType': avaliadoType,
        },
      );
    } catch (e) {
      debugPrint('Erro ao abrir tela de avaliação: $e');
      // Não bloqueia o fluxo se houver erro
    }
  }
}

