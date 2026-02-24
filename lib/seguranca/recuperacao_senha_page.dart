import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/app_gradients.dart';

class RecuperacaoSenhaPage extends StatefulWidget {
  const RecuperacaoSenhaPage({Key? key}) : super(key: key);

  @override
  State<RecuperacaoSenhaPage> createState() => _RecuperacaoSenhaPageState();
}

class _RecuperacaoSenhaPageState extends State<RecuperacaoSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  bool _emailEnviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe seu e-mail';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Informe um e-mail válido';
    }
    return null;
  }

  Future<void> _solicitarRecuperacao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.solicitarRecuperacaoSenha(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _emailEnviado = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFE53935);
    const Color backgroundColor = Color(0xFFFFFFFF);
    const Color fieldBackground = Color(0xFFF5F5F5);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);
    const Color iconColor = Color(0xFF9E9E9E);

    if (_emailEnviado) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'E-mail enviado!',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Enviamos um link de recuperação para:\n${_emailController.text}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                SizedBox(
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'VOLTAR AO LOGIN',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Recuperar Senha',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Text(
                  'Esqueceu sua senha?',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fieldBackground,
                    hintText: 'E-mail',
                    hintStyle: GoogleFonts.poppins(
                      color: iconColor,
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
                ),
                SizedBox(height: 32),
                SizedBox(
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
                    onPressed: _isLoading ? null : _solicitarRecuperacao,
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'ENVIAR LINK DE RECUPERAÇÃO',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
