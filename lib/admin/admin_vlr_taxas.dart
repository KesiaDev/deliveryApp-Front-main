import 'package:delivery_front/bussiness/service/admin_service.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:delivery_front/shared/models/AcoesEdicaoAdmin.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/admin/admin_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminVlrTaxasPage extends StatefulWidget {
  final Usuario userInfo;

  const AdminVlrTaxasPage({Key? key, required this.userInfo}) : super(key: key);

  @override
  _AdminVlrTaxasPage createState() => _AdminVlrTaxasPage();
}

class _AdminVlrTaxasPage extends State<AdminVlrTaxasPage>
    with WidgetsBindingObserver {
  AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
  }

  late Usuario user;

  @override
  Widget build(BuildContext context) {
    user = widget.userInfo;
    double width = MediaQuery.of(context).size.width;
    return montaTelaEmpresas(width);
  }

  Future<List<ValoresTaxas>> generateList() async {
    List<ValoresTaxas> empre = await _adminService.buscaVlrTaxas();
    return empre;

    // final response =
    //     await http.get('https://jsonplaceholder.typicode.com/posts');

    // var list = await json.decode(response.body).cast<Map<String, dynamic>>();
    // return await list.map<NameData>((json) => NameData.fromJson(json)).toList();
  }

  SafeArea montaTelaEmpresas(double width) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AdminColors.background,
        appBar: AdminAppBar(
          title: 'Taxas',
          scaffoldKey: scaffoldKey,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTaxaDialog(context),
          backgroundColor: AdminColors.primaryRed,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Nova Taxa',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        body: FutureBuilder<List<ValoresTaxas>>(
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AdminColors.cardWhite),
                      dataRowColor: MaterialStateProperty.all(AdminColors.cardWhite),
                      decoration: BoxDecoration(
                        color: AdminColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      columns: <DataColumn>[
                        DataColumn(
                          label: Text(
                            'Km Inicial',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Km Final',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Valor da taxa',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Ações',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      rows: snapShot.data!.map<DataRow>((e) {
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(
                              Text(
                                '${e.kmIni ?? 0}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AdminColors.textPrimary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${e.kmFim ?? 0}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AdminColors.textPrimary,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                'R\$ ${e.vlrTaxa?.toStringAsFixed(2) ?? '0.00'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AdminColors.primaryRed,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_rounded, color: AdminColors.primaryRed),
                                    tooltip: 'Editar',
                                    onPressed: () async {
                                      showAlertDialog(context, e);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                    tooltip: 'Excluir',
                                    onPressed: () => _excluirTaxa(context, e),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            } else {
              return AdminEmptyState(
                title: 'Nenhuma taxa encontrada',
                subtitle: 'Ainda não existem taxas configuradas no sistema.',
                icon: Icons.percent_outlined,
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _excluirTaxa(BuildContext context, ValoresTaxas taxa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AdminColors.cardWhite,
        title: Text('Excluir Taxa', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Deseja excluir a faixa ${taxa.kmIni?.toStringAsFixed(0)} – ${taxa.kmFim?.toStringAsFixed(0)} km?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Excluir', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _adminService.excluirTaxa(taxa.numSeq!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Taxa excluída com sucesso'),
        backgroundColor: AdminColors.successGreen,
      ));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao excluir: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showAddTaxaDialog(BuildContext context) {
    final kmIniCtrl = TextEditingController();
    final kmFimCtrl = TextEditingController();
    final vlrCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AdminColors.cardWhite,
        title: Text('Nova Taxa', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _taxaField(kmIniCtrl, 'Km Inicial'),
            const SizedBox(height: 12),
            _taxaField(kmFimCtrl, 'Km Final'),
            const SizedBox(height: 12),
            _taxaField(vlrCtrl, 'Valor da taxa (R\$)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: AdminColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final kmIni = double.tryParse(kmIniCtrl.text.replaceAll(',', '.'));
              final kmFim = double.tryParse(kmFimCtrl.text.replaceAll(',', '.'));
              final vlr = double.tryParse(vlrCtrl.text.replaceAll(',', '.'));
              if (kmIni == null || kmFim == null || vlr == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
                return;
              }
              Navigator.of(ctx).pop();
              try {
                final nova = ValoresTaxas(kmIni: kmIni, kmFim: kmFim, vlrTaxa: vlr, numSeq: 0);
                await _adminService.saveTaxa(nova);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Taxa criada com sucesso'),
                  backgroundColor: AdminColors.successGreen,
                ));
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Criar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _taxaField(TextEditingController ctrl, String hint) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.poppins(fontSize: 16, color: AdminColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: AdminColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.primaryRed, width: 2)),
      ),
    );
  }

  showAlertDialog(BuildContext context, ValoresTaxas sol) {
    final TextEditingController _textFieldControllerObs = TextEditingController();
    double? obsEntrega;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AdminColors.cardWhite,
          title: Text(
            "Editar Taxa",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AdminColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Km: ${sol.kmIni ?? 0} - ${sol.kmFim ?? 0}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AdminColors.textSecondary,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[],
                controller: _textFieldControllerObs,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AdminColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: "Valor da taxa",
                  hintStyle: GoogleFonts.poppins(
                    color: AdminColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AdminColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AdminColors.primaryRed, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    try {
                      obsEntrega = double.parse(value.replaceAll(',', '.'));
                    } catch (e) {
                      obsEntrega = null;
                    }
                  } else {
                    obsEntrega = null;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Necessário informar um valor válido";
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop('dialog');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AdminColors.borderColor, width: 1),
                ),
              ),
              child: Text(
                "Cancelar",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AdminColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (obsEntrega == null) {
                    LoginControler.showToast(context,
                        "Necessário informar um valor válido");
                    return;
                  }
                  sol.vlrTaxa = obsEntrega;
                  await AdminService().saveTaxa(sol);
                  final scaffold = ScaffoldMessenger.of(context);
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text("Taxa salva com sucesso"),
                      backgroundColor: AdminColors.successGreen,
                      action: SnackBarAction(
                          label: 'OK',
                          textColor: Colors.white,
                          onPressed: scaffold.hideCurrentSnackBar),
                    ),
                  );
                  Navigator.of(context, rootNavigator: true).pop('dialog');
                  setState(() {});
                } on PlatformException {
                  final scaffold = ScaffoldMessenger.of(context);
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text("Erro ao salvar taxa"),
                      backgroundColor: Colors.red,
                      action: SnackBarAction(
                          label: 'OK',
                          textColor: Colors.white,
                          onPressed: scaffold.hideCurrentSnackBar),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primaryRed,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Confirmar",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
