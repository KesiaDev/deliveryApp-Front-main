import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/editar_cadastro/editar_cadastro_controller.dart';
import 'package:delivery_front/modules/rating/widgets/rating_display_widget.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class EditarCadastroPage extends StatefulWidget {
  final Usuario usuarioEdicao;

  EditarCadastroPage({Key? key, required this.usuarioEdicao}) : super(key: key);

  @override
  _EditarCadastroPage createState() => _EditarCadastroPage();
}

class _EditarCadastroPage extends State<EditarCadastroPage> {
  late final EditarCadastroController _controler;
  var _tMeuLogin = TextEditingController();
  final _tMinhaSenha = TextEditingController();
  var _tMeuNome = TextEditingController();
  final _tEmailMotorista = TextEditingController();
  var _tCarroMotorista = TextEditingController();
  var _tPlacaMotorista = TextEditingController();
  var _tCorCarroMotorista = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Novos campos
  String desFotoPerfilBase64 = "";
  String? _tipoMotoSelecionado;
  String? _corMotoSelecionada;
  
  // Cores disponíveis para a moto
  final List<Map<String, String>> _coresMoto = [
    {'nome': 'Vermelho', 'hex': '#E53935'},
    {'nome': 'Azul', 'hex': '#2196F3'},
    {'nome': 'Verde', 'hex': '#4CAF50'},
    {'nome': 'Amarelo', 'hex': '#FFC107'},
    {'nome': 'Preto', 'hex': '#1A1A1A'},
    {'nome': 'Branco', 'hex': '#FFFFFF'},
    {'nome': 'Cinza', 'hex': '#9E9E9E'},
    {'nome': 'Laranja', 'hex': '#FF9800'},
  ];

  // Tipos de moto
  final List<String> _tiposMoto = [
    'Scooter',
    'Street',
    'Sport',
    'Big Trail',
    'Cargo',
  ];

