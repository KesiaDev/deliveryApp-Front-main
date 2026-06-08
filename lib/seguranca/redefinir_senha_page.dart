import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

/// Tela para digitar o código OTP recebido por email e definir nova senha.
/// Recebe [email] por argumento de rota ou construtor.
class RedefinirSenhaPage extends StatefulWidget {
  final String email;
  const RedefinirSenhaPage({Key? key, required this.email}) : super(key: key);

  @override
  State<RedefinirSenhaPage> createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends State<RedefinirSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _sucesso = false;
  bool _showSenha = false;
  bool _showConfirm = false;

  static const Color _red = Color(0xFFE53935);

  @override
  void dispose() {
    _otpCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _redefinir() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiBaseHelper.dio.post(
        '${ApiBaseHelper.baseUrl}/public/redefinir-senha',
        data: {
          'email': widget.email,
          'otp': _otpCtrl.text.trim(),
          'novaSenha': _senhaCtrl.text,
        },
        options: Options(
          headers: {'Authorization': null}, // endpoint público
          extra: {'skipAuth': true},
        ),
      );
      if (mounted) setState(() => _sucesso = true);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? 'Erro ao redefinir senha';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sucesso) return _buildSucesso();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Redefinir Senha',
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Digite o código enviado para:',
                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF757575)),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 32),

                // OTP field
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: _inputDecoration('Código de 6 dígitos', null),
                  validator: (v) {
                    if (v == null || v.trim().length != 6) return 'Digite os 6 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Nova senha
                TextFormField(
                  controller: _senhaCtrl,
                  obscureText: !_showSenha,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: _inputDecoration('Nova senha', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_showSenha ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF9E9E9E)),
                      onPressed: () => setState(() => _showSenha = !_showSenha),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmar senha
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showConfirm,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: _inputDecoration('Confirmar senha', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF9E9E9E)),
                      onPressed: () => setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _senhaCtrl.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _loading ? null : _redefinir,
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('REDEFINIR SENHA',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSucesso() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, size: 64, color: Colors.green),
              ),
              const SizedBox(height: 32),
              Text('Senha redefinida!',
                  style: GoogleFonts.poppins(
                      fontSize: 26, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Sua senha foi alterada com sucesso.\nFaça login com sua nova senha.',
                  style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF757575)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text('IR PARA LOGIN',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 16),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF9E9E9E)) : null,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _red, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _red)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _red, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      counterText: '',
    );
  }
}
