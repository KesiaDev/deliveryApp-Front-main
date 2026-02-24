import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:delivery_front/seguranca/biometric_service.dart';
import 'package:delivery_front/core/core.dart';

class BiometricSettingsPage extends StatefulWidget {
  const BiometricSettingsPage({Key? key}) : super(key: key);

  @override
  State<BiometricSettingsPage> createState() => _BiometricSettingsPageState();
}

class _BiometricSettingsPageState extends State<BiometricSettingsPage> {
  bool _isLoading = true;
  bool _isSupported = false;
  bool _hasEnrolled = false;
  bool _isEnabled = false;
  String _biometricType = 'Biometria';
  List<BiometricType> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isSupported = await BiometricService.isDeviceSupported();
      final hasEnrolled = await BiometricService.hasEnrolledBiometrics();
      final isEnabled = await BiometricService.isBiometricEnabled();
      final type = await BiometricService.getBiometricTypeName();
      final available = await BiometricService.getAvailableBiometrics();

      if (mounted) {
        setState(() {
          _isSupported = isSupported;
          _hasEnrolled = hasEnrolled;
          _isEnabled = isEnabled;
          _biometricType = type;
          _availableTypes = available;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Tenta autenticar para habilitar
      final authenticated = await BiometricService.authenticate(
        reason: 'Autentique-se para habilitar o login biométrico',
      );

      if (authenticated) {
        await BiometricService.setBiometricEnabled(true);
        if (mounted) {
          setState(() {
            _isEnabled = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login biométrico habilitado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Autenticação cancelada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      await BiometricService.setBiometricEnabled(false);
      if (mounted) {
        setState(() {
          _isEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login biométrico desabilitado'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFE53935);
    const Color backgroundColor = Color(0xFFFFFFFF);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);

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
          'Login Biométrico',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  Icon(
                    Icons.fingerprint,
                    size: 80,
                    color: _isSupported ? primaryRed : Colors.grey,
                  ),
                  SizedBox(height: 24),
                  Text(
                    _isSupported ? 'Login Biométrico Disponível' : 'Login Biométrico Não Disponível',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  if (!_isSupported)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text(
                        'Seu dispositivo não suporta autenticação biométrica.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.orange.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (!_hasEnrolled)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text(
                        'Nenhuma biometria cadastrada no dispositivo. Configure no sistema operacional.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.orange.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: 32),
                  if (_isSupported && _hasEnrolled) ...[
                    Text(
                      'Tipo de Biometria',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _biometricType,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Habilitar Login Biométrico',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Use $_biometricType para fazer login rapidamente',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isEnabled,
                          onChanged: _toggleBiometric,
                          activeColor: primaryRed,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Como funciona',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ao habilitar, você poderá fazer login usando $_biometricType após o primeiro login manual. Suas credenciais serão armazenadas de forma segura no dispositivo.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
