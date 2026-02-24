import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/shared/components/customException.dart';
import 'package:delivery_front/shared/components/loading_dialog.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:flutter/material.dart';

class EditarConfigSysController {
  final BuildContext context;

  UserService _userService = new UserService();

  EditarConfigSysController(this.context);

  int? seq, raioBuscaCorridas;
  double? vlrKmRodado, vlrPercentualDescontoMotorista, vlrTaxaApp;

  void setSeq(int s) => seq = s;
  void setVlrKmRodado(double s) => vlrKmRodado = s;
  void setVlrPercentualDescontoMotorista(double s) =>
      vlrPercentualDescontoMotorista = s;
  void setVlrTaxaApp(double s) => vlrTaxaApp = s;
  void setRaioBuscaCorridas(int s) => raioBuscaCorridas = s;

  ConfigSys get credential => ConfigSys(
      seq: seq,
      vlrKmRodado: vlrKmRodado,
      vlrPercentualDescontoMotorista: vlrPercentualDescontoMotorista,
      vlrTaxaApp: vlrTaxaApp,
      raioBuscaCorridas: raioBuscaCorridas);

  Future<void> atualizarConfigSys() async {
    try {
      DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));
      var result = await _userService.atualizaConfigSys(credential);

      showToast(context, "Cadastro Atualizado com sucesso!!!");
      await Future.delayed(Duration(seconds: 1));
      Navigator.pop(context, 1);
    } on CustomException catch (e) {
      showToast(
          context, "Erro ao efetuar cadastro, tente novamente: " + e.message);
    } catch (e) {
      showToast(context, "Erro ao efetuar cadastro, tente novamente");
    } finally {
      DialogBuilder(context).hideOpenDialog();
    }
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
}
