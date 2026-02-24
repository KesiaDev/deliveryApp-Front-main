import 'dart:io';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/empresa/corridas/sol_nova_corrida_page.dart';
import 'package:delivery_front/home/widgets/task_column.dart';
import 'package:delivery_front/shared/models/DadosCorrida.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:location/location.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePageEmpresa extends StatefulWidget {
  static TextButton calendarIcon() {
    return TextButton.icon(
      label: Text("Nova corrida", style: TextStyle(color: Colors.black)),
      icon: Icon(
        Icons.add,
        color: Colors.red[800],
      ),
      onPressed: null,
    );
  }

  @override
  State<HomePageEmpresa> createState() => _HomePageEmpresaState();
}

class _HomePageEmpresaState extends State<HomePageEmpresa> {
  Usuario user = Usuario();
  UserService _userService = new UserService();
  List<DadosCorridas> dadosCorrida = [];
  bool isAdm = false;

  // Cores modernas - Padrão FOLL
  static const Color primaryRed = Color(0xFFE53935);
  static const Color backgroundColor = Color(0xFFF8F6FB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF777777);
  static const Color iconColor = Color(0xFF9E9E9E);

  Text subheading(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  Future<void> carregaPerfil() async {
    user = ApiBaseHelper.userSessao!;
    if (user.desNome == null) {
      final userFromService = await _userService.getCurrentUser();
      if (userFromService != null) {
        user = userFromService;
      } else {
        user = new Usuario();
      }
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      late final Map<ph.Permission, ph.PermissionStatus> statusess;

      if (androidInfo.version.sdkInt >= 33) {
        statusess = await [ph.Permission.notification].request();

        var allAccepted = true;
        statusess.forEach((permission, status) {
          if (status != PermissionStatus.granted) {
            allAccepted = false;
          }
        });

        if (!allAccepted) {
          _showToast(context,
              "Necessário autorizar notificações para receber novas informações");
        }
      }
    }
  }

  void _showToast(BuildContext context, String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    isAdm = false;
    // set custom marker pins
    carregaPerfil();
  }

  @override
  Widget build(BuildContext context) {
    //dadosCorrida = await _userService.buscaDadosCorrida(user.usuarioResp!.empresas?.first.codEmpresa);
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          final backResult = await _onBackPressed();
          if (backResult == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: AppColors.primaryBlack,
          hintColor: Colors.black,
          appBarTheme: AppBarTheme(
            backgroundColor: cardBackground,
            elevation: 0,
            shadowColor: Colors.transparent,
            iconTheme: IconThemeData(color: textPrimary),
            titleTextStyle: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Colors.black,
                displayColor: Colors.black,
              ),
        ),
        home: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              title: Text(
                user.desNome ?? "Empresa",
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: true,
              ),
              backgroundColor: cardBackground,
              shadowColor: Colors.transparent,
              elevation: 0,
              actions: <Widget>[
                // Botão de mensagens
                Container(
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: textPrimary,
                      size: 20,
                    ),
                    tooltip: "Mensagens",
                    onPressed: () {
                      if (!mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chatList,
                            arguments: {
                              'currentUserId': user.codUsuario?.toString() ?? '',
                              'currentUserName': user.desNome ?? 'Empresa',
                              'currentUserType': user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA ? 'empresa' : 'motorista',
                            },
                          );
                        }
                      });
                    },
                  ),
                ),
                // Botão de notificações
                Container(
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: textPrimary,
                      size: 20,
                    ),
                    tooltip: "Novas corridas",
                    onPressed: () {
                      if (!mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.corridas,
                            arguments: {
                              'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA,
                            },
                          );
                        }
                      });
                    },
                  ),
                ),
                // Botão Nova Corrida na AppBar (moderno) - ajustado para não sobrepor
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: () {
                      if (!mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          if (user.usuarioResp?.indBloqueado == 1) {
                            context.showInfoBar(
                              duration: Duration(seconds: 8),
                              content: Text(
                                  "Não será possível iniciar corrida, novas solicitações estão bloqueadas."),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SolNovaCorridaPage()),
                            );
                          }
                        }
                      });
                    },
                    icon: Icon(Icons.add, size: 18, color: Colors.red),
                    label: Text(
                      'Nova corrida',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
              leading: Builder(
                builder: (BuildContext context) {
                  return Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.menu_rounded,
                        color: textPrimary,
                        size: 20,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      tooltip: MaterialLocalizations.of(context)
                          .openAppDrawerTooltip,
                    ),
                  );
                },
              ),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                return montaTelaInicialEmpresa(constraints.maxWidth);
              },
            ),
            drawer: Drawer(
              backgroundColor: cardBackground,
              child: ListView(
                scrollDirection: Axis.vertical,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40.0,
                          backgroundColor: Colors.red,
                          child: Text(
                            (user.desNome?.toUpperCase().substring(0, 1) ?? 'E'),
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          (user.desNome ?? 'Empresa'),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          (user.usuario ?? ''),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: backgroundColor),
                  Visibility(
                      visible: user.indTipo == 1 ? true : false,
                      child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFFDEEEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person_outline_rounded, color: Colors.red, size: 20),
                          ),
                          title: Text(
                            "Dados",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            "Minhas informações",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded, color: iconColor),
                          onTap: () async {
                            if (!mounted) return;
                            Navigator.pop(context);
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              if (mounted) {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.editarCadastro,
                                );
                              }
                            });
                          })),
                  Visibility(
                    visible: user.indTipo == 1 ? true : false,
                    child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xFFFDEEEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.motorcycle, color: Colors.red, size: 20),
                        ),
                        title: Text(
                          "Corridas",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          "Corridas em andamento",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: iconColor),
                        onTap: () {
                          if (!mounted) return;
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.corridas,
                                arguments: {'indTipoDefault': 99},
                              );
                            }
                          });
                        }),
                  ),
                  Visibility(
                      visible: user.indTipo == 1 ? false : true,
                      child: ListTile(
                          leading: Icon(Icons.person_outline, color: iconColor),
                          title: Text(
                            (user.indTipo == 1
                                ? "Guardiões do BEM"
                                : "Motoristas"),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            (user.indTipo == 1
                                ? "Adicionar guardião"
                                : "Cadastrar Motoristas"),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right, color: iconColor),
                          onTap: () {
                            if (!mounted) return;
                            Navigator.pop(context);
                          })),
                  Visibility(
                    visible: user.indTipo == 1 ? false : false,
                    child: ListTile(
                        leading: Icon(Icons.star_outline, color: iconColor),
                        title: Text(
                          "Guardiões do bem",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          "Meus Guardiões",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: iconColor),
                        onTap: () {
                          // Navigator.pushReplacement(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => HomePage()),
                          // );

                          // Navigator.push(
                          //     context,
                          //     new MaterialPageRoute(
                          //         builder: (context) => ListaCemMotoristaPage()));
                        }),
                  ),
                  ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFFDEEEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.red, size: 20),
                      ),
                      title: Text(
                        "Mensagens",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        "Conversas e mensagens",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: iconColor),
                      onTap: () {
                        if (!mounted) return;
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.chatList,
                              arguments: {
                                'currentUserId': user.codUsuario?.toString() ?? '',
                                'currentUserName': user.desNome ?? 'Empresa',
                                'currentUserType': user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA ? 'empresa' : 'motorista',
                              },
                            );
                          }
                        });
                      }),
                  ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFFDEEEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.analytics_outlined, color: Colors.red, size: 20),
                      ),
                      title: Text(
                        "Relatórios",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        "Analytics e gráficos",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: iconColor),
                      onTap: () {
                        if (!mounted) return;
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            int? codEmpresa;
                            if (user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA) {
                              codEmpresa = user.usuarioResp?.empresas?.first.codEmpresa;
                            }
                            Navigator.pushNamed(
                              context,
                              AppRoutes.analytics,
                              arguments: {
                                'codEmpresa': codEmpresa,
                              },
                            );
                          }
                        });
                      }),
                  ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFFDEEEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.history_rounded, color: Colors.red, size: 20),
                      ),
                      title: Text(
                        "Histórico",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        user.indTipo ==
                                ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                            ? "Meu histórico de entregas"
                            : "Histórico de chamados",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: iconColor),
                      onTap: () {
                        if (!mounted) return;
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.corridas,
                            );
                          }
                        });
                      }),
                  Divider(height: 1, color: backgroundColor),
                  ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFFDEEEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.account_balance_wallet_rounded, color: Colors.red, size: 20),
                      ),
                      title: Text(
                        "Saldos",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        "Consultar valores",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: iconColor),
                      onTap: () {
                        if (!mounted) return;
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.saldos,
                            );
                          }
                        });
                      }),
                  Divider(height: 1, color: backgroundColor),
                  Visibility(
                    visible: user.indTipo == 1 ? false : false,
                    child: ListTile(
                        leading: Icon(Icons.contact_phone_outlined, color: iconColor),
                        title: Text(
                          "Números úteis",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          "Ligações de Emergência",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: iconColor),
                        onTap: () {
                          //Navigator.pop(context);

                          // Navigator.push(
                          //     context,
                          //     new MaterialPageRoute(
                          //         builder: (context) =>
                          //             ContatosEmergenciaPage()));
                        }),
                  ),
                  ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.exit_to_app_rounded, color: Colors.red, size: 20),
                      ),
                      title: Text(
                        "Sair",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Confirmar"),
                              content: Text("Deseja realmente sair?"),
                              actions: [
                                TextButton(
                                  child: Text("Cancelar"),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                TextButton(
                                  child: Text("Sair", style: TextStyle(color: Colors.red)),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await _userService.logoffLocalDB();
                                    if (mounted) {
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                        AppRoutes.splash,
                                        (Route<dynamic> route) => false,
                                      );
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }),
                  SizedBox(height: 24.0),
                ],
              ),
            )),
      ),
    );
  }

  // Widget para seção de boas-vindas
  Widget _buildWelcomeCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final padding = isTablet ? 24.0 : 20.0;
        final margin = isTablet ? 32.0 : 20.0;
        
        return FutureBuilder<List<DadosCorridas>>(
          future: _userService.buscaDadosCorrida(
              codEmpresa: user.usuarioResp?.empresas?.first.codEmpresa,
              codMotorista: null,
              dtaIni: DateTime.now(),
              dtaFim: DateTime.now()),
          builder: (context, snapshot) {
            int corridasEmAndamento = 0;
            
            if (snapshot.hasData && snapshot.data != null) {
              for (var element in snapshot.data!) {
                if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ==
                    element.indStatusCorrida) {
                  corridasEmAndamento = element.qtdCorridas ?? 0;
                  break;
                }
              }
            }

            return Container(
              margin: EdgeInsets.symmetric(horizontal: margin, vertical: 16.0),
              padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFFFDEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.motorcycle,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${user.desNome ?? "Empresa"} 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Hoje você tem $corridasEmAndamento ${corridasEmAndamento == 1 ? 'corrida' : 'corridas'} em andamento.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: textSecondary,
                      ),
                      textAlign: TextAlign.left,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.fade,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  // Widget para ações rápidas (removido botão Nova Corrida - agora está na AppBar)
  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final margin = isTablet ? 32.0 : 20.0;
        final spacing = isTablet ? 16.0 : 12.0;
        final crossAxisCount = isTablet ? 3 : 2;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: margin, vertical: 8.0),
            child: GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            childAspectRatio: 1.1,
            children: [
              _buildQuickActionCard(
                icon: Icons.person_outline,
                title: 'Motoristas',
                onTap: () {
                  if (!mounted) return;
                  // Navegação para motoristas (se existir)
                  // Por enquanto não faz nada, mas mantém a estrutura
                },
              ),
              _buildQuickActionCard(
                icon: Icons.history_outlined,
                title: 'Histórico',
                onTap: () {
                  if (!mounted) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.corridas,
                      );
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

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFFFDEEEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.fade,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  FutureBuilder criaInfoDia({int? codMotorista, int? codEmpresa}) {
    int? codEmAux;
    int? codMotAux;

    if (ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA == user.indTipo) {
      codMotAux = user.usuarioResp!.motoristas!.first.codMotorista;
    }

    if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == user.indTipo) {
      codEmAux = user.usuarioResp!.empresas!.first.codEmpresa;
    }

    final finalCodEmpresa = codEmpresa ?? codEmAux;
    final finalCodMotorista = codMotorista ?? codMotAux;

    return FutureBuilder<List<DadosCorridas>>(
      future: _userService.buscaDadosCorrida(
          codEmpresa: finalCodEmpresa,
          codMotorista: finalCodMotorista,
          dtaIni: DateTime.now(),
          dtaFim: DateTime.now()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // while data is loading:
          return Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
          );
        } else {
          // data loaded:
          final List<DadosCorridas>? list = snapshot.data;

          if (list != null) {
            DadosCorridas corridasEmAndamento = DadosCorridas();
            DadosCorridas corridasNovas = DadosCorridas();
            DadosCorridas corridasFinalizadas = DadosCorridas();

            for (var element in list) {
              if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                  element.indStatusCorrida) {
                corridasNovas = element;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ==
                  element.indStatusCorrida) {
                corridasEmAndamento = element;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ==
                  element.indStatusCorrida) {
                corridasFinalizadas = element;
              }
            }

            return Container(
                child: Column(
              children: <Widget>[
                SizedBox(height: 8.0),
                TaskColumn(
                  icon: Icons.motorcycle,
                  title: 'Total de corridas',
                  subtitle:
                      '${corridasNovas.qtdCorridas ?? 0} na fila para aceite. ${corridasEmAndamento.qtdCorridas ?? 0} em andamento',
                ),
                SizedBox(
                  height: 12.0,
                ),
                TaskColumn(
                  icon: Icons.motorcycle,
                  title: 'Corridas em andamento',
                  subtitle: '${corridasEmAndamento.qtdCorridas ?? 0}',
                ),
                SizedBox(height: 12.0),
                TaskColumn(
                  icon: Icons.check_circle_rounded,
                  title: 'Corridas concluídas',
                  subtitle: '${corridasFinalizadas.qtdCorridas ?? 0}',
                )
              ],
            ));
          } else {
            return Container(
                child: Column(
              children: <Widget>[
                SizedBox(height: 8.0),
                TaskColumn(
                  icon: Icons.motorcycle,
                  title: 'Total de corridas',
                  subtitle: 'Nenhuma informação encontrada',
                ),
                SizedBox(
                  height: 12.0,
                ),
              ],
            ));
          }
        }
      },
    );
  }

  FutureBuilder criaInfoMes({int? codMotorista, int? codEmpresa}) {
    int? codEmAux;
    int? codMotAux;

    if (ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA == user.indTipo) {
      codMotAux = user.usuarioResp!.motoristas!.first.codMotorista;
    }

    if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == user.indTipo) {
      codEmAux = user.usuarioResp!.empresas!.first.codEmpresa;
    }

    final finalCodEmpresa = codEmpresa ?? codEmAux;
    final finalCodMotorista = codMotorista ?? codMotAux;

    return FutureBuilder<List<DadosCorridas>>(
      future: _userService.buscaDadosCorrida(
          codEmpresa: finalCodEmpresa,
          codMotorista: finalCodMotorista,
          dtaIni: ApiBaseHelper.findFirstDateOfTheMonth(DateTime.now()),
          dtaFim: ApiBaseHelper.lastDayOfMonth(DateTime.now())),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<DadosCorridas>? list = snapshot.data;
          var totalCorridas = 0;
          
          if (list != null) {
            DadosCorridas corridasCanc = DadosCorridas();
            DadosCorridas corridasAceita = DadosCorridas();
            DadosCorridas corridasEmAndamento = DadosCorridas();
            DadosCorridas corridasNovas = DadosCorridas();
            DadosCorridas corridasFinalizadas = DadosCorridas();

            for (var element in list) {
              if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA ==
                  element.indStatusCorrida) {
                corridasNovas = element;
                totalCorridas =
                    (corridasNovas.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
                  element.indStatusCorrida) {
                corridasAceita = element;
                totalCorridas =
                    (corridasAceita.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO ==
                  element.indStatusCorrida) {
                corridasEmAndamento = element;
                totalCorridas =
                    (corridasEmAndamento.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA ==
                  element.indStatusCorrida) {
                corridasFinalizadas = element;
                totalCorridas =
                    (corridasFinalizadas.qtdCorridas ?? 0) + totalCorridas;
              }

              if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA ==
                  element.indStatusCorrida) {
                corridasCanc = element;
                totalCorridas = (corridasCanc.qtdCorridas ?? 0) + totalCorridas;
              }
            }

            double percentCorridasConcluidas = 0.0;
            double percentCorridasCanceladas = 0.0;
            if (totalCorridas > 0) {
              percentCorridasConcluidas = (corridasFinalizadas.qtdCorridas ?? 0) /
                  totalCorridas;
              percentCorridasCanceladas = (corridasCanc.qtdCorridas ?? 0) /
                  totalCorridas;
            }

            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 0.80,
              children: [
                _indicadorCircular(
                  titulo: 'Corridas solicitadas',
                  valor: totalCorridas.toString(),
                  porcentagem: 1.0,
                  cor: Colors.red,
                ),
                _indicadorCircular(
                  titulo: 'Corridas concluídas',
                  valor: '${(percentCorridasConcluidas * 100).toStringAsFixed(1)}%',
                  porcentagem: percentCorridasConcluidas,
                  cor: Colors.green,
                ),
                _indicadorCircular(
                  titulo: 'Canceladas',
                  valor: '${(percentCorridasCanceladas * 100).toStringAsFixed(1)}%',
                  porcentagem: percentCorridasCanceladas,
                  cor: Colors.grey,
                ),
              ],
            );
          } else {
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 0.80,
              children: [
                _indicadorCircular(
                  titulo: 'Corridas solicitadas',
                  valor: '0',
                  porcentagem: 0.0,
                  cor: Colors.red,
                ),
                _indicadorCircular(
                  titulo: 'Corridas concluídas',
                  valor: '0%',
                  porcentagem: 0.0,
                  cor: Colors.green,
                ),
                _indicadorCircular(
                  titulo: 'Canceladas',
                  valor: '0%',
                  porcentagem: 0.0,
                  cor: Colors.grey,
                ),
              ],
            );
          }
        } else {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
          );
        }
      },
    );
  }

  // Widget indicador circular padronizado
  Widget _indicadorCircular({
    required String titulo,
    required String valor,
    required double porcentagem,
    required Color cor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 90,
            width: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: porcentagem > 1.0 ? 1.0 : porcentagem,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(cor),
                ),
                Center(
                  child: Text(
                    valor,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              height: 1.1,
            ),
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget montaTelaInicialEmpresa(double width) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth >= 600;
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final horizontalPadding = isTablet ? (isLandscape ? 48.0 : 32.0) : 20.0;
        final verticalPadding = isTablet ? 16.0 : 10.0;
        final sectionSpacing = isTablet ? 24.0 : 8.0;
        
        return SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Seção de Boas-vindas
                      _buildWelcomeCard(),
                      
                      // Seção de Ações Rápidas
                      _buildQuickActions(),
                      
                      SizedBox(height: sectionSpacing),
                      
                      // Seção Informações gerais - Diário
                      Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bar_chart_outlined,
                                  size: isTablet ? 20 : 18,
                                  color: iconColor,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "Informações gerais - Diário",
                                    style: GoogleFonts.poppins(
                                      color: textPrimary,
                                      fontSize: isTablet ? 20.0 : 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            criaInfoDia(),
                          ],
                        ),
                      ),
                      
                      // Seção Números do mês
                      Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.bar_chart_outlined,
                                  color: iconColor,
                                  size: isTablet ? 22 : 20,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: subheading('Números do mês'),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.0),
                            criaInfoMes(),
                          ],
                        ),
                      ),
                      SizedBox(height: isTablet ? 32 : 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _onBackPressed() async {
    // var page = log(ModalRoute.of(context)!.settings.name ?? "" + "");
    var can = Navigator.canPop(context);
    if (can) {
      //  Navigator.pop(context);
      return true;
    } else {
      return await showDialog(
        context: context,
        builder: (context) => new AlertDialog(
          title: new Text('Confirmação'),
          content: new Text('Deseja fechar o app'),
          actions: <Widget>[
            new GestureDetector(
              onTap: () => Navigator.of(context).pop(true),
              child: Text(
                "NÃO",
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(height: 20),
            new GestureDetector(
              onTap: () async {
                if (can)
                  Navigator.of(context).pop();
                else
                  SystemNavigator.pop();
                // can = Navigator.canPop(context);
                // if (can) Navigator.of(context).pop(true);
                // Navigator.of(context).pop(true);

                //Navigator.popUntil(context, (route) => false);
              },
              child: Text("SIM", style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
    }
  }
}
