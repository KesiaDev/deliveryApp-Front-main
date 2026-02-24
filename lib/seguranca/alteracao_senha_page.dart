import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';

class AlteracaoSenhaPage extends StatefulWidget {
  const AlteracaoSenhaPage({Key? key}) : super(key: key);

  @override
  State<AlteracaoSenhaPage> createState() => _AlteracaoSenhaPageState();
}

class _AlteracaoSenhaPageState extends State<AlteracaoSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmacaoSenhaController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  bool _senhaAtualObscure = true;
  bool _novaSenhaObscure = true;
  bool _confirmacaoSenhaObscure = true;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmacaoSenhaController.dispose();
    super.dispose();
  }

  String? _validateSenhaAtual(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe sua senha atual';
    }
    return null;
  }

  String? _validateNovaSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a nova senha';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmacaoSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a nova senha';
    }
    if (value != _novaSenhaController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  Future<void> _alterarSenha() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.alterarSenha(
        senhaAtual: _senhaAtualController.text,
        novaSenha: _novaSenhaController.text,
        confirmacaoSenha: _confirmacaoSenhaController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Senha alterada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          'Alterar Senha',
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
                  'Altere sua senha',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Para sua segurança, informe sua senha atual e escolha uma nova senha.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 32),
                TextFormField(
                  controller: _senhaAtualController,
                  obscureText: _senhaAtualObscure,
                  validator: _validateSenhaAtual,
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fieldBackground,
                    hintText: 'Senha atual',
                    hintStyle: GoogleFonts.poppins(
                      color: iconColor,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaAtualObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: iconColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _senhaAtualObscure = !_senhaAtualObscure;
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
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _novaSenhaController,
                  obscureText: _novaSenhaObscure,
                  validator: _validateNovaSenha,
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fieldBackground,
                    hintText: 'Nova senha',
                    hintStyle: GoogleFonts.poppins(
                      color: iconColor,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _novaSenhaObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: iconColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _novaSenhaObscure = !_novaSenhaObscure;
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
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmacaoSenhaController,
                  obscureText: _confirmacaoSenhaObscure,
                  validator: _validateConfirmacaoSenha,
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fieldBackground,
                    hintText: 'Confirmar nova senha',
                    hintStyle: GoogleFonts.poppins(
                      color: iconColor,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmacaoSenhaObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: iconColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmacaoSenhaObscure = !_confirmacaoSenhaObscure;
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
                    onPressed: _isLoading ? null : _alterarSenha,
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
                            'ALTERAR SENHA',
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
