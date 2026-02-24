import 'package:delivery_front/confiSys/editar_config_sys_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/cadastro/cadastro_controller.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/editar_cadastro/editar_cadastro_controller.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/admin/admin_components.dart';
import 'package:google_fonts/google_fonts.dart';

class EditarConfigSysPage extends StatefulWidget {
  // Declare a field that holds the Todo.
  final ConfigSys usuarioEdicao;

  // In the constructor, require a Todo.
  EditarConfigSysPage({Key? key, required this.usuarioEdicao})
      : super(key: key);

  @override
  _EditarCadastroPage createState() => _EditarCadastroPage();
}

class _EditarCadastroPage extends State<EditarConfigSysPage> {
  late final EditarConfigSysController _controler;

  //db_enderecos
  final _seq = TextEditingController();
  final _vlrKmRodado = TextEditingController();
  final _vlrPercentualDescontoMotorista = TextEditingController();
  final _vlrTaxaApp = TextEditingController();
  final _raioBuscaCorridas = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _validateLogin(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe o um valor válido";
    }
    return null;
  }

  _onClickCadastro(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // Usa seq se existir, senão usa 1 como padrão
      _controler.setSeq(widget.usuarioEdicao.seq ?? 1);
      _controler
          .setVlrKmRodado(double.parse(_vlrKmRodado.text.replaceAll(',', '.')));
      _controler.setVlrPercentualDescontoMotorista(double.parse(
          _vlrPercentualDescontoMotorista.text.replaceAll(',', '.')));
      _controler
          .setVlrTaxaApp(double.parse(_vlrTaxaApp.text.replaceAll(',', '.')));
      _controler.setRaioBuscaCorridas(int.parse(_raioBuscaCorridas.text));

      //Colocar aqui chamada da API
      _controler.atualizarConfigSys();
    }
  }

  @override
  void initState() {
    super.initState();
    _controler = EditarConfigSysController(context);

    var user = widget.usuarioEdicao;

    // Valores padrão caso sejam null
    _vlrKmRodado.text = (user.vlrKmRodado ?? 0.0).toString();
    _vlrPercentualDescontoMotorista.text =
        (user.vlrPercentualDescontoMotorista ?? 0.0).toStringAsFixed(2);
    _vlrTaxaApp.text = (user.vlrTaxaApp ?? 0.0).toStringAsFixed(2);
    _raioBuscaCorridas.text = (user.raioBuscaCorridas ?? 25).toString();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AdminColors.background,
      appBar: AdminAppBar(
        title: 'Parâmetros do sistema',
        scaffoldKey: scaffoldKey,
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configurações do sistema',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Gerencie os parâmetros gerais da plataforma',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AdminColors.textSecondary,
                ),
              ),
              SizedBox(height: 32),
              
              // Campo: Valor km rodado
              AdminCard(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valor km rodado',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _vlrKmRodado,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => _validateLogin(value),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AdminColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ex: 2.50",
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // Campo: Raio de busca
              AdminCard(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Km para raio de busca das corridas motorista',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _raioBuscaCorridas,
                      keyboardType: TextInputType.number,
                      validator: (value) => _validateLogin(value),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AdminColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ex: 25",
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // Campo: Percentual desconto motorista
              AdminCard(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valor percentual de desconto motorista',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _vlrPercentualDescontoMotorista,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => _validateLogin(value),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AdminColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ex: 10.00",
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              
              // Campo: Valor taxa app
              AdminCard(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valor taxa app',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _vlrTaxaApp,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => _validateLogin(value),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AdminColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ex: 5.00",
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              
              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _onClickCadastro(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primaryRed,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'SALVAR CONFIGURAÇÕES',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
