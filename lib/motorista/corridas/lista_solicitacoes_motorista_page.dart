import 'dart:async';
import 'dart:developer';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:delivery_front/modules/cod/models/cod_model.dart';
import 'package:delivery_front/modules/cod/screens/confirmacao_cobranca_screen.dart';
import 'package:delivery_front/modules/cod/services/cod_service.dart';
import 'package:delivery_front/motorista/corridas/lista_solicitacoes_motorista_controller.dart';
import 'package:delivery_front/modules/chat/screens/chat_screen.dart';
import 'package:delivery_front/modules/rating/services/rating_automatic_service.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'package:delivery_front/shared/models/TipoCorrida.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/dialogs/cancel_corrida_dialog.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class ListaSolicitacoesMotoristaPage extends StatefulWidget {
// Declare a field that holds the Todo.
  final int? indTipoDefault;
  bool? isAdm;

  // In the constructor, require a Todo.
  ListaSolicitacoesMotoristaPage(
      {Key? key, this.indTipoDefault, this.isAdm = false})
      : super(key: key);

  ListaSolicitacoesMotoristaPage.second(
      {Key? key, this.indTipoDefault, required this.isAdm})
      : super(key: key);

  @override
  _ListaSolicitacoesMotoristaPageState createState() =>
      _ListaSolicitacoesMotoristaPageState();
}

class _ListaSolicitacoesMotoristaPageState
    extends State<ListaSolicitacoesMotoristaPage> {
  ListaSolicitacoesMotoristaController? _controller;
  late VoidCallback _controllerListener;
  // BUG-022: chave para forçar rebuild do ListaCemMotoristaView quando o
  // controller muda (notifyListeners), garantindo reload do FutureBuilder.
  Key _listKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _controller = ListaSolicitacoesMotoristaController(context);
    _controllerListener = () {
      if (mounted) setState(() { _listKey = UniqueKey(); });
    };
    _controller!.addListener(_controllerListener);
  }

  @override
  void dispose() {
    _controller?.removeListener(_controllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                  widget.indTipoDefault
              ? 'Pedidos disponíveis'
              : ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
                      widget.indTipoDefault
                  ? 'Corridas aceitas'
                  : ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ==
                          widget.indTipoDefault
                      ? 'Corridas em andamento'
                      : ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ==
                              widget.indTipoDefault
                          ? 'Corridas concluídas'
                          : ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA ==
                                  widget.indTipoDefault
                              ? 'Corridas canceladas'
                              : 'Minhas corridas'),
        ),
        body: Center(
            child: ListaCemMotoristaView(
          key: _listKey,
          controller: _controller!,
          indStatusDefault: widget.indTipoDefault,
          isAdm: widget.isAdm ?? false,
        )),
      ),
    );
  }
}

class ListaCemMotoristaView extends StatefulWidget {
  final ListaSolicitacoesMotoristaController controller;
  final int? indStatusDefault;
  final bool isAdm;

  ListaCemMotoristaView(
      {Key? key,
      required this.controller,
      this.indStatusDefault,
      this.isAdm = false})
      : super(key: key);

  @override
  State<ListaCemMotoristaView> createState() => _ListaCemMotoristaViewState();
}

