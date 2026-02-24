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

class AdminEmpresaPage extends StatefulWidget {
  final Usuario userInfo;

  const AdminEmpresaPage({Key? key, required this.userInfo}) : super(key: key);

  @override
  _AdminEmpresaPage createState() => _AdminEmpresaPage();
}

class _AdminEmpresaPage extends State<AdminEmpresaPage>
    with WidgetsBindingObserver {
  AdminController? _userService;
  AdminService _adminService = AdminService();

  var _indTipoPgto;
  List<Empresa>? _empresasCache; // Cache da lista de empresas
  Set<int> _empresasExcluidas = {}; // IDs de empresas excluídas localmente

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

  Future<List<Empresa>> generateList() async {
    List<Empresa>? empre = await _userService?.buscaEmpresas();

    if (empre != null) {
      // Filtra empresas excluídas localmente
      _empresasCache = empre;
      return empre.where((e) {
        final codEmpresa = e.codEmpresa;
        final codUsuario = e.user?.codUsuario;
        // Remove se foi excluída localmente
        if (codEmpresa != null && _empresasExcluidas.contains(codEmpresa)) {
          return false;
        }
        if (codUsuario != null && _empresasExcluidas.contains(codUsuario)) {
          return false;
        }
        return true;
      }).toList();
    } else {
      return <Empresa>[];
    }
  }

  criaDropDownButton(Empresa empre) {
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
              items: getTiposAcoesEmpresa().map((dropDownStringItem) {
                return DropdownMenuItem<AcoesEdicaoAdmin>(
                  value: dropDownStringItem,
                  child: Text(dropDownStringItem.desTipo),
                );
              }).toList(),
              onChanged: (AcoesEdicaoAdmin? novoItemSelecionado) {
                if (novoItemSelecionado!.indTipo == 1) {
                  int indTipo = ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA;
                  UsuarioResp? usuarioResp =
                      UsuarioResp(desNome: empre.desNomeFantasia);
                  List<Empresa> list = <Empresa>[];
                  list.add(empre);

                  usuarioResp.empresas = list;
                  Usuario userConsulta =
                      Usuario(desNome: empre.desRazaoSocial, indTipo: indTipo);
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
                  if (empre.user?.indBloqueado == 1) {
                    _adminService.changeStatusUser(empre.user!.codUsuario, 0);
                    empre.user!.indBloqueado = 0;
                  } else if (empre.user?.indBloqueado == null ||
                      empre.user?.indBloqueado == 0) {
                    _adminService.changeStatusUser(empre.user!.codUsuario, 1);
                    empre.user!.indBloqueado = 1;
                  }

                  setState(() {});
                }

                if (novoItemSelecionado.indTipo == 4) {
                  // Excluir empresa
                  _excluirEmpresa(empre);
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

  Future<void> _excluirEmpresa(Empresa empresa) async {
    final nomeEmpresa = empresa.desNomeFantasia ?? empresa.desRazaoSocial ?? 'Empresa';
    
    // Confirmação antes de excluir
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Exclusão'),
        content: Text(
          'Você está prestes a EXCLUIR permanentemente a empresa:\n\n'
          '"$nomeEmpresa"\n\n'
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
      final codUsuario = empresa.user?.codUsuario;
      final codEmpresa = empresa.codEmpresa;
      
      // Tenta excluir permanentemente via API
      bool excluido = await _adminService.excluirEmpresa(codUsuario, codEmpresa);
      
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
        showToast(context, 'Empresa excluída com sucesso!');
        // Marca como excluída localmente
        if (codEmpresa != null) {
          _empresasExcluidas.add(codEmpresa);
        }
        if (codUsuario != null) {
          _empresasExcluidas.add(codUsuario);
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
              'Deseja remover a empresa da lista localmente?\n\n'
              '⚠️ A empresa ainda existirá no servidor, mas não aparecerá mais nesta lista até você recarregar a página.',
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
          // Marca como excluída localmente
          if (codEmpresa != null) {
            _empresasExcluidas.add(codEmpresa);
          }
          if (codUsuario != null) {
            _empresasExcluidas.add(codUsuario);
          }
          showToast(context, 'Empresa removida da lista localmente.\n⚠️ Ainda existe no servidor.');
          setState(() {}); // Atualiza a lista
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Fecha loading
      showToast(context, 'Erro ao excluir empresa: $e');
    }
  }

  Future<void> _bloquearTodasEmpresas() async {
    // Confirmação antes de bloquear
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Ação'),
        content: const Text(
          'Você está prestes a BLOQUEAR todas as empresas cadastradas.\n\n'
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
            child: const Text('BLOQUEAR TODAS'),
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
      // Busca todas as empresas
      final empresas = await _userService?.buscaEmpresas() ?? [];
      
      if (empresas.isEmpty) {
        Navigator.of(context).pop(); // Fecha loading
        showToast(context, 'Nenhuma empresa encontrada para bloquear.');
        return;
      }

      int sucesso = 0;
      int erros = 0;

      // Bloqueia cada empresa
      for (var empresa in empresas) {
        if (empresa.user?.codUsuario != null) {
          try {
            await _adminService.changeStatusUser(
              empresa.user!.codUsuario,
              1, // 1 = bloqueado
            );
            sucesso++;
          } catch (e) {
            erros++;
            print('Erro ao bloquear empresa ${empresa.desNomeFantasia}: $e');
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
            'Empresas processadas:\n'
            '✅ Bloqueadas: $sucesso\n'
            '❌ Erros: $erros\n'
            '📦 Total: ${empresas.length}',
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
      showToast(context, 'Erro ao bloquear empresas: $e');
    }
  }

  SafeArea montaTelaEmpresas(double width) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AdminColors.background,
        appBar: AdminAppBar(
          title: 'Empresas',
          scaffoldKey: scaffoldKey,
          actions: [
            // Botão para bloquear todas as empresas
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: AdminColors.textPrimary),
              tooltip: 'Bloquear todas as empresas',
              onPressed: () => _bloquearTodasEmpresas(),
            ),
          ],
        ),
        body: FutureBuilder<List<Empresa>>(
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
                    final empresa = snapShot.data![index];
                    return _buildEmpresaCard(empresa);
                  },
                ),
              );
            } else {
              return AdminEmptyState(
                title: 'Nenhuma empresa encontrada',
                subtitle: 'Ainda não existem empresas cadastradas na plataforma.',
                icon: Icons.business_outlined,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmpresaCard(Empresa empresa) {
    final nome = empresa.desRazaoSocial ?? empresa.desNomeFantasia ?? 'Sem nome';
    final nomeFantasia = empresa.desNomeFantasia ?? '';
    final cnpj = UtilBrasilFields.isCNPJValido(empresa.desCpfCnpj)
        ? UtilBrasilFields.obterCnpj(empresa.desCpfCnpj!)
        : UtilBrasilFields.isCPFValido(empresa.desCpfCnpj)
            ? UtilBrasilFields.obterCpf(empresa.desCpfCnpj!)
            : empresa.desCpfCnpj ?? 'N/A';
    final isBloqueada = empresa.user?.indBloqueado == 1;

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
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Icon(
                  Icons.business_rounded,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              // Nome e CNPJ
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
                    if (nomeFantasia.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        nomeFantasia,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                    SizedBox(height: 4),
                    Text(
                      cnpj,
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
                text: isBloqueada ? 'Bloqueada' : 'Ativa',
                isActive: !isBloqueada,
                isBlocked: isBloqueada,
              ),
            ],
          ),
          SizedBox(height: 16),
          // Botões de ação
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                icon: Icons.attach_money_rounded,
                label: 'Valores',
                onTap: () {
                  int indTipo = ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA;
                  UsuarioResp? usuarioResp =
                      UsuarioResp(desNome: empresa.desNomeFantasia);
                  List<Empresa> list = <Empresa>[];
                  list.add(empresa);
                  usuarioResp.empresas = list;
                  Usuario userConsulta =
                      Usuario(desNome: empresa.desRazaoSocial, indTipo: indTipo);
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
              SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.edit_rounded,
                label: 'Editar',
                onTap: () {
                  // TODO: Implementar edição
                  showToast(context, 'Funcionalidade em desenvolvimento');
                },
              ),
              SizedBox(width: 8),
              _buildActionButton(
                icon: isBloqueada ? Icons.lock_open_rounded : Icons.lock_rounded,
                label: isBloqueada ? 'Desbloquear' : 'Bloquear',
                onTap: () {
                  if (empresa.user?.indBloqueado == 1) {
                    _adminService.changeStatusUser(empresa.user!.codUsuario, 0);
                    empresa.user!.indBloqueado = 0;
                  } else if (empresa.user?.indBloqueado == null ||
                      empresa.user?.indBloqueado == 0) {
                    _adminService.changeStatusUser(empresa.user!.codUsuario, 1);
                    empresa.user!.indBloqueado = 1;
                  }
                  setState(() {});
                },
              ),
              SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AdminColors.secondaryGray),
                onSelected: (value) {
                  if (value == 'excluir') {
                    _excluirEmpresa(empresa);
                  } else if (value == 'cartao') {
                    if (empresa.desCartao == null || empresa.desNomeCartao == "") {
                      showToast(context, "Nenhum item encontrado!");
                      return;
                    }
                    _downloadFile(empresa.desCartao!, empresa.desNomeCartao!);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'cartao',
                    child: Row(
                      children: [
                        Icon(Icons.credit_card_rounded, size: 20, color: AdminColors.textPrimary),
                        SizedBox(width: 12),
                        Text('Ver cartão', style: GoogleFonts.poppins(fontSize: 14)),
                      ],
                    ),
                  ),
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
