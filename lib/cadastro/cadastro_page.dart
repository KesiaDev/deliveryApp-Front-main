import 'dart:convert';

import 'package:brasil_fields/brasil_fields.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/FileProcess.dart';
import 'package:delivery_front/bussiness/service/CnpjService.dart';
import 'package:delivery_front/bussiness/service/ViaCepService.dart';
import 'package:delivery_front/cadastro/cadastro_controller.dart';
import 'package:delivery_front/core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

class CadastroPage extends StatefulWidget {
  final int tipoLogin;

  CadastroPage({Key? key, required this.tipoLogin, this.tipoPagina})
      : super(key: key);

  int? tipoPagina = 1;
  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  late final CadastroController _controler;
  var _tMeuLogin = TextEditingController();
  final _tMinhaSenha = TextEditingController();
  var _tMeuNome = TextEditingController();
  final _tEmailMotorista = TextEditingController();
  late FocusNode focusNodeNumero;

  late var desImgCarteria = "";
  var desNomeCarteira = "";
  var desImgCartao = "";
  var desNomeCartao = "";

  // Estado para controle da consulta CNPJ
  bool _isLoadingCnpj = false;
  bool _cnpjJaConsultado = false; // Evita múltiplas consultas
  
  // Estado para controle da consulta CEP
  bool _isLoadingCep = false;
  
  // Estado para tipo de documento (CPF ou CNPJ/MEI) - apenas para motorista
  String _tipoDocumento = 'CPF'; // 'CPF' ou 'CNPJ'
  
  // Campo de confirmação de senha
  final _tConfirmarSenha = TextEditingController();

//db_motoristas
  final _cpf = TextEditingController();
  final _des_placa = TextEditingController();
  final _des_modelo = TextEditingController();