class _ListaCemMotoristaViewState extends State<ListaCemMotoristaView> {
  late Future<List<SolicitacaoMotorista>> _future;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh a cada 15 segundos (BUG-006: UI não atualiza status em tempo real)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _future = widget.controller.buscaListaSolicitacoes(
          indBuscaChamadosRaio: widget.indStatusDefault ?? -1,
          isAdm: widget.isAdm);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: FutureBuilder<List<SolicitacaoMotorista>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            List<SolicitacaoMotorista> data = snapshot.data!;
            final route = ModalRoute.of(context);
            final pageName = route?.settings.name ?? "";
            log(pageName);
            if (data.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Text(
                      'Nenhuma corrida encontrada.\nArraste para baixo para atualizar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              );
            }
            return _jobsListView(data, widget.controller);
          } else if (snapshot.hasError) {
            return ListView(
              children: [
                SizedBox(height: 80),
                Center(child: Text("${snapshot.error}")),
              ],
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // ListView _jobsListView(List<SolicitacaoMotorista> data, controller) {
  //   return ListView.builder(
  //       itemCount: data.length,
  //       itemBuilder: (context, index) {
  //         return _tile(
  //             ((data[index].dbMotoristasByCodMotorista!.desNomeFantasia != null
  //                     ? data[index]
  //                             .dbMotoristasByCodMotorista!
  //                             .desNomeFantasia! +
  //                         " - "
  //                     : "") +
  //                 ApiBaseHelper.getDtaFormatada(data[index].dthSolicitacao)),
  //             (data[index].indStatusCorrida == 1 ? "Concluída" : "Aberta"),
  //             (Utils.getIconStatusCorridaIconData(
  //                 data[index].indStatusCorrida)),
  //             data[index],
  //             controller,
  //             data[index].indStatusCorrida ==
  //                     ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA
  //                 ? true
  //                 : false,
  //             context);
  //       });
  // }

  ListView _jobsListView(
      List<SolicitacaoMotorista> data,
      ListaSolicitacoesMotoristaController controller) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          return _tile2(
              ((data[index].dbEmpresasByCodEmpresa?.desNomeFantasia != null
                      ? data[index].dbEmpresasByCodEmpresa!.desNomeFantasia! +
                          " - "
                      : "") +
                  ApiBaseHelper.getDtaFormatada(data[index].dthSolicitacao)),
              (data[index].indStatusCorrida == 1 ? "Concluída" : "Aberta"),
              (Utils.getIconStatusCorridaIconData(
                  data[index].indStatusCorrida)),
              data[index],
              controller,
              data[index].indStatusCorrida ==
                          ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ||
                      data[index].indStatusCorrida ==
                          ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA
                  ? true
                  : false,
              context);
        });
  }

  Padding _tile2(
      String title,
      String subtitle,
      IconData icon,
      SolicitacaoMotorista amigo,
      ListaSolicitacoesMotoristaController _controller,
      bool isFinalizado,
      BuildContext _context) {
    int nextStatus =
        Utils.getDesStatusProxStatusCorrida(amigo.indStatusCorrida);
    String text = Utils.getDesStatusCorrida(amigo.indStatusCorrida);
    subtitle = Utils.getDesTextoProxStatusCorrida(amigo.indStatusCorrida);
    String subtitleaux = "";
    String subtitleEndere = "";
    String subtitleObsEntrega = "";
    if (amigo.dthInicioCorrida != null)
      subtitleaux = subtitleaux +
          "Inicio corrida:" +
          ApiBaseHelper.getDtaFormatada(amigo.dthInicioCorrida);

    if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
        amigo.indStatusCorrida) {
      if (amigo.enderecoEmpresa != null)
        subtitleEndere = subtitleEndere + amigo.enderecoEmpresa!;

      if (amigo.desObsCorrida != null)
        subtitleObsEntrega = subtitleObsEntrega + amigo.desObsCorrida!;
    } else {
      if (amigo.dthFinalizacaoCorrida != null)
        subtitleaux = subtitleaux +
            " - Fim corrida:" +
            ApiBaseHelper.getDtaFormatada(amigo.dthFinalizacaoCorrida);

      if (amigo.desEnderecoEntrega != null) {
        subtitleEndere = subtitleEndere + amigo.desEnderecoEntrega!;
        if (amigo.desNumeroEndereco != null && amigo.desNumeroEndereco!.isNotEmpty) {
          subtitleEndere = subtitleEndere + ', ' + amigo.desNumeroEndereco!;
        }
        subtitleEndere = subtitleEndere + ' - ';
      }

      if (amigo.desObsCorrida != null)
        subtitleObsEntrega = subtitleObsEntrega + amigo.desObsCorrida!;
    }

    if (amigo.indTipoCorrida != null) {
      subtitleObsEntrega = subtitleObsEntrega +
          " - " +
          getTitleTipoCorrida(amigo.indTipoCorrida!);
    }

    // Para nova corrida: exibe ganho com label claro no topo das obs
    if (amigo.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA) {
      final ganho = Utils.formatBRL(amigo.vlrTotalMotorista);
      subtitleObsEntrega = '💰 Você recebe: $ganho\n$subtitleObsEntrega';
    } else {
      subtitleObsEntrega = subtitleObsEntrega + ' · ${Utils.formatBRL(amigo.vlrTotalMotorista)}';
    }

    // Badge de Cobrança na Entrega
    if (amigo.isCod) {
      final vlrCod = amigo.vlrCobrancaCliente?.toStringAsFixed(2) ?? '?';
      final maq = amigo.indMaquininha == 1 ? ' 💳' : '';
      subtitleObsEntrega = '💰 Cobrar do cliente: R\$ $vlrCod$maq\n$subtitleObsEntrega';
    }

    // Build multi-destination steps label when delivery has ordered destinations
    if (amigo.destinos != null && amigo.destinos!.length > 1) {
      final sorted = [...amigo.destinos!]..sort((a, b) => a.ordem.compareTo(b.ordem));
      final steps = sorted
          .map((d) => '${d.ordem}. ${d.enderecoCompleto}')
          .join('\n');
      subtitleEndere = 'Paradas:\n$steps';
    }

    // Botão de chat — visível para corridas aceitas ou em andamento
    final user = ApiBaseHelper.userSessao;
    Widget chatButton = Visibility(
      visible: (amigo.indStatusCorrida ==
                  ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ||
              amigo.indStatusCorrida ==
                  ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO)
          ? true
          : false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'chat_${amigo.numSeq}',
            onPressed: () {
              if (user == null) return;
              final motoristaId =
                  user.usuarioResp?.motoristas?.first.codMotorista?.toString() ??
                      '';
              final motoristaName =
                  user.usuarioResp?.motoristas?.first.desNomeFantasia ??
                      user.desNome ??
                      'Motorista';
              final empresaId =
                  amigo.codEmpresa?.toString() ?? '';
              final empresaName =
                  amigo.dbEmpresasByCodEmpresa?.desNomeFantasia ?? 'Empresa';

              Navigator.push(
                _context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    corridaId: amigo.numSeq?.toString() ?? '',
                    motoristaId: motoristaId,
                    motoristaName: motoristaName,
                    empresaId: empresaId,
                    empresaName: empresaName,
                    currentUserId: motoristaId,
                    currentUserName: motoristaName,
                    currentUserType: 'motorista',
                  ),
                ),
              );
            },
            child: const Icon(Icons.chat_bubble_outline),
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );

    return _customListItem(
      IconButton(
          onPressed: () {
            ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
              content: Text('Status: ${Utils.getDesStatusCorrida(amigo.indStatusCorrida)}'),
              duration: const Duration(seconds: 2),
            ));
          },
          icon: Utils.getIconStatusCorrida(amigo.indStatusCorrida)),
      title,
      text,
      amigo.qtdKmCorrida ?? 0,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          //Text(subtitle),
          FloatingActionButton.extended(
            onPressed: () {
              // Add your onPressed code here!
              //Caso no momento do clique já possua acesso, ao clicar será retirado acesso
              //Caso não tenha acesso, ao ser clicar enviara true para atualizar
              if (ApiBaseHelper.userSessao!.indTipo ==
                  ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
                if (isFinalizado) {
                  LoginControler.showToast(_context,
                      "Não é possível alterar o status de uma corrida já encerrada.");
                } else {
                  //amigo.indStatusCorrida = (isFinalizado ? 1 : 0);
                  //_controller.finalizarChamado(amigo.numSeq!,ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA );
                  if (ApiBaseHelper.userSessao?.usuarioResp?.indBloqueado !=
                          null &&
                      ApiBaseHelper.userSessao?.usuarioResp?.indBloqueado ==
                          1) {
                    LoginControler.showToast(_context,
                        "Usuário bloqueado não é possível aceitar corridas.");
                  } else {
                    showAlertDialog(_context, amigo.numSeq!, _controller,
                        amigo.indStatusCorrida!, amigo);
                    //amigo.indStatusCorrida = Utils.getDesStatusProxStatusCorrida(amigo.indStatusCorrida);
                  }
                }
              }
            },
            label: Text(subtitle, style: TextStyle(fontSize: 8)),
            //  icon: Utils.getIconStatusCorrida(amigo.indStatusCorrida),
            backgroundColor:
                Utils.getColorStatusCorrida(amigo.indStatusCorrida),
          ),
        ],
      ),
      subtitleaux,
      subtitleEndere,
      subtitleObsEntrega,
      Visibility(
        visible: (amigo.indStatusCorrida ==
                    ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ||
                amigo.indStatusCorrida ==
                    ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA)
            ? true
            : false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            //Text(subtitle),
            FloatingActionButton(
              heroTag: 'nav_${amigo.numSeq}',
              onPressed: () async {
                await _openInAppNavigation(_context, amigo);
              },
              child: const Icon(Icons.navigation_rounded),
              backgroundColor: Colors.blue,
            ),
          ],
        ),
      ),
      Visibility(
        visible: (amigo.indStatusCorrida ==
                    ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ||
                amigo.indStatusCorrida ==
                    ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA)
            ? true
            : false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            //Text(subtitle),
            FloatingActionButton(
              onPressed: () async {
                // Add your onPressed code here!
                //Caso no momento do clique já possua acesso, ao clicar será retirado acesso
                //Caso não tenha acesso, ao ser clicar enviara true para atualizar
                if (amigo.desTelefone != null) {
                  String telefone = amigo.desTelefone!;
                  String url = "tel:$telefone";
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                }
              },
              //label: Text("", style: TextStyle(fontSize: 8)),
              child: Icon(Icons.call),
              //icon: Icon(Icons.location_on),
              backgroundColor: Colors.blue,
            ),
          ],
        ),
      ),
      chatButton,
    );
  }

  _customListItem(
      Widget thumbnail,
      String title,
      String? user,
      double viewCount,
      Widget custom,
      String dadosCorrida,
      String enderecoEntrega,
      String obsEntrega,
      Widget custom2,
      Widget custom3,
      Widget custom4) {
    // BUG-019: layout reestruturado — botões abaixo do conteúdo para evitar
    // overflow horizontal em telas pequenas e garantir scroll vertical correto.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumbnail,
              const SizedBox(width: 8),
              Expanded(
                child: _videoDescription(title, user ?? "", viewCount,
                    dadosCorrida, enderecoEntrega, obsEntrega),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Botões de ação em linha com wrap para caber em qualquer tela
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [custom, custom2, custom3, custom4],
          ),
          const Divider(),
        ],
      ),
    );
  }

  _videoDescription(String title, String user, double viewCount,
      String dadosCorrida, String enderecoEntrega, String obsEntrega) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5.0, 0.0, 0.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14.0,
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 2.0)),
          Text(
            user,
            style: const TextStyle(fontSize: 10.0),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 2.0)),
          Text(
            dadosCorrida,
            style: const TextStyle(fontSize: 10.0),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Text(
            enderecoEntrega,
            style: const TextStyle(fontSize: 10.0),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Text(
            obsEntrega,
            style: const TextStyle(fontSize: 10.0),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Text(
            '$viewCount KMs',
            style: const TextStyle(fontSize: 10.0),
          ),
        ],
      ),
    );
  }

  ListTile _tile(
      String title,
      String subtitle,
      IconData icon,
      SolicitacaoMotorista amigo,
      ListaSolicitacoesMotoristaController _controller,
      bool isFinalizado,
      BuildContext _context) {
    subtitle = Utils.getDesStatusCorrida(amigo.indStatusCorrida);
    String subtitleaux = subtitle;
    if (amigo.dthInicioCorrida != null)
      subtitleaux = subtitleaux +
          " Inicio corrida:" +
          ApiBaseHelper.getDtaFormatada(amigo.dthInicioCorrida);
    return ListTile(
      contentPadding: const EdgeInsets.all(15.0),
      title: Text(title, style: TextStyle()),
      subtitle: Text(
        subtitleaux,
        style: TextStyle(color: Colors.black),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          //Text(subtitle),
          FloatingActionButton.extended(
            onPressed: () {
              // Add your onPressed code here!
              //Caso no momento do clique já possua acesso, ao clicar será retirado acesso
              //Caso não tenha acesso, ao ser clicar enviara true para atualizar
              if (ApiBaseHelper.userSessao!.indTipo ==
                  ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
                if (isFinalizado) {
                  LoginControler.showToast(_context,
                      "Não é possível alterar o status de uma corrida já encerrado.");
                } else {
                  //amigo.indStatusCorrida = (isFinalizado ? 1 : 0);
                  //_controller.finalizarChamado(amigo.numSeq!,ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA );
                  if (ApiBaseHelper.userSessao?.indBloqueado != null &&
                      ApiBaseHelper.userSessao?.indBloqueado == 1) {
                    LoginControler.showToast(_context,
                        "Usuário bloqueado não é possível aceitar corridas.");
                  } else {
                    if (ApiBaseHelper.userSessao?.indBloqueado != null &&
                        ApiBaseHelper.userSessao?.indBloqueado == 1) {
                      LoginControler.showToast(_context,
                          "Usuário bloqueado não é possível aceitar corridas.");
                    } else {
                      showAlertDialog(_context, amigo.numSeq!, _controller,
                          amigo.indStatusCorrida!, amigo);
                      //amigo.indStatusCorrida = Utils.getDesStatusProxStatusCorrida(amigo.indStatusCorrida);
                    }
                  }
                }
              }
            },
            label: Text(subtitle, style: TextStyle(fontSize: 10)),
            icon: Utils.getIconStatusCorrida(amigo.indStatusCorrida),
            backgroundColor: (isFinalizado ? Colors.green : Colors.red),
          ),
        ],
      ),
      isThreeLine: true,
      leading: Icon(
        icon,
        color: Colors.orange[500],
      ),
    );
  }

  /// Abre a navegação in-app para retirada ou entrega dependendo do status da corrida
  Future<void> _openInAppNavigation(BuildContext context, SolicitacaoMotorista solicitacao) async {
    final corridaId = solicitacao.numSeq?.toString() ?? '';
    final isPickup = solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ||
        solicitacao.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA;

    if (isPickup) {
      // Navegando até a empresa para retirar
      double? lat = solicitacao.dbEmpresasByCodEmpresa?.desLatitude;
      double? lon = solicitacao.dbEmpresasByCodEmpresa?.desLongitude;

      if ((lat == null || lon == null) && solicitacao.enderecoEmpresa != null) {
        try {
          final locs = await locationFromAddress(solicitacao.enderecoEmpresa!);
          if (locs.isNotEmpty) {
            lat = locs.first.latitude;
            lon = locs.first.longitude;
          }
        } catch (_) {}
      }

      if (lat != null && lon != null && context.mounted) {
        Navigator.pushNamed(context, AppRoutes.motoristaNavigation, arguments: {
          'corridaId': corridaId,
          'destinationLat': lat,
          'destinationLng': lon,
          'destinationTitle': solicitacao.enderecoEmpresa ?? 'Local de retirada',
          'destinationType': 'pickup',
        });
      } else if (context.mounted) {
        Utils.getSnackBar('Endereço de retirada não disponível.', context);
      }
    } else {
      // Navegando até o cliente para entregar
      double? lat = solicitacao.desLatitudeEntrega;
      double? lon = solicitacao.desLongitudeEntrega;

      if ((lat == null || lon == null) && solicitacao.desEnderecoEntrega != null) {
        try {
          final addr = '${solicitacao.desEnderecoEntrega}, ${solicitacao.desNumeroEndereco ?? ''}';
          final locs = await locationFromAddress(addr);
          if (locs.isNotEmpty) {
            lat = locs.first.latitude;
            lon = locs.first.longitude;
            solicitacao.desLatitudeEntrega = lat;
            solicitacao.desLongitudeEntrega = lon;
          }
        } catch (_) {}
      }

      if (lat != null && lon != null && context.mounted) {
        final title = '${solicitacao.desEnderecoEntrega ?? 'Entrega'}'
            '${solicitacao.desNumeroEndereco != null ? ', ${solicitacao.desNumeroEndereco}' : ''}';
        Navigator.pushNamed(context, AppRoutes.motoristaNavigation, arguments: {
          'corridaId': corridaId,
          'destinationLat': lat,
          'destinationLng': lon,
          'destinationTitle': title,
          'destinationType': 'delivery',
        });
      } else if (context.mounted) {
        Utils.getSnackBar('Endereço de entrega não disponível.', context);
      }
    }
  }

  /// Abre navegação in-app direto para o ponto de retirada (usado ao aceitar corrida)
  Future<void> _openPickupNavigation(BuildContext context, SolicitacaoMotorista solicitacao) async {
    await _openInAppNavigation(context, solicitacao);
  }

  showAlertDialog(
      BuildContext _context,
      int numSeqChamado,
      ListaSolicitacoesMotoristaController _controller,
      int indStatusAtualCorrida,
      SolicitacaoMotorista solicitacao) {
    int nextStatus = Utils.getDesStatusProxStatusCorrida(indStatusAtualCorrida);
    String text = Utils.getDesTextoProxStatusCorrida(indStatusAtualCorrida);
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancelar"),
      onPressed: () {
        Navigator.of(_context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Confirmar"),
      onPressed: () async {
        // Se for cancelamento, usa dialog com motivo obrigatório
        if (nextStatus == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA) {
          Navigator.of(_context).pop(); // Fecha dialog atual
          
          final motivo = await CancelCorridaDialog.show(
            _context,
            corridaId: numSeqChamado.toString(),
            tituloCorrida: solicitacao.desEnderecoEntrega ?? 'Corrida #$numSeqChamado',
          );
          
          if (motivo != null && motivo.isNotEmpty) {
            _controller.finalizarChamado(
              numSeqChamado,
              nextStatus,
              motivoCancelamento: motivo,
            );
          } else {
            // Usuário fechou o diálogo sem confirmar — informa que não foi cancelado
            LoginControler.showToast(
              _context,
              'Cancelamento não realizado. Informe o motivo para cancelar.',
            );
          }
          return;
        }
        
        if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
            indStatusAtualCorrida) {
          bool sucess =
              await _controller.aceitarCorrida(numSeqChamado, nextStatus);
          if (sucess) {
            if (_context.mounted) Navigator.of(_context).pop();
            // Abre GPS direto para retirada (estilo Uber/iFood)
            if (_context.mounted) await _openPickupNavigation(_context, solicitacao);
            // BUG-015: após GPS abrir, navega para corridas aceitas
            // para o motorista não ficar preso na tela de "0 corridas disponíveis"
            if (_context.mounted) {
              Navigator.pushNamed(
                _context,
                AppRoutes.corridas,
                arguments: {
                  'indTipoDefault':
                      ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA,
                },
              );
            }
          }
        } else {
          // ── Verifica se é corrida com CoD antes de encerrar ──────────
          if (nextStatus == ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA &&
              solicitacao.isCod) {
            Navigator.of(_context).pop(); // Fecha o dialog de confirmação

            final user = ApiBaseHelper.userSessao;
            final codMotorista = user?.usuarioResp?.motoristas?.firstOrNull?.codMotorista ?? 0;

            // Busca dados CoD do Firestore
            CodDelivery? codData;
            try {
              codData = await CodService.getCodDelivery(numSeqChamado);
            } catch (_) {}

            if (codData != null && _context.mounted) {
              // Abre tela de confirmação de cobrança
              final result = await Navigator.push<CodDelivery?>(
                _context,
                MaterialPageRoute(
                  builder: (_) => ConfirmacaoCobrancaScreen(
                    numSeq: numSeqChamado,
                    cod: codData!,
                    codMotorista: codMotorista,
                  ),
                ),
              );
              // Independente do resultado, finaliza a corrida no backend
              if (_context.mounted) {
                _controller.finalizarChamado(numSeqChamado, nextStatus);
              }
            } else {
              // CoD não encontrado — finaliza normalmente
              _controller.finalizarChamado(numSeqChamado, nextStatus);
            }
          } else {
            _controller.finalizarChamado(numSeqChamado, nextStatus);
          }

          if (_context.mounted) Navigator.of(_context).pop();

          // Se a corrida foi concluída (status 3), abre tela de avaliação
          if (nextStatus == ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (_context.mounted) {
              await RatingAutomaticService.openRatingScreenAfterCompletion(
                context: _context,
                corridaId: numSeqChamado.toString(),
                solicitacao: solicitacao,
                currentUserType: 'motorista',
              );
            }
          }
        }
      },
    );

    // Para nova corrida: exibe ganho em destaque antes do aceite
    Widget dialogContent;
    if (indStatusAtualCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA) {
      final ganho = solicitacao.vlrTotalMotorista;
      final ganhoText = ganho != null && ganho > 0
          ? Utils.formatBRL(ganho)
          : 'Valor a calcular';
      final enderecoRetirada = solicitacao.enderecoEmpresa ?? 'Endereço não informado';
      final enderecoEntrega = solicitacao.desEnderecoEntrega != null
          ? '${solicitacao.desEnderecoEntrega}${solicitacao.desNumeroEndereco != null ? ', ${solicitacao.desNumeroEndereco}' : ''}'
          : 'Destino não informado';
      final distancia = solicitacao.qtdKmCorrida != null
          ? '${solicitacao.qtdKmCorrida!.toStringAsFixed(1)} km'
          : null;

      dialogContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ganho em destaque
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                Text('Você receberá', style: TextStyle(fontSize: 13, color: Colors.green.shade700)),
                const SizedBox(height: 4),
                Text(
                  ganhoText,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                if (distancia != null)
                  Text(distancia, style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Rota
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.radio_button_checked, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(enderecoRetirada, style: const TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(enderecoEntrega, style: const TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Deseja aceitar esta corrida?', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ],
      );
    } else {
      dialogContent = Text("Deseja realmente ${text}?");
    }

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: indStatusAtualCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA
          ? const Text("Aceitar corrida?")
          : Text("Confirmar"),
      content: dialogContent,
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: _context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