  String? _validateLogin(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe o login";
    }
    return null;
  }

  String? _validateSenha(String? text) {
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

  String? _validatePlacaMotorista(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe uma placa válida de veículo";
    }
    return null;
  }

  String? _validateModeloMotorista(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe uma modelo válido de veículo";
    }
    return null;
  }

  String? _validateCorMotorista(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe uma cor válida de carro";
    }
    return null;
  }

  Future<void> _escolherFotoPerfil() async {
    if (kIsWeb) {
      // Para web, usar FilePicker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        Uint8List? fileBytes = result.files.first.bytes;
        if (fileBytes != null) {
          setState(() {
            desFotoPerfilBase64 = base64.encode(fileBytes);
          });
        }
      }
    } else {
      // Para mobile, mostrar opções
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Escolher da galeria'),
                  onTap: () async {
                    if (!mounted) return;
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (mounted) {
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 85,
                        );
                        if (image != null && mounted) {
                          final bytes = await image.readAsBytes();
                          setState(() {
                            desFotoPerfilBase64 = base64.encode(bytes);
                          });
                        }
                      }
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Tirar foto'),
                  onTap: () async {
                    if (!mounted) return;
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (mounted) {
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 85,
                        );
                        if (image != null && mounted) {
                          final bytes = await image.readAsBytes();
                          setState(() {
                            desFotoPerfilBase64 = base64.encode(bytes);
                          });
                        }
                      }
                    });
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  _onClickCadastro(BuildContext context) {
    final meuLogin = _tMeuLogin.text;
    final minhaSenha = _tMinhaSenha.text;
    final meuNome = _tMeuNome.text;
    final emailMotorista = _tEmailMotorista.text;
    final carroMotorista = _tCarroMotorista.text;
    final corMotorista = _tCorCarroMotorista.text;
    final placaCarro = _tPlacaMotorista.text;

    if (_formKey.currentState!.validate()) {
      _controler.setEmail(meuLogin);
      _controler.setSenha(minhaSenha);
      _controler.setNome(meuNome);
      _controler.setEmailMotoristaAmigo(emailMotorista);
      _controler.setCarro(carroMotorista);
      _controler.setCor(corMotorista);
      _controler.setPlaca(placaCarro);
      
      // Novos campos
      if (desFotoPerfilBase64.isNotEmpty) {
        _controler.setDesFotoPerfilBase64(desFotoPerfilBase64);
      }
      if (_tipoMotoSelecionado != null && _tipoMotoSelecionado!.isNotEmpty) {
        _controler.setDesTipoMoto(_tipoMotoSelecionado!);
      }
      if (_corMotoSelecionada != null && _corMotoSelecionada!.isNotEmpty) {
        _controler.setDesCorMoto(_corMotoSelecionada!);
      }

      if (widget.usuarioEdicao.indTipo == 1) {
        _controler.atualizarCadastroMotorista();
      } else if (widget.usuarioEdicao.indTipo == 2) {
        if (widget.usuarioEdicao.usuario != null)
          _controler.setEmailMotoristaAmigo(widget.usuarioEdicao.usuario!);
        _controler.atualizarCadastroCem();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controler = EditarCadastroController(context);
    _tMeuNome = TextEditingController(text: widget.usuarioEdicao.desNome);
    _tMeuLogin = TextEditingController(text: widget.usuarioEdicao.usuario);
    
    // Carregar dados existentes do motorista
    if (widget.usuarioEdicao.indTipo == 1) {
      final motorista = widget.usuarioEdicao.usuarioResp?.motoristas?.first;
      if (motorista != null) {
        if (motorista.desFotoPerfil != null && motorista.desFotoPerfil!.isNotEmpty) {
          desFotoPerfilBase64 = motorista.desFotoPerfil!;
        }
        if (motorista.desTipoMoto != null && motorista.desTipoMoto!.isNotEmpty) {
          _tipoMotoSelecionado = motorista.desTipoMoto;
        }
        if (motorista.desCorMoto != null && motorista.desCorMoto!.isNotEmpty) {
          _corMotoSelecionada = motorista.desCorMoto;
        }
        if (motorista.desPlaca != null) {
          _tPlacaMotorista.text = motorista.desPlaca!;
        }
      }
    }
    
    // Carregar dados existentes da empresa (incluindo foto se houver)
    if (widget.usuarioEdicao.indTipo == 2) {
      final empresa = widget.usuarioEdicao.usuarioResp?.empresas?.first;
      if (empresa != null) {
        if (empresa.desFotoPerfil != null && empresa.desFotoPerfil!.isNotEmpty) {
          desFotoPerfilBase64 = empresa.desFotoPerfil!;
        }
      }
    }
  }

  bool _isObscure = true;

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20, top: 24, bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: Color(0xFF9E9E9E), size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFE53935);
    const Color backgroundColor = Color(0xFFFFFFFF);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);
    const Color fieldBackground = Color(0xFFF5F5F5);
    const Color iconColor = Color(0xFF9E9E9E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Editar Perfil",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de perfil (disponível para motorista e empresa)
              _buildSection(
                "Foto de Perfil",
                Icons.person_outline,
                [
                  Center(
                    child: GestureDetector(
                      onTap: _escolherFotoPerfil,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: fieldBackground,
                            backgroundImage: desFotoPerfilBase64.isNotEmpty
                                ? MemoryImage(base64.decode(desFotoPerfilBase64))
                                : null,
                            child: desFotoPerfilBase64.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: iconColor,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryRed,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _escolherFotoPerfil,
                child: Text(
                  desFotoPerfilBase64.isEmpty ? "Escolher foto" : "Alterar foto",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: primaryRed,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Widget de nota média com link para histórico
            Center(
              child: GestureDetector(
                onTap: () {
                  final userId = widget.usuarioEdicao.codUsuario?.toString() ?? '';
                  debugPrint('🔍 Navegando para histórico de avaliações');
                  debugPrint('🔍 userId: $userId');
                  debugPrint('🔍 codUsuario: ${widget.usuarioEdicao.codUsuario}');
                  
                  if (userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro: ID do usuário não encontrado'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.pushNamed(
                    context,
                    AppRoutes.ratingHistory,
                    arguments: {
                      'userId': userId,
                    },
                  ).then((_) {
                    debugPrint('🔍 Retornou da tela de histórico');
                  }).catchError((error) {
                    debugPrint('❌ Erro ao navegar: $error');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao abrir histórico: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RatingDisplayWidget(
                      userId: widget.usuarioEdicao.codUsuario?.toString() ?? '',
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
            ),
                ],
              ),

              // Dados pessoais
              _buildSection(
                "Dados Pessoais",
                Icons.person_outline,
                [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      controller: _tMeuLogin,
                      validator: _validateLogin,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'Seu e-mail',
                        filled: true,
                        fillColor: fieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.email_outlined, color: iconColor),
                        labelStyle: GoogleFonts.poppins(color: textSecondary),
                        hintStyle: GoogleFonts.poppins(color: textSecondary),
                      ),
                      style: GoogleFonts.poppins(color: textPrimary),
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      controller: _tMinhaSenha,
                      validator: _validateSenha,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        hintText: 'Sua senha',
                        filled: true,
                        fillColor: fieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
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
                        labelStyle: GoogleFonts.poppins(color: textSecondary),
                        hintStyle: GoogleFonts.poppins(color: textSecondary),
                      ),
                      style: GoogleFonts.poppins(color: textPrimary),
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      controller: _tMeuNome,
                      validator: _validateNome,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        hintText: 'Seu nome completo',
                        filled: true,
                        fillColor: fieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.person_outline, color: iconColor),
                        labelStyle: GoogleFonts.poppins(color: textSecondary),
                        hintStyle: GoogleFonts.poppins(color: textSecondary),
                      ),
                      style: GoogleFonts.poppins(color: textPrimary),
                    ),
                  ),
                ],
              ),

              // Veículo (apenas para motorista)
              if (widget.usuarioEdicao.indTipo == 1) ...[
                _buildSection(
                  "Veículo",
                  Icons.motorcycle_outlined,
                  [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormField(
                        controller: _tPlacaMotorista,
                        validator: _validatePlacaMotorista,
                        decoration: InputDecoration(
                          labelText: 'Placa',
                          hintText: 'ABC-1234',
                          filled: true,
                          fillColor: fieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.confirmation_number_outlined, color: iconColor),
                          labelStyle: GoogleFonts.poppins(color: textSecondary),
                          hintStyle: GoogleFonts.poppins(color: textSecondary),
                        ),
                        style: GoogleFonts.poppins(color: textPrimary),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormField(
                        controller: _tCarroMotorista,
                        validator: _validateModeloMotorista,
                        decoration: InputDecoration(
                          labelText: 'Modelo',
                          hintText: 'Ex: Honda CG 160',
                          filled: true,
                          fillColor: fieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.two_wheeler_outlined, color: iconColor),
                          labelStyle: GoogleFonts.poppins(color: textSecondary),
                          hintStyle: GoogleFonts.poppins(color: textSecondary),
                        ),
                        style: GoogleFonts.poppins(color: textPrimary),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButtonFormField<String>(
                        value: _tipoMotoSelecionado,
                        decoration: InputDecoration(
                          labelText: 'Tipo da Moto',
                          hintText: 'Selecione o tipo',
                          filled: true,
                          fillColor: fieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.category_outlined, color: iconColor),
                          labelStyle: GoogleFonts.poppins(color: textSecondary),
                          hintStyle: GoogleFonts.poppins(color: textSecondary),
                        ),
                        style: GoogleFonts.poppins(color: textPrimary),
                        items: _tiposMoto.map((String tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _tipoMotoSelecionado = newValue;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cor da Moto',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _coresMoto.map((cor) {
                              final isSelected = _corMotoSelecionada == cor['hex'];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _corMotoSelecionada = cor['hex'];
                                  });
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(cor['hex']!.replaceFirst('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? primaryRed : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: primaryRed.withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: isSelected
                                      ? Icon(Icons.check, color: Colors.white, size: 24)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              // Botão salvar
              Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
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
                      'SALVAR',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
