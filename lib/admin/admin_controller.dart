import 'package:delivery_front/bussiness/service/admin_service.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:flutter/material.dart';

class AdminController {
  final BuildContext context;

  AdminService _userService = new AdminService();

  AdminController(this.context);

  Future<List<Empresa>?> buscaEmpresas() async {
    try {
      //DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));
      var result = null;

      result = await _userService.findEmpresas();
      return result;
    } catch (e) {
      AdminController.showToast(
          context, "Erro ao buscar solicitações, tente novamente");
      List<Empresa> listResponse = [];
      return listResponse;
    } finally {
      //DialogBuilder(context).hideOpenDialog();
    }
  }

  Future<List<Motorista>?> buscaMotoristas() async {
    try {
      //DialogBuilder(context).showLoadingIndicator("");
      await Future.delayed(Duration(seconds: 1));
      var result = null;

      result = await _userService.findMotoristas();
      return result;
    } catch (e) {
      AdminController.showToast(
          context, "Erro ao buscar solicitações, tente novamente");
      List<Motorista> listResponse = [];
      return listResponse;
    } finally {
      //DialogBuilder(context).hideOpenDialog();
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
