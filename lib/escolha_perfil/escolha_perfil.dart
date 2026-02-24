import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/app_images.dart';
import 'package:delivery_front/core/core.dart';
import 'package:flutter/material.dart';

class EscolhaPerfil extends StatelessWidget {
  const EscolhaPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final logo = Hero(
      tag: 'hero3',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 80.0,
        child: Image.asset(
          AppImages.logo,
          height: 450,
          width: 450,
          isAntiAlias: true,
        ),
      ),
    );
    final loginPage = Padding(
      padding: EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red, // foreground
            padding: EdgeInsets.all(25),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.red),
              borderRadius: BorderRadius.circular(24),
            )),
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.login,
            arguments: {'tipoLogin': 1},
          );
        },
        // padding: EdgeInsets.all(25),
        //  color: Colors.red.shade800,
        child: const Text('LOGIN MOTORISTA', style: TextStyle(color: Colors.white)),
      ),
    );

    final cem = Padding(
      padding: EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red, // foreground
            padding: EdgeInsets.all(25),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.red),
              borderRadius: BorderRadius.circular(24),
            )),
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.login,
            arguments: {'tipoLogin': 2},
          );
        },
        //padding: EdgeInsets.all(25),
        // color: Colors.red[800],
        child: const Text('LOGIN CLIENTE', style: TextStyle(color: Colors.white)),
      ),
    );

    final textAcessar = Center(
      child: Text(
        "ACESSAR",
        style: AppTextStyles.titleBold,
      ),
    );
    final btnMotorista = TextButton(
      child: Text('MOTORISTA'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.green),
        shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24))),
      ),
      onPressed: () {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.login,
          arguments: {'tipoLogin': 1},
        );
      },
    );

    final cadastro = Padding(
      padding: EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red, // foreground
            padding: EdgeInsets.all(25),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: AppColors.red),
              borderRadius: BorderRadius.circular(24),
            )),
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.cadastro,
            arguments: {
              'tipoLogin': ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA,
            },
          );
        },
        //padding: EdgeInsets.all(25),
        //color: Colors.transparent,
        child: const Text('CADASTRO CLIENTE', style: TextStyle(color: Colors.white)),
      ),
    );

    final btnCem = TextButton(
      child: Text('CLIENTE'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.green),
        shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5))),
      ),
      onPressed: () {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.splash,
        );
      },
    );
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.linear,
        ),
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(left: 24.0, right: 24.0),
            children: <Widget>[
              logo,
              textAcessar,
              SizedBox(height: 138.0),
              loginPage,
              SizedBox(height: 8.0),
              cem,
              SizedBox(height: 28.0),
            ],
          ),
        ),
      ),
    );
  }
}
