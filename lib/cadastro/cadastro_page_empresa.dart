import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/cadastro/cadastro_controller.dart';
import 'package:delivery_front/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CadastroPageEmpresa extends StatefulWidget {
  @override
  _CadastroPageEmpresa createState() => _CadastroPageEmpresa();
}

class _CadastroPageEmpresa extends State<CadastroPageEmpresa> {
  late final CadastroController _controler;
  var _tMeuLogin = TextEditingController();
  final _tMinhaSenha = TextEditingController();
  var _tMeuNome = TextEditingController();
  final _tEmailMotorista = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _validateLogin(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe o login";
    }
    return null;
  }

  String? _validateSenha(String? text) {
    if (ApiBaseHelper.userSessao != null &&
        ApiBaseHelper.userSessao!.codUsuario == null) {
      if (text == null || text.isEmpty) {
        return "Informe a senha";
      }
    }
    return null;
  }

  String? _validateNome(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe um nome para o cadastro";
    }
    return null;
  }

  String? _validateEmailMotorista(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe um e-mail de motorista amigo para o cadastro";
    }
    return null;
  }

  _onClickCadastro(BuildContext context) {
    final meuLogin = _tMeuLogin.text;
    final minhaSenha = _tMinhaSenha.text;
    final meuNome = _tMeuNome.text;
    final emailMotorista = _tEmailMotorista.text;
    //print("Login: $login , Senha: $senha ");

    if (_formKey.currentState!.validate()) {
      _controler.setEmail(meuLogin);
      _controler.setSenha(minhaSenha);
      _controler.setNome(meuNome);
      _controler.setEmailMotoristaAmigo(emailMotorista);
      //Colocar aqui chamada da API
      _controler.registraCem(1);
    }
  }

  @override
  void initState() {
    super.initState();
    _controler = CadastroController(context);
    if (ApiBaseHelper.userSessao != null) {
      if (ApiBaseHelper.userSessao!.usuario != null)
        _tMeuLogin.text = ApiBaseHelper.userSessao!.usuario!;

      if (ApiBaseHelper.userSessao!.desNome != null)
        _tMeuNome.text = ApiBaseHelper.userSessao!.desNome!;
    }
  }

  bool _isObscure = true;
  @override
  Widget build(BuildContext context) {
    final logo = Hero(
      tag: 'hero',
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

    final textAcessar = Center(
      child: Text(
        "CADASTRO",
        style: AppTextStyles.titleBold,
      ),
    );

    final meuEmail = TextFormField(
      controller: _tMeuLogin,
      validator: (value) => _validateLogin(value!),
      keyboardType: TextInputType.emailAddress,
      autofocus: true,

      //initialValue: 'alucard@gmail.com',
      decoration: InputDecoration(
        labelText: (ApiBaseHelper.userSessao!.indTipo == 2 ||
                ApiBaseHelper.userSessao!.indTipo == null
            ? 'Meu E-mail'
            : 'E-mail do amigo'),
        border: UnderlineInputBorder(),
        hintText: (ApiBaseHelper.userSessao!.indTipo == 2 ||
                ApiBaseHelper.userSessao!.indTipo == null
            ? 'Meu E-mail'
            : 'E-mail do amigo'),
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
      ),
    );

    final meuNome = TextFormField(
      keyboardType: TextInputType.name,
      controller: _tMeuNome,
      validator: (value) => _validateNome(value!),
      autofocus: true,
      //initialValue: 'alucard@gmail.com',
      decoration: InputDecoration(
        labelText: (ApiBaseHelper.userSessao!.indTipo == 2 ||
                ApiBaseHelper.userSessao!.indTipo == null
            ? 'Meu Nome'
            : 'Nome do amigo'),
        border: UnderlineInputBorder(),
        hintText: (ApiBaseHelper.userSessao!.indTipo == 2 ||
                ApiBaseHelper.userSessao!.indTipo == null
            ? 'Meu Nome'
            : 'Nome do amigo'),
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
      ),
    );

    final minhaSenha = TextFormField(
      autofocus: false,
      //initialValue: 'some password',
      obscureText: _isObscure,
      controller: _tMinhaSenha,
      validator: (value) => _validateSenha(value!),
      autocorrect: false,
      decoration: InputDecoration(
        labelText: (ApiBaseHelper.userSessao!.indTipo == 2 ||
                ApiBaseHelper.userSessao!.indTipo == null
            ? 'Minha Senha'
            : 'Senha do amigo'),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility : Icons.visibility_off,
            color: Colors.red.shade800,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
        hintText: (ApiBaseHelper.userSessao!.indTipo == 2 ||
                ApiBaseHelper.userSessao!.indTipo == null
            ? 'Minha Senha'
            : 'Senha do amigo'),
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
    );

    final emailMotoristaAmigo = TextFormField(
      controller: _tEmailMotorista,
      validator: (value) => _validateEmailMotorista(value!),
      keyboardType: TextInputType.emailAddress,
      autofocus: true,

      //initialValue: 'alucard@gmail.com',
      decoration: InputDecoration(
        labelText: (ApiBaseHelper.userSessao!.indTipo == 2 ||
                ApiBaseHelper.userSessao!.indTipo == null
            ? 'E-mail motorista amigo'
            : 'E-mail Guardião'),
        border: UnderlineInputBorder(),
        hintText: (ApiBaseHelper.userSessao!.indTipo == 2 ||
                ApiBaseHelper.userSessao!.indTipo == null
            ? 'E-mail motorista amigo'
            : 'E-mail Guardião'),
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
      ),
    );

    final enviarButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
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
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => SplashPage()),
          // );
          _onClickCadastro(context);
        },
        //padding: EdgeInsets.all(25),
        //color: Colors.red[800],
        child: Text('ENVIAR', style: TextStyle(color: Colors.white)),
      ),
    );
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.linear,
        ),
        child: Center(
          child: Form(
            key: _formKey,
            child: (ApiBaseHelper.userSessao!.indTipo != 1
                ? ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(left: 24.0, right: 24.0),
                    children: <Widget>[
                      logo,
                      textAcessar,
                      SizedBox(height: 90.0),
                      (ApiBaseHelper.userSessao!.indTipo == 2
                          ? Center()
                          : meuEmail),
                      SizedBox(height: 8.0),
                      (ApiBaseHelper.userSessao!.indTipo == 2
                          ? Center()
                          : minhaSenha),
                      SizedBox(height: 8.0),
                      (ApiBaseHelper.userSessao!.indTipo == 2
                          ? Center()
                          : meuNome),
                      SizedBox(height: 8.0),
                      (ApiBaseHelper.userSessao!.indTipo != 2
                          ? Center()
                          : emailMotoristaAmigo),
                      SizedBox(height: 24.0),
                      enviarButton,
                    ],
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(left: 24.0, right: 24.0),
                    children: <Widget>[
                      logo,
                      textAcessar,
                      SizedBox(height: 90.0),
                      emailMotoristaAmigo,
                      SizedBox(height: 24.0),
                      enviarButton,
                    ],
                  )),
          ),
        ),
      ),
    );
  }
}
