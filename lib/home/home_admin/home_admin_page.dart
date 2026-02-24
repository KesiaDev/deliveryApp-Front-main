import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/bussiness/service/admin_service.dart';
import 'package:delivery_front/core/app_images.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/info_corridas_page/info_corrida_page.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/shared/models/DadosCorrida.dart';
import 'package:delivery_front/admin/admin_components.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:google_fonts/google_fonts.dart';


class HomeAdminPage extends StatefulWidget {
  HomeAdminPage({Key? key, bool? buscaChamados}) : super(key: key);

  bool buscaChamados = false;

  @override
  _HomePageAdminState createState() => _HomePageAdminState();
}

int currentTimeInSeconds() {
  var ms = (new DateTime.now()).millisecondsSinceEpoch;
  return (ms / 1000).round();
}

class _HomePageAdminState extends State<HomeAdminPage>
    with WidgetsBindingObserver {
  StreamSubscription? _locationSubscription;
  Location _locationTracker = Location();

  bool has = false;
  Usuario user = Usuario();
  int? timeStampInicial = 0;

  UserService _userService = new UserService();
  AdminService _adminService = AdminService();
  bool _isMovingManually = false;

  Marker? marker;
  Circle? circle;
  GoogleMapController? _controller;
  Set<Marker> _markers = Set<Marker>();

  BitmapDescriptor? otherCars;

  Text subheading(String title) {
    return Text(
      title,
      style: TextStyle(
          color: AppColors.grey,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2),
    );
  }

  @override
  void initState() {
    super.initState();
    carregaPerfil();
    // set custom marker pins
  }

  Future<void> carregaPerfil() async {
    user = ApiBaseHelper.userSessao!;
    if (user == null) user = (await _userService.getCurrentUser())!;
    if (user == null) user = new Usuario();
  }

  Future<bool> _onBackPressed() async {
    final route = ModalRoute.of(context);
    final pageName = route?.settings.name ?? "";
    var page = log(pageName);
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

  Widget _createFooterItem(
      {required IconData icon,
      required String text,
      required GestureTapCallback onTap}) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(icon),
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(text),
          )
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      key: Key("home"),
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          final backResult = await _onBackPressed();
          if (backResult == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: AppColors.primaryBlack,
          hintColor: Colors.black,
          appBarTheme: AppBarTheme(color: Colors.black),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Colors.black,
                displayColor: Colors.black,
              ),
        ),
        home: Scaffold(
          backgroundColor: Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            title: Text(
              user.desNome ?? "",
              style: GoogleFonts.poppins(
                color: Color(0xFF1A1A1A),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: <Widget>[
              Visibility(
                visible: user.indTipo ==
                        ApiBaseHelper.IND_TIP_PERFIL_99_ADMIN_SISTEMA
                    ? false
                    : false,
                child: TextButton.icon(
                  label: Text(
                    "Motoristas",
                    style: GoogleFonts.poppins(
                      color: Color(0xFFE53935),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  icon: Icon(
                    Icons.newspaper,
                    color: Color(0xFFE53935),
                    size: 18,
                  ),
                  onPressed: () async {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.corridas,
                      arguments: {
                        'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA,
                      },
                    );
                  },
                ),
              ),
            ],
            leading: Builder(
              builder: (BuildContext context) {
                return Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: Color(0xFF1A1A1A),
                      size: 20,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip:
                        MaterialLocalizations.of(context).openAppDrawerTooltip,
                  ),
                );
              },
            ),
          ),
          body: _buildModernDashboard(), // Dashboard moderno
          drawer: AdminDrawer(
            user: user,
            onNavigate: (route, arguments) {
              Navigator.pushNamed(context, route, arguments: arguments);
            },
            onLogout: () => showAlertDialog(context),
          ),
        ),
      ),
    );
  }

  showAlertDialog(BuildContext context) {
    // Cores do padrão FOLL
    const Color primaryRed = Color(0xFFE53935);
    const Color backgroundColor = Color(0xFFFFFFFF);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);
    const Color borderColor = Color(0xFFE6E7EB);
    
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: backgroundColor,
          title: Text(
            "Confirmar saída",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          content: Text(
            "Deseja realmente sair da sua conta?",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Text(
                "Cancelar",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                if (!context.mounted) return;
                // Fecha o dialog
                Navigator.of(context).pop();
                // Aguarda um frame para garantir que o Navigator não está locked
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!context.mounted) return;
                  await _userService.logoffLocalDB();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.splash,
                    (Route<dynamic> route) => false,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Confirmar",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
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

  // ============================================
  // DASHBOARD MODERNO
  // ============================================
  Widget _buildModernDashboard() {
    return Container(
      color: AdminColors.background,
      child: FutureBuilder<List<DadosCorridas>>(
        future: _userService.buscaDadosCorrida(
          codEmpresa: null,
          codMotorista: null,
          dtaIni: DateTime.now(),
          dtaFim: DateTime.now(),
          isAdm: true,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryRed),
              ),
            );
          }

          final list = snapshot.data ?? [];
          DadosCorridas corridasNovas = DadosCorridas();
          DadosCorridas corridasEmAndamento = DadosCorridas();
          DadosCorridas corridasFinalizadas = DadosCorridas();
          DadosCorridas corridasCanceladas = DadosCorridas();
          int totalMotoristasOnline = 0;
          int totalEmpresasAtivas = 0;
          double totalRecebido = 0.0;

          for (var element in list) {
            if (element.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA) {
              corridasNovas = element;
            }
            if (element.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO) {
              corridasEmAndamento = element;
            }
            if (element.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA) {
              corridasFinalizadas = element;
            }
            if (element.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA) {
              corridasCanceladas = element;
            }
            if (element.totalMotoristasOnline != null) {
              totalMotoristasOnline += (element.totalMotoristasOnline ?? 0);
            }
          }

          // Busca empresas ativas
          _adminService.findEmpresas().then((empresas) {
            totalEmpresasAtivas = empresas.where((e) => e.user?.indBloqueado != 1).length;
          });

          int corridasHoje = (corridasNovas.qtdCorridas ?? 0) + 
                            (corridasEmAndamento.qtdCorridas ?? 0) + 
                            (corridasFinalizadas.qtdCorridas ?? 0);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            color: AdminColors.primaryRed,
            child: SingleChildScrollView(
              primary: false,
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    'Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Visão geral do sistema',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 24),

                  // KPIs no topo
                  Row(
                    children: [
                      Expanded(
                        child: AdminKpiCard(
                          title: 'Corridas hoje',
                          value: '$corridasHoje',
                          icon: Icons.motorcycle_rounded,
                          iconColor: AdminColors.primaryRed,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: AdminKpiCard(
                          title: 'Motoristas online',
                          value: '$totalMotoristasOnline',
                          icon: Icons.person_rounded,
                          iconColor: AdminColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AdminKpiCard(
                          title: 'Empresas ativas',
                          value: '$totalEmpresasAtivas',
                          icon: Icons.business_rounded,
                          iconColor: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: AdminKpiCard(
                          title: 'Total recebido',
                          value: 'R\$ ${totalRecebido.toStringAsFixed(2)}',
                          icon: Icons.attach_money_rounded,
                          iconColor: AdminColors.warningOrange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),

                  // Resumo do mês
                  Text(
                    'Resumo do mês',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildResumoCard(
                          icon: Icons.check_circle_rounded,
                          iconColor: AdminColors.successGreen,
                          title: 'Concluídas',
                          value: '${corridasFinalizadas.qtdCorridas ?? 0}',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildResumoCard(
                          icon: Icons.directions_car_rounded,
                          iconColor: Colors.blue,
                          title: 'Em\nandamento',
                          value: '${corridasEmAndamento.qtdCorridas ?? 0}',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildResumoCard(
                          icon: Icons.cancel_rounded,
                          iconColor: Colors.red,
                          title: 'Canceladas',
                          value: '${corridasCanceladas.qtdCorridas ?? 0}',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),

                  // Atalhos rápidos
                  Text(
                    'Atalhos rápidos',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    primary: false,
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
                      AdminQuickActionCard(
                        title: 'Motoristas',
                        subtitle: 'Gerenciar motoristas',
                        icon: Icons.person_rounded,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.adminMotoristas,
                            arguments: {'userInfo': user},
                          );
                        },
                      ),
                      AdminQuickActionCard(
                        title: 'Empresas',
                        subtitle: 'Gerenciar empresas',
                        icon: Icons.business_rounded,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.adminEmpresas,
                            arguments: {'userInfo': user},
                          );
                        },
                      ),
                      AdminQuickActionCard(
                        title: 'Taxas',
                        subtitle: 'Configurar taxas',
                        icon: Icons.percent_rounded,
                        iconColor: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.adminTaxas,
                            arguments: {'userInfo': Usuario()},
                          );
                        },
                      ),
                      AdminQuickActionCard(
                        title: 'Configurações',
                        subtitle: 'Parâmetros do sistema',
                        icon: Icons.settings_rounded,
                        iconColor: AdminColors.secondaryGray,
                        onTap: () async {
                          try {
                            final config = await _userService.buscarConfigSys();
                            Navigator.pushNamed(
                              context,
                              AppRoutes.configSistema,
                              arguments: {'usuarioEdicao': config},
                            );
                          } catch (e) {
                            final config = ConfigSys(
                              vlrKmRodado: 0.0,
                              vlrPercentualDescontoMotorista: 0.0,
                              vlrTaxaApp: 0.0,
                              raioBuscaCorridas: 25,
                            );
                            Navigator.pushNamed(
                              context,
                              AppRoutes.configSistema,
                              arguments: {'usuarioEdicao': config},
                            );
                          }
                        },
                      ),
                      AdminQuickActionCard(
                        title: 'Saldos',
                        subtitle: 'Consultar valores',
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: AdminColors.warningOrange,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.saldos,
                            arguments: {'userInfo': user},
                          );
                        },
                      ),
                      AdminQuickActionCard(
                        title: 'Mensagens',
                        subtitle: 'Conversas e chat',
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: Color(0xFFE53935),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chatList,
                            arguments: {
                              'currentUserId': user.codUsuario?.toString() ?? '',
                              'currentUserName': user.desNome ?? 'Admin',
                              'currentUserType': 'admin',
                            },
                          );
                        },
                      ),
                      AdminQuickActionCard(
                        title: 'Histórico',
                        subtitle: 'Corridas concluídas',
                        icon: Icons.history_rounded,
                        iconColor: AdminColors.secondaryGray,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.corridas,
                            arguments: {
                              'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA,
                              'isAdm': true,
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================
  // CARD DE RESUMO DO MÊS (Padrão Profissional)
  // ============================================
  Widget _buildResumoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: 110),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.fade,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: AdminColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AdminColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class botaoPanico extends StatelessWidget {
  const botaoPanico({
    Key? key,
    required this.user,
    required Location locationTracker,
    required UserService userService,
  })  : _locationTracker = locationTracker,
        _userService = userService,
        super(key: key);

  final Usuario user;
  final Location _locationTracker;
  final UserService _userService;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: user.indTipo == 1 ? true : false,
      child: Container(
        height: MediaQuery.of(context).size.width * 0.3,
        width: MediaQuery.of(context).size.width * 0.3,
        child: FittedBox(
          fit: BoxFit.contain,
          child: FloatingActionButton(
            shape: CircleBorder(
              side: BorderSide(
                color: Colors.black,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(AppImages.logo),
            ),
            backgroundColor: Colors.black87,
            onPressed: () async {
              //getCurrentLocation();
              // var location = await _locationTracker.getLocation();
              // await _userService.novoPedidoDeSocorro(
              //     location.latitude!, location.longitude!);
              Navigator.pushNamed(
                context,
                AppRoutes.corridas,
                arguments: {
                  'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO,
                  'isAdm': true,
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class botaoPanicoSocorro extends StatelessWidget {
  const botaoPanicoSocorro({
    Key? key,
    required this.user,
    required Location locationTracker,
    required UserService userService,
  })  : _locationTracker = locationTracker,
        _userService = userService,
        super(key: key);

  final Usuario user;
  final Location _locationTracker;
  final UserService _userService;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: user.indTipo == 1 ? true : true,
      child: Container(
        height: 450,
        width: 450,
        child: FittedBox(
          fit: BoxFit.contain,
          child: FloatingActionButton(
            shape: CircleBorder(
              side: BorderSide(
                color: Colors.orange,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(AppImages.logoAppTransparente),
            ),
            backgroundColor: Colors.orange,
            onPressed: () async {
              //getCurrentLocation();
              var location = await _locationTracker.getLocation();
              await _userService.novoPedidoDeSocorro(
                  location.latitude!, location.longitude!);
            },
          ),
        ),
      ),
    );
  }
}

Future<void> callSocorro(int codMotorista) async {
  // print(
  //     "Chamei o socorro lat=${ApiBaseHelper.userSessao!.codMotorista} e long=${ApiBaseHelper.long}");
  // UserService _userService = UserService();
  // Usuario user = Usuario();
  // user.codMotorista = codMotorista;
  // await _userService.novoPedidoDeSocorroFlutuante(user);

  // await _userService.novoPedidoDeSocorroBlut();
}

///
/// As this callback function is called from background, it should be declared on the parent level
/// Whenever a button is clicked, this method will be invoked with a tag (As tag is unique for every button, it helps in identifying the button).
/// You can check for the tag value and perform the relevant action for the button click
///
void callBackFunction(String tag) {
  if (tag.contains("simple_button")) {
    var codMotorista = tag.split("#").elementAt(1);
    print("Simple button has been clicked");
    callSocorro(int.parse(codMotorista));
  }
  switch (tag) {
    case "simple_button":
      int codMotorista = tag.split("#").elementAt(1) as int;
      print("Simple button has been clicked");
      callSocorro(codMotorista);
      break;
    case "focus_button":
      print("Focus button has been clicked");
      //SystemAlertWindow.closeSystemWindow();
      if (Platform.isAndroid) {
        AndroidIntent intent = AndroidIntent(
          action: "action_main",
        );
//await intent.launch();
        intent.launch();
      }
      // inten.Intent()
      //   ..setAction(ac.Action.ACTION_MAIN)
      //   ..startActivity().catchError((e) => print(e));
      break;
    case "personal_btn":
      print("Personal button has been clicked");
      break;
    default:
      print("OnClick event of $tag");
  }
}

class Utils {
  static String mapStyles = '''[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]''';
}
