import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/login/login_controller.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/shared/services/local_storage_service.dart';
import 'package:delivery_front/seguranca/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  final int tipoLogin;

  const LoginPage({super.key, required this.tipoLogin});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginControler _controler;
  final _tLogin = TextEditingController();
  final _tSenha = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _biometricAvailable = false;
  String _biometricType = 'Biometria';

  String? _validateLogin(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe o login";
    }

    if (!text.contains("@")) return "Informe um e-mail válido para login";

    return null;
  }

  String? _validateSenha(String? text) {
    if (text == null || text.isEmpty) {
      return "Informe a senha";
    }
    return null;
  }

  void _onClickLogin(BuildContext context) {
    // Remove apenas espaços, mantém o email como digitado (case-sensitive pode ser necessário)
    final login = _tLogin.text.trim();
    final senha = _tSenha.text;

    print('🟢 [LOGIN_PAGE] Tentando fazer login...');
    print('🟢 [LOGIN_PAGE] Email (trimmed): $login');
    print('🟢 [LOGIN_PAGE] Senha length: ${senha.length}');

    if (_formKey.currentState!.validate()) {
      _controler.setEmail(login);
      _controler.setSenha(senha);
      _controler.authenticate();
    } else {
      print('🔴 [LOGIN_PAGE] Validação do formulário falhou!');
    }
  }

  @override
  void initState() {
    super.initState();
    _controler = LoginControler(context);
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final canUse = await BiometricService.canUseBiometric();
    final type = await BiometricService.getBiometricTypeName();
    if (mounted) {
      setState(() {
        _biometricAvailable = canUse;
        _biometricType = type;
      });
    }
  }

  Future<void> _loginWithBiometric() async {
    final authenticated = await BiometricService.authenticate(
      reason: 'Autentique-se para fazer login',
    );

    if (authenticated) {
      // Busca credenciais salvas
      final savedEmail = await LocalStorageService.getString('saved_email');
      final savedPassword = await LocalStorageService.getString('saved_password');

      if (savedEmail != null && savedPassword != null) {
        _tLogin.text = savedEmail;
        _tSenha.text = savedPassword;
        _onClickLogin(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nenhuma credencial salva encontrada. Faça login manualmente primeiro.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  bool _isObscure = true;
  @override
  Widget build(BuildContext context) {
    // Cores do mockup
    const Color primaryRed = Color(0xFFE53935);
    const Color backgroundColor = Color(0xFFFFFFFF);
    const Color fieldBackground = Color(0xFFF5F5F5);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);
    const Color iconColor = Color(0xFF9E9E9E);
    const Color placeholderColor = Color(0xFF9E9E9E);

    // Logo flat no topo
    final logo = Hero(
      tag: '4',
      child: Padding(
        padding: const EdgeInsets.only(top: 60.0, bottom: 40.0),
        child: Image.asset(
          AppImages.logo,
          height: 120,
          width: 120,
          isAntiAlias: true,
        ),
      ),
    );

    // Título e subtítulo
    final title = Text(
      'Bem-vinda(o) de volta',
      style: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );

    final subtitle = Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
      child: Text(
        'Entre com sua conta para continuar',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );

    // Campo de email moderno
    final email = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      controller: _tLogin,
      validator: (value) => _validateLogin(value),
      keyboardType: TextInputType.emailAddress,
      autofocus: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'E-mail',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    // Campo de senha moderno
    final password = TextFormField(
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 16,
      ),
      autofocus: false,
      controller: _tSenha,
      validator: (value) => _validateSenha(value),
      obscureText: _isObscure,
      autocorrect: false,
      decoration: InputDecoration(
        filled: true,
        fillColor: fieldBackground,
        hintText: 'Senha',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

    // Botão ENTRAR moderno
    final loginButton = SizedBox(
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
        onPressed: () => _onClickLogin(context),
        child: Text(
          'ENTRAR',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );

    // Botão CADASTRO MOTORISTA (outlined)
    final cadastroMotorista = SizedBox(
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
          try {
            final can = await Navigator.pushNamed<bool>(
              context,
              AppRoutes.termos,
            );

            if (can == true) {
              // Garantir que userSessao não seja null
              if (ApiBaseHelper.userSessao == null) {
                ApiBaseHelper.userSessao = Usuario();
              }
              ApiBaseHelper.userSessao!.indTipo =
                  ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA;
              
              if (!context.mounted) return;
              
              Navigator.pushNamed(
                context,
                AppRoutes.cadastro,
                arguments: {
                  'tipoLogin': ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA,
                },
              );
            } else if (can == false) {
              if (!context.mounted) return;
              final scaffold = ScaffoldMessenger.of(context);
              scaffold.showSnackBar(
                const SnackBar(
                  content: Text(
                    "Necessário aceitar os termos para continuar com o cadastro",
                  ),
                ),
              );
            }
          } catch (e) {
            if (!context.mounted) return;
            final scaffold = ScaffoldMessenger.of(context);
            scaffold.showSnackBar(
              SnackBar(
                content: Text("Erro ao navegar: $e"),
              ),
            );
          }
        },
        child: Text(
          'CADASTRO MOTORISTA',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryRed,
          ),
        ),
      ),
    );

    // Botão CADASTRO CLIENTE (outlined)
    final cadastro = SizedBox(
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
          try {
            final can = await Navigator.pushNamed<bool>(
              context,
              AppRoutes.termos,
            );

            if (can == true) {
              // Garantir que userSessao não seja null
              if (ApiBaseHelper.userSessao == null) {
                ApiBaseHelper.userSessao = Usuario();
              }
              ApiBaseHelper.userSessao!.indTipo =
                  ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA;
              
              if (!context.mounted) return;
              
              Navigator.pushNamed(
                context,
                AppRoutes.cadastro,
                arguments: {
                  'tipoLogin': ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA,
                },
              );
            } else if (can == false) {
              if (!context.mounted) return;
              final scaffold = ScaffoldMessenger.of(context);
              scaffold.showSnackBar(
                const SnackBar(
                  content: Text(
                    "Necessário aceitar os termos para continuar com o cadastro",
                  ),
                ),
              );
            }
          } catch (e) {
            if (!context.mounted) return;
            final scaffold = ScaffoldMessenger.of(context);
            scaffold.showSnackBar(
              SnackBar(
                content: Text("Erro ao navegar: $e"),
              ),
            );
          }
        },
        child: Text(
          'CADASTRO CLIENTE',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryRed,
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  logo,
                  title,
                  subtitle,
                  email,
                  const SizedBox(height: 16.0),
                  password,
                  const SizedBox(height: 8.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.recuperacaoSenha,
                        );
                      },
                      child: Text(
                        'Esqueci minha senha',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: primaryRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  loginButton,
                  if (_biometricAvailable) ...[
                    const SizedBox(height: 24.0),
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'ou',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryRed,
                          side: BorderSide(color: primaryRed, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: backgroundColor,
                        ),
                        icon: Icon(Icons.fingerprint),
                        label: Text(
                          'Entrar com $_biometricType',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryRed,
                          ),
                        ),
                        onPressed: _loginWithBiometric,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16.0),
                  cadastroMotorista,
                  const SizedBox(height: 12.0),
                  cadastro,
                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
