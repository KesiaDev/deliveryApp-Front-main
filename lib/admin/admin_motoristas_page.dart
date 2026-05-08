import 'package:brasil_fields/brasil_fields.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/FileProcess.dart';
import 'package:delivery_front/bussiness/service/admin_service.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/shared/models/AcoesEdicaoAdmin.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/admin/admin_components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_controller.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

class AdminMotoristaPage extends StatefulWidget {
  final Usuario userInfo;

  const AdminMotoristaPage({Key? key, required this.userInfo})
      : super(key: key);

  @override
  _AdminMotoristaPage createState() => _AdminMotoristaPage();
}

class _AdminMotoristaPage extends State<AdminMotoristaPage>
    with WidgetsBindingObserver {
  AdminController? _userService;
  AdminService _adminService = AdminService();
  final Set<int> _motoristasExcluidos = {}; // Lista de motoristas excluídos localmente

  var _indTipoPgto;

  @override
  void initState() {
    super.initState();
    _userService = AdminController(context);
  }

  late Usuario user;

  @override
  Widget build(BuildContext context) {
    user = widget.userInfo;
    double width = MediaQuery.of(context).size.width;
    return montaTelaEmpresas(width);
  }

  Future<List<Motorista>> generateList() async {
    List<Motorista>? empre = await _userService?.buscaMotoristas();

    if (empre != null) {
      // Filtra motoristas excluídos localmente
      final filtered = empre.where((m) {
        final codUsuario = m.user?.codUsuario;
        final codMotorista = m.codMotorista;
        return !_motoristasExcluidos.contains(codUsuario) &&
               !_motoristasExcluidos.contains(codMotorista);
      }).toList();

      // Deduplica por codMotorista — evita exibir registros duplicados do banco
      final seenIds = <int>{};
      return filtered.where((m) {
        if (m.codMotorista == null) return true;
        return seenIds.add(m.codMotorista!);
      }).toList();
    } else {
      return <Motorista>[];
    }
  }

  Future<void> _excluirMotorista(Motorista motorista) async {
    final nomeMotorista = motorista.desRazaoSocial ?? motorista.desNomeFantasia ?? 'Motorista';
    
    // Confirmação antes de excluir
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Exclusão'),
        content: Text(
          'Você está prestes a EXCLUIR permanentemente o motorista:\n\n'
          '"$nomeMotorista"\n\n'
          'Esta ação NÃO pode ser desfeita!\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );

    if (confirmacao != true) return;

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final codUsuario = motorista.user?.codUsuario;
      final codMotorista = motorista.codMotorista;
      
      // Tenta excluir permanentemente via API
      bool excluido = await _adminService.excluirMotorista(codUsuario, codMotorista);
      
      // Se não conseguiu excluir via API, tenta bloquear com valor especial (99 = excluído)
      if (!excluido && codUsuario != null) {
        try {
          // Tenta bloquear com valor 99 (pode ser interpretado como exclusão no backend)
          await _adminService.changeStatusUser(codUsuario, 99);
          excluido = true; // Considera como excluído
        } catch (e) {
          // Se falhar, continua
        }
      }
      
      Navigator.of(context).pop(); // Fecha loading

      if (excluido) {
        showToast(context, 'Motorista excluído com sucesso!');
        // Marca como excluído localmente
        if (codMotorista != null) {
          _motoristasExcluidos.add(codMotorista);
        }
        if (codUsuario != null) {
          _motoristasExcluidos.add(codUsuario);
        }
        setState(() {}); // Atualiza a lista
      } else {
        // Se não conseguiu excluir, pergunta se quer remover da lista localmente
        final removerLocal = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Exclusão não disponível na API'),
            content: const Text(
              'O endpoint de exclusão não está implementado na API.\n\n'
              'Deseja remover o motorista da lista localmente?\n\n'
              '⚠️ O motorista ainda existirá no servidor, mas não aparecerá mais nesta lista até você recarregar a página.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Remover Localmente'),
              ),
            ],
          ),
        );

        if (removerLocal == true) {
          // Marca como excluído localmente
          if (codMotorista != null) {
            _motoristasExcluidos.add(codMotorista);
          }
          if (codUsuario != null) {
            _motoristasExcluidos.add(codUsuario);
          }
          showToast(context, 'Motorista removido da lista localmente.\n⚠️ Ainda existe no servidor.');
          setState(() {}); // Atualiza a lista
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Fecha loading
      showToast(context, 'Erro ao excluir motorista: $e');
    }
  }

  Future<void> _excluirTodosMotoristas() async {
    // Confirmação antes de excluir
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Exclusão'),
        content: const Text(
          'Você está prestes a EXCLUIR permanentemente TODOS os motoristas cadastrados.\n\n'
          'Esta ação NÃO pode ser desfeita!\n\n'
          '⚠️ ATENÇÃO: Esta é uma ação irreversível!\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('EXCLUIR TODOS'),
          ),
        ],
      ),
    );

    if (confirmacao != true) return;

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Busca todos os motoristas
      final motoristas = await _userService?.buscaMotoristas() ?? [];
      
      if (motoristas.isEmpty) {
        Navigator.of(context).pop(); // Fecha loading
        showToast(context, 'Nenhum motorista encontrado para excluir.');
        return;
      }

      int sucesso = 0;
      int erros = 0;

      // Exclui cada motorista
      for (var motorista in motoristas) {
        final codUsuario = motorista.user?.codUsuario;
        final codMotorista = motorista.codMotorista;
        
        if (codUsuario != null || codMotorista != null) {
          try {
            bool excluido = await _adminService.excluirMotorista(codUsuario, codMotorista);
            
            if (!excluido && codUsuario != null) {
              // Tenta bloquear com valor 99 como fallback
              try {
                await _adminService.changeStatusUser(codUsuario, 99);
                excluido = true;
              } catch (e) {
                // Ignora
              }
            }
            
            if (excluido) {
              sucesso++;
              // Marca como excluído localmente
              if (codMotorista != null) {
                _motoristasExcluidos.add(codMotorista);
              }
              if (codUsuario != null) {
                _motoristasExcluidos.add(codUsuario);
              }
            } else {
              erros++;
            }
          } catch (e) {
            erros++;
            print('Erro ao excluir motorista ${motorista.desRazaoSocial ?? motorista.desNomeFantasia}: $e');
          }
        }
      }

      Navigator.of(context).pop(); // Fecha loading

      // Mostra resultado
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Processo Concluído'),
          content: Text(
            'Motoristas processados:\n'
            '✅ Excluídos: $sucesso\n'
            '❌ Erros: $erros\n'
            '📦 Total: ${motoristas.length}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {}); // Atualiza a lista
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fecha loading
      showToast(context, 'Erro ao excluir motoristas: $e');
    }
  }

  criaDropDownButton(Motorista empre) {
    return Container(
      child: Column(
        children: <Widget>[
          DropdownButton<AcoesEdicaoAdmin>(
              hint: Text(
                'Opções',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                ),
              ),
              items: getTiposAcoesMotorista().map((dropDownStringItem) {
                return DropdownMenuItem<AcoesEdicaoAdmin>(
                  value: dropDownStringItem,
                  child: Text(dropDownStringItem.desTipo),
                );
              }).toList(),
              onChanged: (AcoesEdicaoAdmin? novoItemSelecionado) {
                if (novoItemSelecionado!.indTipo == 1) {
                  int indTipo = ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA;
                  UsuarioResp? usuarioResp =
                      UsuarioResp(desNome: empre.desNomeFantasia);
                  List<Motorista> list = <Motorista>[];
                  list.add(empre);

                  usuarioResp.motoristas = list;
                  Usuario userConsulta = Usuario(
                      desNome: empre.desRazaoSocial,
                      indTipo: indTipo,
                      codUsuario: empre.user!.codUsuario);
                  userConsulta.usuarioResp = usuarioResp;
                  Navigator.pushNamed(
                    context,
                    AppRoutes.saldos,
                    arguments: {
                      'isAdm': true,
                      'userConsulta': userConsulta,
                    },
                  );
                }
                if (novoItemSelecionado.indTipo == 3) {
                  () async {
                    if (empre.user?.indBloqueado == 1) {
                      await _adminService.changeStatusUser(empre.user!.codUsuario, 0);
                      empre.user!.indBloqueado = 0;
                    } else if (empre.user?.indBloqueado == null ||
                        empre.user?.indBloqueado == 0) {
                      await _adminService.changeStatusUser(empre.user!.codUsuario, 1);
                      empre.user!.indBloqueado = 1;
                    }
                    if (mounted) setState(() {});
                  }();
                }

                if (novoItemSelecionado.indTipo == 4) {
                  setState(() async {
                    if (empre.desCarteira == null ||
                        empre.desNomeCarteira == "") {
                      showToast(context, "Nenhum item encontrado!");
                      return;
                    }

                    final abreviatura = empre.desNomeCarteira!.contains(".pdf")
                        ? "data:application/pdf;base64,"
                        : "data:image/png;base64,";

                    final urlString = abreviatura + (empre.desCarteira ?? "");
                    if (kIsWeb) {
                      html.AnchorElement anchorElement =
                          html.AnchorElement(href: urlString);
                      anchorElement.download = urlString;
                      anchorElement.click();
                    } else {
                      await FileProcess.downloadFile(
                          (empre.desCarteira ?? ""), empre.desNomeCarteira!);
                      FileProcess.openFile(empre.desNomeCarteira!);
                    }
                  });
                }

                if (novoItemSelecionado.indTipo == 5) {
                  setState(() async {
                    if (empre.desCartao == null || empre.desNomeCartao == "") {
                      showToast(context, "Nenhum item encontrado!");
                      return;
                    }

                    final abreviatura = empre.desNomeCartao!.contains(".pdf")
                        ? "data:application/pdf;base64,"
                        : "data:image/png;base64,";

                    final urlString = abreviatura + (empre.desCartao ?? "");

                    if (kIsWeb) {
                      html.AnchorElement anchorElement =
                          html.AnchorElement(href: urlString);
                      anchorElement.download = urlString;
                      anchorElement.click();
                    } else {
                      await FileProcess.downloadFile(
                          (empre.desCartao ?? ""), empre.desNomeCartao!);
                      FileProcess.openFile(empre.desNomeCartao!);
                    }
                  });
                }

                //_dropDownItemSelected(novoItemSelecionado!);
              },
              value: _indTipoPgto),
        ],
      ),
    );
  }

  void _dropDownItemSelected(AcoesEdicaoAdmin novoItem) {
    _indTipoPgto = novoItem;
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

  Future<void> _bloquearTodosMotoristas() async {
    // Confirmação antes de bloquear
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Ação'),
        content: const Text(
          'Você está prestes a BLOQUEAR todos os motoristas cadastrados.\n\n'
          'Esta ação não pode ser desfeita facilmente.\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('BLOQUEAR TODOS'),
          ),
        ],
      ),
    );

    if (confirmacao != true) return;

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Busca todos os motoristas
      final motoristas = await _userService?.buscaMotoristas() ?? [];
      
      if (motoristas.isEmpty) {
        Navigator.of(context).pop(); // Fecha loading
        showToast(context, 'Nenhum motorista encontrado para bloquear.');
        return;
      }

      int sucesso = 0;
      int erros = 0;

      // Bloqueia cada motorista
      for (var motorista in motoristas) {
        if (motorista.user?.codUsuario != null) {
          try {
            await _adminService.changeStatusUser(
              motorista.user!.codUsuario,
              1, // 1 = bloqueado
            );
            sucesso++;
          } catch (e) {
            erros++;
            print('Erro ao bloquear motorista ${motorista.desRazaoSocial ?? motorista.desNomeFantasia}: $e');
          }
        }
      }

      Navigator.of(context).pop(); // Fecha loading

      // Mostra resultado
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Processo Concluído'),
          content: Text(
            'Motoristas processados:\n'
            '✅ Bloqueados: $sucesso\n'
            '❌ Erros: $erros\n'
            '📦 Total: ${motoristas.length}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {}); // Atualiza a lista
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fecha loading
      showToast(context, 'Erro ao bloquear motoristas: $e');
    }
  }

  SafeArea montaTelaEmpresas(double width) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AdminColors.background,
        appBar: AdminAppBar(
          title: 'Motoristas',
          scaffoldKey: scaffoldKey,
          actions: [
            // Botão para excluir todos os motoristas
            IconButton(
              icon: Icon(Icons.delete_forever_rounded, color: Colors.red),
              tooltip: 'Excluir todos os motoristas',
              onPressed: () => _excluirTodosMotoristas(),
            ),
            // Botão para bloquear todos os motoristas
            IconButton(
              icon: Icon(Icons.block_rounded, color: AdminColors.textPrimary),
              tooltip: 'Bloquear todos os motoristas',
              onPressed: () => _bloquearTodosMotoristas(),
            ),
          ],
        ),
        body: FutureBuilder<List<Motorista>>(
          future: generateList(),
          builder: (context, snapShot) {
            if (snapShot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryRed),
                ),
              );
            }

            if (snapShot.hasData && snapShot.data!.isNotEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                color: AdminColors.primaryRed,
                child: ListView.separated(
                  padding: EdgeInsets.all(20),
                  itemCount: snapShot.data!.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final motorista = snapShot.data![index];
                    return _buildMotoristaCard(motorista);
                  },
                ),
              );
            } else {
              return AdminEmptyState(
                title: 'Nenhum motorista encontrado',
                subtitle: 'Ainda não existem motoristas cadastrados na plataforma.',
                icon: Icons.person_outline_rounded,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMotoristaCard(Motorista motorista) {
    final nome = motorista.desRazaoSocial ?? motorista.desNomeFantasia ?? 'Sem nome';
    final cpfCnpj = UtilBrasilFields.isCNPJValido(motorista.desCpfCnpj)
        ? UtilBrasilFields.obterCnpj(motorista.desCpfCnpj!)
        : UtilBrasilFields.isCPFValido(motorista.desCpfCnpj)
            ? UtilBrasilFields.obterCpf(motorista.desCpfCnpj!)
            : motorista.desCpfCnpj ?? 'N/A';
    final isBloqueado = motorista.user?.indBloqueado == 1;
    final isOnline = motorista.user?.indOffline == 0;

    return AdminCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AdminColors.primaryRed.withOpacity(0.1),
                child: Text(
                  nome.toUpperCase().substring(0, 1),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.primaryRed,
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Nome e CPF
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      cpfCnpj,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              AdminStatusBadge(
                text: isBloqueado
                    ? 'Bloqueado'
                    : isOnline
                        ? 'Online'
                        : 'Offline',
                isActive: isOnline && !isBloqueado,
                isBlocked: isBloqueado,
              ),
            ],
          ),
          SizedBox(height: 16),
          // Botões de ação - usando Wrap para evitar overflow
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                icon: Icons.attach_money_rounded,
                label: 'Valores',
                onTap: () {
                  int indTipo = ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA;
                  UsuarioResp? usuarioResp =
                      UsuarioResp(desNome: motorista.desNomeFantasia);
                  List<Motorista> list = <Motorista>[];
                  list.add(motorista);
                  usuarioResp.motoristas = list;
                  Usuario userConsulta = Usuario(
                      desNome: motorista.desRazaoSocial,
                      indTipo: indTipo,
                      codUsuario: motorista.user!.codUsuario);
                  userConsulta.usuarioResp = usuarioResp;
                  Navigator.pushNamed(
                    context,
                    AppRoutes.saldos,
                    arguments: {
                      'isAdm': true,
                      'userConsulta': userConsulta,
                    },
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.edit_rounded,
                label: 'Editar',
                onTap: () {
                  // TODO: Implementar edição
                  showToast(context, 'Funcionalidade em desenvolvimento');
                },
              ),
              _buildActionButton(
                icon: isBloqueado ? Icons.lock_open_rounded : Icons.lock_rounded,
                label: isBloqueado ? 'Desbloquear' : 'Bloquear',
                onTap: () async {
                  if (motorista.user?.indBloqueado == 1) {
                    await _adminService.changeStatusUser(motorista.user!.codUsuario, 0);
                    motorista.user!.indBloqueado = 0;
                  } else if (motorista.user?.indBloqueado == null ||
                      motorista.user?.indBloqueado == 0) {
                    await _adminService.changeStatusUser(motorista.user!.codUsuario, 1);
                    motorista.user!.indBloqueado = 1;
                  }
                  if (mounted) setState(() {});
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AdminColors.secondaryGray),
                onSelected: (value) {
                  if (value == 'excluir') {
                    _excluirMotorista(motorista);
                  } else if (value == 'carteira') {
                    if (motorista.desCarteira == null ||
                        motorista.desNomeCarteira == "") {
                      showToast(context, "Nenhum item encontrado!");
                      return;
                    }
                    _downloadFile(motorista.desCarteira!, motorista.desNomeCarteira!);
                  } else if (value == 'cartao') {
                    if (motorista.desCartao == null || motorista.desNomeCartao == "") {
                      showToast(context, "Nenhum item encontrado!");
                      return;
                    }
                    _downloadFile(motorista.desCartao!, motorista.desNomeCartao!);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Excluir', style: GoogleFonts.poppins(fontSize: 14, color: Colors.red)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'carteira',
                    child: Row(
                      children: [
                        Icon(Icons.credit_card_rounded, size: 20, color: AdminColors.textPrimary),
                        SizedBox(width: 12),
                        Text('Ver carteira', style: GoogleFonts.poppins(fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'cartao',
                    child: Row(
                      children: [
                        Icon(Icons.badge_rounded, size: 20, color: AdminColors.textPrimary),
                        SizedBox(width: 12),
                        Text('Ver cartão', style: GoogleFonts.poppins(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AdminColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AdminColors.primaryRed),
            SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AdminColors.primaryRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(String base64, String fileName) async {
    final abreviatura = fileName.contains(".pdf")
        ? "data:application/pdf;base64,"
        : "data:image/png;base64,";
    final urlString = abreviatura + base64;
    if (kIsWeb) {
      html.AnchorElement anchorElement = html.AnchorElement(href: urlString);
      anchorElement.download = urlString;
      anchorElement.click();
    } else {
      await FileProcess.downloadFile(base64, fileName);
      FileProcess.openFile(fileName);
    }
  }
}