  //db_enderecos
  final _desCep = TextEditingController();
  final _desRua = TextEditingController();
  final _desNumero = TextEditingController();
  final _desCidade = TextEditingController();
  final _desEstado = TextEditingController();
  final _desBairro = TextEditingController();

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
      if (widget.tipoPagina == 1) {
        if (text == null || text.isEmpty) {
          return "Informe a senha";
        }
        if (text.length < 6) {
          return "Senha deve ter no mínimo 6 caracteres";
        }
      }
    }
    return null;
  }
  
  String? _validateConfirmarSenha(String? text) {
    if (ApiBaseHelper.userSessao != null &&
        ApiBaseHelper.userSessao!.codUsuario == null) {
      if (widget.tipoPagina == 1) {
        if (text == null || text.isEmpty) {
          return "Confirme a senha";
        }
        if (text != _tMinhaSenha.text) {
          return "As senhas não coincidem";
        }
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

  String? _validateCampoGenericoCep(String? text, String msg) {
    if (text == null || text.isEmpty) {
      return msg;
    }

    return null;
  }

  _buscaCep(String? text) async {
    if (text == null) text = _desCep.text;

    if (text != null) {
      final cepLimpo = text.replaceAll(".", "").replaceAll("-", "");
      
      // Só busca se tiver 8 dígitos
      if (cepLimpo.length == 8 && !_isLoadingCep) {
        setState(() {
          _isLoadingCep = true;
        });

        try {
          var retorno = await ViaCepService.fetchCep(cep: cepLimpo);

          //db_enderecos
          if (mounted) {
            setState(() {
              if (retorno.bairro != null && retorno.bairro!.isNotEmpty) {
                _desBairro.text = retorno.bairro!;
              }

              if (retorno.logradouro != null && retorno.logradouro!.isNotEmpty) {
                _desRua.text = retorno.logradouro!;
              }

              if (retorno.localidade != null && retorno.localidade!.isNotEmpty) {
                _desCidade.text = retorno.localidade!;
              }

              if (retorno.uf != null && retorno.uf!.isNotEmpty) {
                _desEstado.text = retorno.uf!;
              }

              _isLoadingCep = false;
            });

            focusNodeNumero.requestFocus();
            showToast(context, "Endereço preenchido automaticamente");
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoadingCep = false;
            });
            showToast(context, "CEP não encontrado. Preencha manualmente.");
            Logger.logWarn(
              'Erro ao consultar CEP: $e',
              tag: 'CadastroPage._buscaCep',
            );
          }
        }
      } else if (cepLimpo.length < 8) {
        setState(() {
          _isLoadingCep = false;
        });
      }
    }
  }

  /// Consulta automática de CNPJ quando o usuário digita 14 dígitos
  /// 
  /// Esta função é chamada automaticamente quando o campo CPF/CNPJ
  /// atinge 14 dígitos (tamanho do CNPJ)
  /// 
  /// Preenche automaticamente os campos mas mantém tudo editável
  _buscaCnpj(String cnpj) async {
    // Remove formatação para contar apenas dígitos
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    
    // Só consulta se tiver exatamente 14 dígitos e ainda não foi consultado
    if (cnpjLimpo.length == 14 && !_cnpjJaConsultado && !_isLoadingCnpj) {
      setState(() {
        _isLoadingCnpj = true;
        _cnpjJaConsultado = true;
      });

      try {
        final cnpjData = await CnpjService.fetchCnpj(cnpj: cnpjLimpo);

        // Preenche os campos automaticamente (mas mantém editáveis)
        if (mounted) {
          setState(() {
            // Razão Social -> Nome
            if (cnpjData.razaoSocial != null && cnpjData.razaoSocial!.isNotEmpty) {
              _tMeuNome.text = cnpjData.razaoSocial!;
            }

            // Endereço - Logradouro
            if (cnpjData.logradouro != null && cnpjData.logradouro!.isNotEmpty) {
              String tipoLogradouro = cnpjData.descricaoTipoLogradouro ?? '';
              _desRua.text = tipoLogradouro.isNotEmpty 
                  ? '$tipoLogradouro ${cnpjData.logradouro}'
                  : cnpjData.logradouro!;
            }

            // Número
            if (cnpjData.numero != null && cnpjData.numero!.isNotEmpty) {
              _desNumero.text = cnpjData.numero!;
            }

            // Bairro
            if (cnpjData.bairro != null && cnpjData.bairro!.isNotEmpty) {
              _desBairro.text = cnpjData.bairro!;
            }

            // CEP
            if (cnpjData.cep != null && cnpjData.cep!.isNotEmpty) {
              _desCep.text = cnpjData.cep!;
            }

            // Cidade
            if (cnpjData.municipio != null && cnpjData.municipio!.isNotEmpty) {
              _desCidade.text = cnpjData.municipio!;
            }

            // Estado (UF)
            if (cnpjData.uf != null && cnpjData.uf!.isNotEmpty) {
              _desEstado.text = cnpjData.uf!;
            }

            _isLoadingCnpj = false;
          });

          // Mostra mensagem de sucesso
          showToast(context, "Dados do CNPJ preenchidos automaticamente");
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingCnpj = false;
            _cnpjJaConsultado = false; // Permite tentar novamente
          });
          
          // Mostra erro mas não impede o cadastro
          showToast(context, "Não foi possível consultar o CNPJ. Você pode preencher manualmente.");
          
          Logger.logWarn(
            'Erro ao consultar CNPJ: $e',
            tag: 'CadastroPage._buscaCnpj',
          );
        }
      }
    } else if (cnpjLimpo.length < 14) {
      // Reset do flag quando o CNPJ é alterado para menos de 14 dígitos
      setState(() {
        _cnpjJaConsultado = false;
      });
    }
  }

  String? _validateCampoGenerico(String? text, String msg) {
    if (text == null || text.isEmpty) {
      return msg;
    }

    return null;
  }

  String? _validadeCPF(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe um valido";
    }

    if (!CPFValidator.isValid(text) && !CNPJValidator.isValid(text))
      return "Informe um CPF/CNPJ válido";

    return null;
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

  /// Widget auxiliar para criar seções organizadas
  Widget _buildSection({
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Color(0xFF9E9E9E), size: 20),
                SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  _onClickCadastro(BuildContext context) {
    print('🟢 [CADASTRO] Iniciando processo de cadastro...');
    final meuLogin = _tMeuLogin.text.trim().toLowerCase();
    final minhaSenha = _tMinhaSenha.text;
    final meuNome = _tMeuNome.text.trim();
    final emailMotorista = _tEmailMotorista.text.trim().toLowerCase();
    
    print('🟢 [CADASTRO] Dados coletados:');
    print('   - Email: $meuLogin');
    print('   - Nome: $meuNome');
    print('   - CPF/CNPJ: ${_cpf.text}');
    print('   - Tipo: ${widget.tipoLogin}');

    // Validação de documentos baseada no tipo de usuário e tipo de documento
    if (ApiBaseHelper.userSessao!.indTipo ==
        ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
      // Para motorista, sempre precisa da CNH
      if (desImgCarteria == null || desImgCarteria.isEmpty) {
        print('🔴 [CADASTRO] Validação falhou: CNH não anexada');
        showToast(
            context, "Necessário anexar a Carteira de Motorista (CNH)");
        return;
      }
      
      // Se for CNPJ/MEI, também precisa do Cartão CNPJ/MEI
      if (_tipoDocumento == 'CNPJ') {
        if (desImgCartao == null || desImgCartao.isEmpty) {
          print('🔴 [CADASTRO] Validação falhou: Cartão CNPJ/MEI não anexado');
          showToast(
              context, "Necessário anexar o Cartão CNPJ/MEI");
          return;
        }
      }
      // Se for CPF, não precisa de comprovante de residência (desImgCartao não é obrigatório)
    } else {
      // Para empresa, não precisa mais anexar cartão CNPJ/MEI pois já fazemos consulta automática
      // Validação removida conforme solicitado
      print('🟢 [CADASTRO] Cadastro de empresa - validação de documentos pulada');
    }
    
    // Validação do formulário
    print('🟢 [CADASTRO] Validando formulário...');
    if (!_formKey.currentState!.validate()) {
      print('🔴 [CADASTRO] Validação do formulário falhou! Verifique os campos.');
      
      // Verifica campos específicos que podem estar vazios
      String camposFaltando = '';
      if (_desNumero.text.trim().isEmpty) {
        camposFaltando += 'Número do endereço, ';
      }
      if (_desCep.text.trim().isEmpty) {
        camposFaltando += 'CEP, ';
      }
      if (_desRua.text.trim().isEmpty) {
        camposFaltando += 'Rua, ';
      }
      if (_desBairro.text.trim().isEmpty) {
        camposFaltando += 'Bairro, ';
      }
      if (_desCidade.text.trim().isEmpty) {
        camposFaltando += 'Cidade, ';
      }
      if (_desEstado.text.trim().isEmpty) {
        camposFaltando += 'Estado, ';
      }
      
      if (camposFaltando.isNotEmpty) {
        camposFaltando = camposFaltando.substring(0, camposFaltando.length - 2);
        showToast(context, "Por favor, preencha: $camposFaltando");
      } else {
        showToast(context, "Por favor, preencha todos os campos corretamente");
      }
      return;
    }
    
    print('✅ [CADASTRO] Validação passou! Preparando dados...');
    
    try {
      _controler.setEmail(meuLogin);
      _controler.setSenha(minhaSenha);
      _controler.setNome(meuNome);
      _controler.setEmailMotoristaAmigo(emailMotorista);

      _controler.setCpf(_cpf.text);

      _controler.setDesPlaca(_des_placa.text);
      _controler.desModelo(_des_modelo.text);

      //db_enderecos
      _controler.setDesCep(_desCep.text);
      _controler.setDesRua(_desRua.text);
      _controler.setDesNumero(_desNumero.text);
      _controler.setDesCidade(_desCidade.text);
      _controler.setDesEstado(_desEstado.text);
      _controler.setDesBairro(_desBairro.text);
      _controler.indTipo = widget.tipoLogin;
      _controler.setDesCarteiraBase64(desImgCarteria ?? "");
      _controler.setDesNomeCarteira(desNomeCarteira ?? "");
      _controler.setDesCartaoBae64(desImgCartao ?? "");
      _controler.setDesNomeCartao(desNomeCartao ?? "");
      
      print('✅ [CADASTRO] Dados preparados! Chamando registraCem...');
      //Colocar aqui chamada da API
      _controler.registraCem(widget.tipoPagina ?? 1);
    } catch (e, stackTrace) {
      print('🔴 [CADASTRO] Erro ao preparar dados: $e');
      print('🔴 [CADASTRO] StackTrace: $stackTrace');
      showToast(context, "Erro ao processar cadastro. Tente novamente.");
    }
  }

  @override
  void initState() {
    super.initState();
    _controler = CadastroController(context);
    focusNodeNumero = new FocusNode();
    if (ApiBaseHelper.userSessao != null) {
      if (ApiBaseHelper.userSessao!.usuario != null)
        _tMeuLogin.text = ApiBaseHelper.userSessao!.usuario!;

      if (ApiBaseHelper.userSessao!.desNome != null)
        _tMeuNome.text = ApiBaseHelper.userSessao!.desNome!;

      var user = ApiBaseHelper.userSessao!.usuarioResp;

      //if (ApiBaseHelper.userSessao!.desNome != null)
      // _tMinhaSenha.text = user!.senha!;

      if (ApiBaseHelper.userSessao!.indTipo ==
          ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
        if (user != null) {
          var motoristaEmpresa = user!.motoristas!.first;
          _cpf.text = motoristaEmpresa.desCpfCnpj!;

          _des_placa.text = motoristaEmpresa.desPlaca!;
          //_des_modelo.text = _cpf.text = motoristaEmpresa.desModelo!;

          _desCep.text = motoristaEmpresa.enderecos!.first.desCep!;

          _desRua.text = motoristaEmpresa.enderecos!.first.desRua!;

          _desNumero.text = motoristaEmpresa.enderecos!.first.desNumero!;
          _desCidade.text = motoristaEmpresa.enderecos!.first.desCidade!;
          _desEstado.text = motoristaEmpresa.enderecos!.first.desEstado!;
          _desBairro.text = motoristaEmpresa.enderecos!.first.desBairro!;

          desImgCartao = motoristaEmpresa.desCartao ?? "";
          desNomeCartao = motoristaEmpresa.desNomeCartao ?? "";

          desImgCarteria = motoristaEmpresa.desCarteira ?? "";
          desNomeCarteira = motoristaEmpresa.desNomeCarteira ?? "";
        }
      } else {
        // motoristaEmpresa = user!.empresas!.first;
        if (user != null) {
          var motoristaEmpresa = user!.empresas!.first;
          _cpf.text = motoristaEmpresa.desCpfCnpj!;

          _desCep.text = motoristaEmpresa.enderecos!.first.desCep!;
          _desRua.text = motoristaEmpresa.enderecos!.first.desRua!;
          _desNumero.text = motoristaEmpresa.enderecos!.first.desNumero!;
          _desCidade.text = motoristaEmpresa.enderecos!.first.desCidade!;
          _desEstado.text = motoristaEmpresa.enderecos!.first.desEstado!;
          _desBairro.text = motoristaEmpresa.enderecos!.first.desBairro!;

          desImgCartao = motoristaEmpresa.desCartao ?? "";
          desNomeCartao = motoristaEmpresa.desNomeCartao ?? "";
        }
      }
    }
  }

  bool _isObscure = true;
  @override
  Widget build(BuildContext context) {
    // Cores do mockup moderno
    const Color primaryRed = Color(0xFFE53935);
    const Color backgroundColor = Color(0xFFFFFFFF);
    const Color fieldBackground = Color(0xFFF5F5F5);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);
    const Color iconColor = Color(0xFF9E9E9E);
    const Color placeholderColor = Color(0xFF9E9E9E);

    // Logo moderno
    final logo = Hero(
      tag: 'hero',
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
        child: Image.asset(
          AppImages.logo,
          height: 100,
          width: 100,
          isAntiAlias: true,
        ),
      ),
    );

    // Título e subtítulo modernos
    final textAcessar = Text(
      'Criar conta',
      style: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );

    final subtitle = Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
      child: Text(
        'Preencha seus dados para criar sua conta',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );

    final meuEmail = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _tMeuLogin,
      validator: (value) => _validateLogin(value!),
      keyboardType: TextInputType.emailAddress,
      autofocus: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'seu@email.com',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.email_outlined, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    final meuNome = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      keyboardType: TextInputType.name,
      controller: _tMeuNome,
      validator: (value) => _validateNome(value!),
      autofocus: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'Seu nome completo',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.person_outline, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    final minhaSenha = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      autofocus: false,
      obscureText: _isObscure,
      controller: _tMinhaSenha,
      validator: (value) => _validateSenha(value!),
      autocorrect: false,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'Digite sua senha',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: iconColor),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: iconColor,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
    
    final confirmarSenha = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      autofocus: false,
      obscureText: _isObscure,
      controller: _tConfirmarSenha,
      validator: (value) => _validateConfirmarSenha(value!),
      autocorrect: false,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'Confirme sua senha',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.lock_outline, color: iconColor),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: iconColor,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    final emailMotoristaAmigo = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _tEmailMotorista,
      validator: (value) => _validateEmailMotorista(value!),
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: (ApiBaseHelper.userSessao!.indTipo == 2 ||
                ApiBaseHelper.userSessao!.indTipo == null
            ? 'amigo@email.com'
            : 'guardião@email.com'),
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.email_outlined, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    // Widget para seleção de tipo de documento (apenas para motorista)
    Widget? tipoDocumentoSelector;
    if (widget.tipoLogin == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
      tipoDocumentoSelector = Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: fieldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _tipoDocumento = 'CPF';
                    _cpf.clear();
                    _cnpjJaConsultado = false;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _tipoDocumento == 'CPF' 
                        ? primaryRed 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'CPF',
                      style: GoogleFonts.poppins(
                        color: _tipoDocumento == 'CPF' 
                            ? Colors.white 
                            : textPrimary,
                        fontWeight: _tipoDocumento == 'CPF' 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _tipoDocumento = 'CNPJ';
                    _cpf.clear();
                    _cnpjJaConsultado = false;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _tipoDocumento == 'CNPJ' 
                        ? primaryRed 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'CNPJ/MEI',
                      style: GoogleFonts.poppins(
                        color: _tipoDocumento == 'CNPJ' 
                            ? Colors.white 
                            : textPrimary,
                        fontWeight: _tipoDocumento == 'CNPJ' 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final cpf = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _cpf,
      validator: (value) => _validadeCPF(value!),
      keyboardType: TextInputType.number,
      inputFormatters: [
        CpfOuCnpjFormatter(),
        FilteringTextInputFormatter.digitsOnly
      ],
      autofocus: true,
      // Consulta automática quando o CNPJ tem 14 dígitos
      onChanged: (value) {
        // Consulta se for cadastro de empresa OU se for motorista com CNPJ selecionado
        if (widget.tipoLogin == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA ||
            (widget.tipoLogin == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA && _tipoDocumento == 'CNPJ')) {
          _buscaCnpj(value);
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: widget.tipoLogin == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
            ? (_tipoDocumento == 'CPF' ? '000.000.000-00' : '00.000.000/0000-00')
            : 'CPF ou CNPJ',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(
          _tipoDocumento == 'CNPJ' ? Icons.business_outlined : Icons.badge_outlined,
          color: iconColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        // Mostra indicador de loading se estiver consultando
        suffixIcon: _isLoadingCnpj
            ? Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                  ),
                ),
              )
            : null,
      ),
    );

    final desPlacaText = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _des_placa,
      validator: (value) =>
          _validateCampoGenerico(value!, "Informe um valor de placa válido"),
      autofocus: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'ABC-1234',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.directions_car_outlined, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    final desModeloText = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _des_modelo,
      validator: (value) =>
          _validateCampoGenerico(value!, "Informe um valor de modelo válido"),
      autofocus: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'Modelo do veículo',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.directions_car_outlined, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    FocusNode focusNode = new FocusNode();
    focusNode.addListener(() async {
      if (!focusNode.hasFocus) {
        await _buscaCep(null);

        setState(() {});
      }
    });

    final desCepText = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _desCep,
      focusNode: focusNode,
      onChanged: (s) {
        // Busca CEP automaticamente quando tiver 8 dígitos
        final cepLimpo = s.replaceAll(RegExp(r'[^\d]'), '');
        if (cepLimpo.length == 8) {
          _buscaCep(s);
        }
      },
      validator: (value) =>
          _validateCampoGenericoCep(value!, "Informe um CEP válido"),
      autofocus: true,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CepInputFormatter(),
      ],
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: '00000-000',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.location_on_outlined, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: _isLoadingCep
            ? Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                  ),
                ),
              )
            : null,
      ),
    );

    final desRuaText = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _desRua,
      validator: (value) =>
          _validateCampoGenerico(value!, "Informe uma Rua válida"),
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'Nome da rua',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.streetview_outlined, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    final desNumeroText = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _desNumero,
      focusNode: focusNodeNumero,
      validator: (value) =>
          _validateCampoGenerico(value!, "Informe um número válido"),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: '123',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.numbers_outlined, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    final desBairroText = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _desBairro,
      validator: (value) =>
          _validateCampoGenerico(value!, "Informe um Bairro válido"),
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'Nome do bairro',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.location_city_outlined, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    final desCidadeText = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _desCidade,
      validator: (value) =>
          _validateCampoGenerico(value!, "Informe um nome de cidade válido"),
      autofocus: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'Nome da cidade',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.location_city_outlined, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    final desEstadoText = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _desEstado,
      maxLength: 2,
      validator: (value) =>
          _validateCampoGenerico(value!, "Informe um estado válido"),
      autofocus: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'UF',
        hintStyle: GoogleFonts.poppins(
          color: placeholderColor,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.map_outlined, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: '',
      ),
    );

    final enviarButton = SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () {
          _onClickCadastro(context);
        },
        child: Text(
          'ENVIAR',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );

    final addCarteiraMotorista = SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryRed,
          side: BorderSide(color: primaryRed, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: backgroundColor,
        ),
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            withData: true,
            allowedExtensions: ['jpg', 'pdf'],
          );

          if (result != null) {
            Uint8List? fileBytes = result.files.first.bytes;
            String fileName = result.files.first.name;

            final imageEncoded =
                base64.encode(fileBytes!); // returns base64 string
            desImgCarteria = imageEncoded;
            desNomeCarteira = fileName;
            // Upload file
            setState(() {});
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_outlined, color: primaryRed, size: 20),
            SizedBox(width: 8),
            Text(
              desNomeCarteira.isEmpty 
                ? 'Anexar CNH' 
                : 'CNH: ${desNomeCarteira}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryRed,
              ),
            ),
          ],
        ),
      ),
    );

    final seeIconCartao = IconButton(
      icon: Icon(
        Icons.visibility_outlined,
        color: iconColor,
      ),
      onPressed: () {
        setState(() async {
          if (desImgCartao == null || desImgCartao == "") {
            showToast(
                context, "Necessário adicionar uma imagem para visualização");
            return;
          }

          final abreviatura = desNomeCartao.contains(".pdf")
              ? "data:application/pdf;base64,"
              : "data:image/png;base64,";
          final urlString = abreviatura + desImgCartao;
          if (kIsWeb) {
            html.AnchorElement anchorElement =
                html.AnchorElement(href: urlString);
            anchorElement.download = urlString;
            anchorElement.click();
          } else {
            await FileProcess.downloadFile(desImgCartao, desNomeCartao);

            FileProcess.openFile(desNomeCartao);
          }
        });
      },
    );

    final seeIconCarteira = IconButton(
      icon: Icon(
        Icons.visibility_outlined,
        color: iconColor,
      ),
      onPressed: () {
        setState(() async {
          if (desImgCarteria == null || desImgCarteria == "") {
            showToast(
                context, "Necessário adicionar uma imagem para visualização");
            return;
          }

          final abreviatura = desNomeCarteira.contains(".pdf")
              ? "data:application/pdf;base64,"
              : "data:image/png;base64,";
          final urlString = abreviatura + desImgCarteria;
          if (kIsWeb) {
            html.AnchorElement anchorElement =
                html.AnchorElement(href: urlString);
            anchorElement.download = urlString;
            anchorElement.click();
          } else {
            await FileProcess.downloadFile(desImgCarteria, desNomeCarteira);

            FileProcess.openFile(desNomeCarteira);
          }
        });
      },
    );

    final addCartaoCnpjMotorista = SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryRed,
          side: BorderSide(color: primaryRed, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: backgroundColor,
        ),
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            withData: true,
            allowedExtensions: ['jpg', 'pdf'],
          );

          if (result != null) {
            Uint8List? fileBytes = result.files.first.bytes;
            String fileName = result.files.first.name;

            final imageEncoded =
                base64.encode(fileBytes!); // returns base64 string
            desImgCartao = imageEncoded;
            desNomeCartao = fileName;
            // Upload file
            setState(() {});
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_outlined, color: primaryRed, size: 20),
            SizedBox(width: 8),
            Text(
              desNomeCartao.isEmpty 
                ? 'Anexar Cartão CNPJ/MEI' 
                : 'CNPJ/MEI: ${desNomeCartao}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryRed,
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  logo,
                  textAcessar,
                  subtitle,
                  SizedBox(height: 32.0),
                  (ApiBaseHelper.userSessao!.indTipo != 1
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                      // Seção: Conta
                      _buildSection(
                        title: 'Conta',
                        icon: Icons.account_circle,
                        children: [
                          meuEmail,
                          SizedBox(height: 12.0),
                          minhaSenha,
                          SizedBox(height: 12.0),
                          if (widget.tipoPagina == 1) ...[
                            confirmarSenha,
                            SizedBox(height: 12.0),
                          ],
                        ],
                      ),
                      // Seção: Dados Pessoais
                      _buildSection(
                        title: 'Dados Pessoais',
                        icon: Icons.person,
                        children: [
                          if (tipoDocumentoSelector != null) ...[
                            tipoDocumentoSelector!,
                            SizedBox(height: 12.0),
                          ],
                          cpf,
                          SizedBox(height: 12.0),
                          meuNome,
                        ],
                      ),
                      // Seção: Endereço
                      _buildSection(
                        title: 'Endereço',
                        icon: Icons.location_on,
                        children: [
                          desCepText,
                          SizedBox(height: 12.0),
                          desRuaText,
                          SizedBox(height: 12.0),
                          Row(
                            children: [
                              Expanded(flex: 2, child: desNumeroText),
                              SizedBox(width: 12),
                              Expanded(flex: 3, child: desBairroText),
                            ],
                          ),
                          SizedBox(height: 12.0),
                          Row(
                            children: [
                              Expanded(flex: 3, child: desCidadeText),
                              SizedBox(width: 12),
                              Expanded(flex: 1, child: desEstadoText),
                            ],
                          ),
                        ],
                      ),
                            SizedBox(height: 24),
                            enviarButton,
                            SizedBox(height: 40),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                      // Seção: Conta
                      _buildSection(
                        title: 'Conta',
                        icon: Icons.account_circle,
                        children: [
                          meuEmail,
                          SizedBox(height: 12.0),
                          minhaSenha,
                          SizedBox(height: 12.0),
                          if (widget.tipoPagina == 1) ...[
                            confirmarSenha,
                            SizedBox(height: 12.0),
                          ],
                          emailMotoristaAmigo,
                        ],
                      ),
                      // Seção: Dados Pessoais
                      _buildSection(
                        title: 'Dados Pessoais',
                        icon: Icons.person,
                        children: [
                          if (tipoDocumentoSelector != null) ...[
                            tipoDocumentoSelector!,
                            SizedBox(height: 12.0),
                          ],
                          cpf,
                          SizedBox(height: 12.0),
                          meuNome,
                          SizedBox(height: 12.0),
                          desPlacaText,
                          SizedBox(height: 12.0),
                          desModeloText,
                        ],
                      ),
                      // Seção: Endereço
                      _buildSection(
                        title: 'Endereço',
                        icon: Icons.location_on,
                        children: [
                          desCepText,
                          SizedBox(height: 12.0),
                          desRuaText,
                          SizedBox(height: 12.0),
                          Row(
                            children: [
                              Expanded(flex: 2, child: desNumeroText),
                              SizedBox(width: 12),
                              Expanded(flex: 3, child: desBairroText),
                            ],
                          ),
                          SizedBox(height: 12.0),
                          Row(
                            children: [
                              Expanded(flex: 3, child: desCidadeText),
                              SizedBox(width: 12),
                              Expanded(flex: 1, child: desEstadoText),
                            ],
                          ),
                        ],
                      ),
                      // Seção: Documentos
                      _buildSection(
                        title: 'Documentos',
                        icon: Icons.description,
                        children: [
                          addCarteiraMotorista,
                          if (desNomeCarteira.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    desNomeCarteira,
                                    style: GoogleFonts.poppins(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                seeIconCarteira,
                              ],
                            ),
                            SizedBox(height: 12),
                          ],
                          if (_tipoDocumento == 'CNPJ') ...[
                            addCartaoCnpjMotorista,
                            if (desNomeCartao.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      desNomeCartao,
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFF4CAF50),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  seeIconCartao,
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                            SizedBox(height: 24),
                            enviarButton,
                            SizedBox(height: 40),
                          ],
                        )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

