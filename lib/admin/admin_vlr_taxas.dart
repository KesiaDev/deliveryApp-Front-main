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
                              IconButton(
                                icon: Icon(
                                  Icons.edit_rounded,
                                  color: AdminColors.primaryRed,
                                ),
                                onPressed: () async {
                                  showAlertDialog(context, e);
                                },
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
