import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';

/// Tela de pagamento com cartão de crédito — integração real Asaas
class CardPaymentScreen extends StatefulWidget {
  final String corridaId;
  final double amount;
  final String? description;

  const CardPaymentScreen({
    Key? key,
    required this.corridaId,
    required this.amount,
    this.description,
  }) : super(key: key);

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  static const Color _red = Color(0xFFE53935);

  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  // Dados do cartão
  final _cardNumberCtrl = TextEditingController();
  final _holderNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController(); // MM/AA
  final _cvvCtrl = TextEditingController();

  // Dados do titular (obrigatório Asaas)
  final _cpfCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _addressNumberCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _holderNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _cpfCtrl.dispose();
    _cepCtrl.dispose();
    _addressNumberCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);

    try {
      final expiry = _expiryCtrl.text.trim().split('/');
      final expiryMonth = expiry[0];
      final expiryYear = '20${expiry[1]}';

      final cardNumber = _cardNumberCtrl.text.replaceAll(' ', '');
      final cpfCnpj = _cpfCtrl.text.replaceAll(RegExp(r'[.\-/]'), '');
      final cep = _cepCtrl.text.replaceAll('-', '');
      final phone = _phoneCtrl.text.replaceAll(RegExp(r'[\s()\-]'), '');

      final jwt = ApiBaseHelper.userSessao?.jwt;
      final dio = Dio(BaseOptions(
        baseUrl: ApiBaseHelper.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: jwt != null ? 'Bearer $jwt' : '',
        },
      ));

      final body = {
        'cpfCnpj': cpfCnpj,
        'name': _holderNameCtrl.text.trim(),
        'value': widget.amount,
        'description': widget.description ?? 'Entrega Fool',
        'corridaId': widget.corridaId,
        'creditCard': {
          'holderName': _holderNameCtrl.text.trim(),
          'number': cardNumber,
          'expiryMonth': expiryMonth,
          'expiryYear': expiryYear,
          'ccv': _cvvCtrl.text.trim(),
        },
        'creditCardHolderInfo': {
          'name': _holderNameCtrl.text.trim(),
          'cpfCnpj': cpfCnpj,
          'postalCode': cep,
          'addressNumber': _addressNumberCtrl.text.trim(),
          'phone': phone,
          'mobilePhone': phone,
        },
      };

      final response = await dio.post('/private/payment/card', data: body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        if (status == 'CONFIRMED' || status == 'RECEIVED') {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pagamento aprovado!'),
            backgroundColor: Colors.green,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Status: $status — aguarde confirmação'),
            backgroundColor: Colors.orange,
          ));
          // status PENDING também libera a corrida (cartão parcelado ou antifraude)
          Navigator.of(context).pop(true);
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data as Map?)?['error'] ?? e.message ?? 'Erro no pagamento';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg.toString()),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: Text(
          'Pagar com Cartão',
          style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Valor
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    Text('Valor a pagar',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 6),
                    Text(
                      'R\$ ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _sectionTitle('Dados do cartão'),
              const SizedBox(height: 12),

              // Número do cartão
              _buildField(
                controller: _cardNumberCtrl,
                label: 'Número do cartão',
                hint: '0000 0000 0000 0000',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                validator: (v) {
                  final digits = v?.replaceAll(' ', '') ?? '';
                  if (digits.length < 13) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Nome no cartão
              _buildField(
                controller: _holderNameCtrl,
                label: 'Nome no cartão',
                hint: 'JOÃO SILVA',
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: _buildField(
                    controller: _expiryCtrl,
                    label: 'Validade',
                    hint: 'MM/AA',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryFormatter(),
                    ],
                    validator: (v) {
                      if (v == null || v.length < 5) return 'Inválida';
                      final parts = v.split('/');
                      final month = int.tryParse(parts[0]) ?? 0;
                      if (month < 1 || month > 12) return 'Mês inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _cvvCtrl,
                    label: 'CVV',
                    hint: '123',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (v) =>
                        (v?.length ?? 0) < 3 ? 'CVV inválido' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              _sectionTitle('Dados do titular (obrigatório)'),
              const SizedBox(height: 12),

              // CPF
              _buildField(
                controller: _cpfCtrl,
                label: 'CPF do titular',
                hint: '000.000.000-00',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CpfFormatter(),
                ],
                validator: (v) {
                  final digits = v?.replaceAll(RegExp(r'[.\-]'), '') ?? '';
                  if (digits.length != 11) return 'CPF inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    controller: _cepCtrl,
                    label: 'CEP',
                    hint: '00000-000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CepFormatter(),
                    ],
                    validator: (v) {
                      final digits = v?.replaceAll('-', '') ?? '';
                      if (digits.length != 8) return 'CEP inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _addressNumberCtrl,
                    label: 'Número',
                    hint: '123',
                    keyboardType: TextInputType.text,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              _buildField(
                controller: _phoneCtrl,
                label: 'Telefone / WhatsApp',
                hint: '(11) 99999-9999',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (v) {
                  final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                  if (digits.length < 10) return 'Telefone inválido';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Botão pagar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Pagar R\$ ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Pagamento seguro via Asaas',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A)),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll(' ', '');
    if (digits.length > 16) return old;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newVal.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll('/', '');
    if (digits.length > 4) return old;
    String str = digits;
    if (digits.length >= 3) {
      str = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return newVal.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) return old;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newVal.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll('-', '');
    if (digits.length > 8) return old;
    String str = digits;
    if (digits.length > 5) {
      str = '${digits.substring(0, 5)}-${digits.substring(5)}';
    }
    return newVal.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
