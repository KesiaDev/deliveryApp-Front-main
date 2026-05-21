import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:android_intent_plus/android_intent.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/app_images.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/empresa/corridas/lista_solicitacoes_empresa_controller.dart';
import 'package:delivery_front/home/widgets/maps/mapsSheet.dart';
import 'package:delivery_front/info_corridas_page/info_corrida_page.dart';
import 'package:delivery_front/shared/models/motorista/models/lista_solicitacoes.dart';
import 'package:delivery_front/shared/models/motorista/models/motoristas_proximos.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:flash/flash.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:map_launcher/map_launcher.dart' as mapN;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';

bool carregouChamado = false;

class HomePage extends StatefulWidget {
  HomePage({Key? key, bool? buscaChamados}) : super(key: key);

  bool buscaChamados = false;

  @override
  _HomePageState createState() => _HomePageState();
}

int currentTimeInSeconds() {
  var ms = (new DateTime.now()).millisecondsSinceEpoch;
  return (ms / 1000).round();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  StreamSubscription? _locationSubscription;
  Timer? _gpsVerificationTimer;
  Timer? _chamadosPollingTimer;
  bool _isDisposed = false;
  Location _locationTracker = Location();

  bool has = false;
  Usuario user = Usuario();
  int? timeStampInicial = 0;

  UserService _userService = new UserService();
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


  Future<void> _verificaGPSAtivo() async {
    if (Platform.isMacOS || _isDisposed) return;

    _gpsVerificationTimer?.cancel();
    _gpsVerificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      if (Platform.isIOS) {
        // iOS handling pode ser adicionado aqui se necessário
        return;
      }

      try {
        final serviceEnabled = await _locationTracker.serviceEnabled();
        if (!serviceEnabled) {
          final hasPermission = await _locationTracker.hasPermission() == PermissionStatus.granted;
          if (hasPermission) {
            try {
              if (await _locationTracker.requestService()) {
                if (mounted) {
                  getCurrentLocation();
                }
              }
            } on PlatformException catch (e) {
              if (e.code == 'SERVICE_STATUS_DISABLED') {
                debugPrint("Permission Denied");
              }
            }
          } else {
            await _locationTracker.requestPermission();
          }
        } else {
          final hasPermission = await _locationTracker.hasPermission() == PermissionStatus.granted;
          if (hasPermission) {
            final position = await Geolocator.getCurrentPosition();

            if (user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA) {
              final endereco = user.usuarioResp?.empresas?.first.enderecos?.first;
              if (endereco != null) {
                final enderecoStr = '${endereco.desRua},${endereco.desNumero}, ${endereco.desCidade}';
                final results = await geo.locationFromAddress(enderecoStr);

                if (results.isNotEmpty && mounted) {
                  if (user.indTipo == 1 || user.indTipo == 2) {
                    await _userService.atualizarLocalMotorista(
                      results.first.latitude,
                      results.first.longitude,
                    );
                    if (mounted) {
                      ApiBaseHelper.lat = results.first.latitude;
                      ApiBaseHelper.long = results.first.longitude;
                      debugPrint('atualizei lat=${ApiBaseHelper.lat} e long=${ApiBaseHelper.long}');
                    }
                  }
                }
              }
            } else {
              ApiBaseHelper.lat = position.latitude;
              ApiBaseHelper.long = position.longitude;
            }
          } else {
            await _locationTracker.requestPermission();
          }
        }

        if (mounted && !carregouChamado) {
          ApiBaseHelper.setBuscaNovosChamados(true);
          carregouChamado = true;
        }
      } catch (e) {
        debugPrint('Erro ao verificar GPS: $e');
      }
    });
  }

  void _buscaChamadosLeitura() {
    _chamadosPollingTimer?.cancel();
    _chamadosPollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      ApiBaseHelper.setBuscaNovosChamados(true);
      await _buscaNovosChamados();
    });
  }

  Future<void> _buscaNovosChamados() async {
    if (_isDisposed || !mounted) return;

    ApiBaseHelper.setBuscaNovosChamados(true);
    final usuarioResp = user.usuarioResp;
    
    if (usuarioResp?.indBloqueado == 1) return;
    
    if (user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
      try {
        final controller = ListaSolicitacoesEmpresaController(context);
        final sol = await controller.buscaListaNovasSolicitacoes(
          indBuscaChamadosRaio: ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA,
        );

        if (!mounted || _isDisposed) return;

        if (sol.isNotEmpty) {
          int index = 0;
          for (var item in sol) {
            if (_isDisposed || !mounted) break;
            
            if (item.indStatusCorrida == ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA) {
              _showBottomFlash(
                item,
                margin: const EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  bottom: 34.0,
                ),
              );
              index++;
              if (index >= 2) break;
            }
          }
        }
      } catch (e) {
        debugPrint('Erro ao buscar novos chamados: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    carregaPerfil();
    // set custom marker pins
    setSourceAndDestinationIcons();
    if (user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
      _verificaGPSAtivo();

      //_buscaNovosChamados();
      _buscaChamadosLeitura();
    } else {
      _verificaGPSAtivo();
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // if (ApiBaseHelper.userSessao!.indTipo == 1) {
    //   // PIPView(
    //   //   builder: (context, isFloating) => botaoPanico(
    //   //       user: user,
    //   //       locationTracker: _locationTracker,
    //   //       userService: _userService),
    //   // );

    //   // if (!ApiBaseHelper.isPipAtivado) {
    //   PIPView.of(context)?.presentBelow(
    //     botaoPanicoSocorro(
    //         user: user,
    //         locationTracker: _locationTracker,
    //         userService: _userService),
    //   );
    //   ApiBaseHelper.isPipAtivado = true;
    //   // }
    //   //ApiBaseHelper.isPipAtivado = false;
    //   //PIPView.of(context)?.dispose();
    switch (state) {
      case AppLifecycleState.resumed:
        print("app in resumed");

        //_buscaNovosChamados();

        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        // if (ApiBaseHelper.userSessao!.indTipo == 1) carregaFlutuante();
        break;
      case AppLifecycleState.paused:
        print("app in paused");

        // if (ApiBaseHelper.userSessao!.indTipo == 1) carregaFlutuante();
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  Future<void> carregaPerfil() async {
    user = ApiBaseHelper.userSessao!;
    if (user == null) user = (await _userService.getCurrentUser())!;
    if (user == null) user = new Usuario();

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

  // carregaFlutuante() {
  //   SystemWindowHeader header = SystemWindowHeader(
  //     button: SystemWindowButton(
  //       text: SystemWindowText(
  //           text: "X",
  //           fontSize: 18,
  //           textColor: Colors.black,
  //           fontWeight: FontWeight.BOLD),
  //       tag: "focus_button",
  //       width: 25,
  //       padding: SystemWindowPadding(left: 25, right: 0, bottom: 0, top: 0),
  //       height: 25,
  //       decoration: SystemWindowDecoration(
  //           startColor: Colors.transparent,
  //           endColor: Colors.transparent,
  //           borderWidth: 0,
  //           borderRadius: 0.0),
  //     ),
  //     decoration: SystemWindowDecoration(
  //         startColor: Colors.transparent,
  //         endColor: Colors.transparent,
  //         borderColor: Colors.transparent,
  //         borderWidth: 1,
  //         borderRadius: 100.0),
  //     title: SystemWindowText(
  //       text: "",
  //       fontSize: 0,
  //     ),
  //   );

  //   SystemWindowFooter footer = SystemWindowFooter(
  //       buttons: [
  //         SystemWindowButton(
  //           text: SystemWindowText(
  //               text: "B",
  //               fontSize: 70,
  //               textColor: Colors.white,
  //               fontWeight: FontWeight.BOLD),
  //           tag:
  //               "simple_button#${user.codMotorista}", //useful to identify button click event
  //           padding:
  //               SystemWindowPadding(left: 20, right: 20, bottom: 0, top: 0),
  //           width: 90,
  //           height: 90,
  //           decoration: SystemWindowDecoration(
  //               startColor: Colors.orange,
  //               endColor: Colors.orange,
  //               borderColor: Colors.orange,
  //               borderWidth: 1,
  //               borderRadius: 100.0),
  //         ),
  //         // SystemWindowButton(
  //         //   text: SystemWindowText(
  //         //       text: "X", fontSize: 12, textColor: Colors.white),
  //         //   tag: "focus_button",
  //         //   width: 25,
  //         //   padding: SystemWindowPadding(left: 0, right: 0, bottom: 0, top: 0),
  //         //   height: 25,
  //         //   decoration: SystemWindowDecoration(
  //         //       startColor: Color.fromRGBO(250, 139, 97, 1),
  //         //       endColor: Color.fromRGBO(247, 28, 88, 1),
  //         //       borderWidth: 0,
  //         //       borderRadius: 100.0),
  //         // ),
  //       ],
  //       padding: SystemWindowPadding(left: 2, right: 0, bottom: 2),
  //       decoration: SystemWindowDecoration(
  //         startColor: Colors.transparent,
  //         borderRadius: 2,
  //         endColor: Colors.transparent,
  //       ),
  //       buttonsPosition: ButtonPosition.LEADING);

  //   SystemWindowBody body = SystemWindowBody(
  //       decoration: SystemWindowDecoration(
  //     startColor: Colors.transparent,
  //     borderRadius: 100,
  //     endColor: Colors.transparent,
  //   ));

  //   SystemAlertWindow.showSystemWindow(
  //     height: 148,
  //     width: 100,
  //     header: header,
  //     body: body,
  //     footer: footer,
  //     margin: SystemWindowMargin(left: 0, right: 0, top: 0, bottom: 0),
  //     gravity: SystemWindowGravity.TOP,
  //     notificationTitle: "Bem",
  //     notificationBody: "Bem",
  //   );
  //   //Using SystemWindowPrefMode.DEFAULT uses Overlay window till Android 10 and bubble in Android 11
  //   //Using SystemWindowPrefMode.OVERLAY forces overlay window instead of bubble in Android 11.
  //   //Using SystemWindowPrefMode.BUBBLE forces Bubble instead of overlay window in Android 10 & above
  // }

  Future<void> verificaStatus() async {
    //SystemAlertWindow.requestPermissions;
  }

  static final CameraPosition initialLocation = CameraPosition(
    target: LatLng(-32.0332, -52.0986),
    zoom: 12.4746,
  );

  Future<Uint8List> getMarker() async {
    // Verifica se o motorista tem tipo e cor definidos
    final motorista = user.usuarioResp?.motoristas?.first;
    final tipoMoto = motorista?.desTipoMoto ?? 'Street';
    final corMoto = motorista?.desCorMoto ?? '#E53935';
    
    // Cria um marker personalizado de moto
    return await _createMotoMarker(tipoMoto, corMoto);
  }

  Future<Uint8List> _createMotoMarker(String tipoMoto, String corHex) async {
    // Parse da cor HEX
    Color corMoto;
    try {
      corMoto = Color(int.parse(corHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      corMoto = Color(0xFFE53935); // Vermelho FOLL padrão
    }

    // Tamanho do marker
    final double size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..style = PaintingStyle.fill;

    // Desenha círculo de fundo branco
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, paint);

    // Desenha borda com a cor da moto
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    paint.color = corMoto;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, paint);

    // Desenha ícone de moto simplificado
    paint.style = PaintingStyle.fill;
    paint.color = corMoto;
    
    // Corpo da moto (retângulo arredondado)
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size / 2 - 15, size / 2 - 5, 30, 10),
      Radius.circular(5),
    );
    canvas.drawRRect(rect, paint);

    // Roda traseira
    canvas.drawCircle(Offset(size / 2 - 12, size / 2 + 8), 6, paint);
    
    // Roda dianteira
    canvas.drawCircle(Offset(size / 2 + 12, size / 2 + 8), 6, paint);

    // Guidão (linha simples)
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size / 2 + 10, size / 2 - 5),
      Offset(size / 2 + 15, size / 2 - 10),
      paint,
    );

    // Finaliza o desenho
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> getMarkerOtherCars() async {
    //return getBytesFromAsset('assets/images/car.png', 35);
    return getBytesFromAsset(AppImages.logoAppNovo, 55);
  }

  void setSourceAndDestinationIcons() async {
    Uint8List imageData = await getMarkerOtherCars();
    otherCars = BitmapDescriptor.fromBytes(imageData);

    // BitmapDescriptor.fromAssetImage(
    //         ImageConfiguration(devicePixelRatio: 2.0), 'assets/images/car.png')
    //     .then((onValue) {
    //   otherCars = onValue;
    // });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> updateMarkerAndCircle(
      LocationData newLocalData, Uint8List imageData) async {
    LatLng latlng = LatLng(newLocalData.latitude!, newLocalData.longitude!);

    //Atualiza a localização atual do motorista
    if (user.indTipo == 1 || user.indTipo == 2) {
      _userService.atualizarLocalMotorista(
          newLocalData.latitude!, newLocalData.longitude!);
      if (this.mounted) {
        if (ApiBaseHelper.IND_TIP_PERFIL_2_EMPRESA == user.indTipo &&
            ApiBaseHelper.lat == 0) {
          ApiBaseHelper.lat = newLocalData.latitude!;
          ApiBaseHelper.long = newLocalData.longitude!;
        } else if (ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA == user.indTipo) {
          ApiBaseHelper.lat = newLocalData.latitude!;
          ApiBaseHelper.long = newLocalData.longitude!;
        }
        print(
            'atualizei lat=${ApiBaseHelper.lat} e long=${ApiBaseHelper.long}');
      }
    }

    //await atualizaMotoristasProximos(newLocalData);
    if (this.mounted) {
      this.setState(() {
        if (user.indTipo == 1) {
          marker = Marker(
              markerId: MarkerId("home"),
              position: latlng,
              rotation: newLocalData.heading!,
              draggable: false,
              zIndex: 2,
              flat: true,
              anchor: Offset(0.5, 0.5),
              icon: BitmapDescriptor.fromBytes(imageData));

          _markers.add(marker!);
        }



        circle = Circle(
            circleId: CircleId("car"),
            radius: newLocalData.accuracy!,
            zIndex: 1,
            strokeColor: Colors.orange,
            center: latlng,
            fillColor: Colors.blue.withAlpha(70));
      });
    }
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

  Future<void> atualizaMotoristasProximos(var newLocalData) async {
    if ((currentTimeInSeconds() - timeStampInicial!) > 60) {
      List<MotoristasProximos>? listMot =
          await _userService.buscaMotoristasProximos();
      if (listMot != null) {
        for (var item in listMot) {
          if (item.desLatitude != null && item.desLongitude != null) {
            _markers.add(Marker(
                markerId: MarkerId(item.codMotorista.toString()),
                position: LatLng(item.desLatitude!, item.desLongitude!),
                rotation: newLocalData.heading!,
                draggable: false,
                zIndex: 2,
                flat: true,
                anchor: Offset(0.5, 0.5),
                icon: otherCars!));
          }
        }
        timeStampInicial = currentTimeInSeconds();
        //this.setState(() {});
      }
    }
  }


  void getCurrentLocation() async {
    try {
      Uint8List imageData = await getMarker();
      var location = await _locationTracker.getLocation();

      updateMarkerAndCircle(location, imageData);

      if (_locationSubscription != null) {
        _locationSubscription!.cancel();
      }

      _locationSubscription =
          _locationTracker.onLocationChanged.listen((newLocalData) {
        if (this.mounted) {
          if (_controller != null) {
            if (!_isMovingManually) {
              _controller!.animateCamera(CameraUpdate.newCameraPosition(
                  new CameraPosition(
                      bearing: 192.8334901395799,
                      target: LatLng(
                          newLocalData.latitude!, newLocalData.longitude!),
                      tilt: 0,
                      zoom: 13.30)));
            }
          }
          updateMarkerAndCircle(newLocalData, imageData);
        }
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
        _showToast(
            context, "Necessário permissão para acessar a localização!!");
      }
      if (e.code == '90') {
        _showToast(context, "Tente novamente sistema GPS fora do ar");
        debugPrint("Tente novamente sistema GPS fora do ar");
      }
    }
  }

  void _showBottomFlash(
    final SolicitacaoMotorista sol, {
    bool persistent = true,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    showFlash(
      context: context,
      persistent: persistent,
      duration: const Duration(seconds: 25),
      builder: (_, controller) {
        return Flash(
          controller: controller,
          //margin: margin,
          //behavior: FlashBehavior.fixed,
          position: FlashPosition.bottom,
          //borderRadius: BorderRadius.circular(8.0),
          //borderColor: Colors.orange,
          //boxShadows: kElevationToShadow[8],
          // backgroundGradient: RadialGradient(
          //   colors: [Colors.orange, Colors.orange],
          //   center: Alignment.topLeft,
          //   radius: 2,
          // ),
          //onTap: () => controller.dismiss(),
          forwardAnimationCurve: Curves.easeInCirc,
          reverseAnimationCurve: Curves.bounceIn,
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.black),
            child: FlashBar(
              controller: controller,
              title: Text(
                ((sol.dbEmpresasByCodEmpresa!.desNomeFantasia ?? "") +
                    " solicitou uma nova corrida"),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              content: Text(("Distancia até estabelecimento: ") +
                  ("" + sol.distance.toString() + " Kms") +
                  (" Local da entrega - ${sol.desEnderecoEntrega} ") +
                  " - Data chamada " +
                  ApiBaseHelper.getDtaFormatada(sol.dthSolicitacao) +
                  " - Valor da corrida: ${sol.vlrTotalMotorista!}"),
              indicatorColor: Colors.black,
              icon: Icon(Icons.info_outline),
              primaryAction: TextButton(
                onPressed: () => controller.dismiss(),
                child: Text('Fechar', style: TextStyle(color: Colors.black)),
              ),
              actions: <Widget>[
                TextButton(
                    onPressed: () async {
                      ListaSolicitacoesEmpresaController controllerSol =
                          ListaSolicitacoesEmpresaController(context);
                      await controllerSol.aceitarCorrida(sol.numSeq!, 1);
                      if (true) {
                        final availableMaps =
                            await mapN.MapLauncher.installedMaps;
                        // print(
                        //     availableMaps); // [AvailableMap { mapName: Google Maps, mapType: google }, ...]

                        // await availableMaps.first.showDirections(
                        //     destination: map.Coords(37.759392, -122.5107336));
                        // MapsSheet.show(
                        //   context: context,
                        //   onMapTap: (map) {
                        //     map.showDirections(
                        //       destination: mapN.Coords(-29.1860583, -51.2377713),
                        //     );
                        //   },
                        // );
                        if (sol.dbEmpresasByCodEmpresa!.desLatitude != null &&
                            sol.dbEmpresasByCodEmpresa!.desLongitude != null) {
                          MapsSheet.show(
                            context: context,
                            onMapTap: (map) {
                              map.showDirections(
                                destination: mapN.Coords(
                                    sol.dbEmpresasByCodEmpresa!.desLatitude!,
                                    sol.dbEmpresasByCodEmpresa!.desLongitude!),
                              );
                            },
                          );
                        } else {
                          context.showSuccessBar(
                            duration: Duration(seconds: 5),
                            content: Text(
                                "Não será possível iniciar navegação, solicitação não possui coordenadas"),
                          );
                        }

                        // bool? existe = await mapN.MapLauncher.isMapAvailable(
                        //     mapN.MapType.google);
                        // if (existe!) {
                        //   await mapN.MapLauncher.showDirections(
                        //       mapType: mapN.MapType.google,
                        //       destination: mapN.Coords(37.759392, -122.5107336));
                        // }

                        // existe = await mapN.MapLauncher.isMapAvailable(
                        //     mapN.MapType.waze);
                        // if (existe!) {
                        //   await mapN.MapLauncher.showDirections(
                        //       mapType: mapN.MapType.waze,
                        //       destination: mapN.Coords(37.759392, -122.5107336));
                        // }

                        // await availableMaps.first.showMarker(
                        //   coords: mapN.Coords(
                        //       sol.dbEmpresasByCodEmpresa!.desLatitude!, sol.dbEmpresasByCodEmpresa!.desLongitude!),
                        //   title: "${sol.dbEmpresasByCodEmpresa!.desNomeFantasia} - Retirada",
                        // );
                      } else {
                        context.showSuccessBar(
                          duration: Duration(seconds: 5),
                          content:
                              Text("Corrida já iniciada por outro motorista."),
                        );
                      }
                    },
                    child: Text('Aceitar e Digirir até estabelecimento',
                        style: TextStyle(color: Colors.black))),
                // TextButton(
                //     onPressed: () => controller.dismiss('No, I do not!'),
                //     child: Text('NO')),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (_ != null) {
        //_showMessage(_.toString());
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Cancela timers periódicos para evitar memory leaks
    _gpsVerificationTimer?.cancel();
    _chamadosPollingTimer?.cancel();
    
    // Cancela subscription de localização
    _locationSubscription?.cancel();
    _locationSubscription = null;
    
    //SystemAlertWindow.closeSystemWindow();
    // PIPView.of(context)?.dispose();
    super.dispose();
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
      child: _buildHomeContent(context),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final route = ModalRoute.of(context);
    final pageName = route?.settings.name ?? "";
    var page = log(pageName);

    return MaterialApp(
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
                visible:
                    user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                        ? true
                        : false,
                child: TextButton.icon(
                  label: Text(
                    "Novas corridas",
                    style: GoogleFonts.poppins(
                      color: Color(0xFFE53935),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  icon: Icon(
                    Icons.newspaper_outlined,
                    color: Color(0xFFE53935),
                    size: 18,
                  ),
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
              Visibility(
                visible:
                    user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                        ? true
                        : false,
                child: Container(
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFFE53935),
                      size: 20,
                    ),
                    onPressed: () {
                      _isMovingManually = false;
                      getCurrentLocation();
                    },
                  ),
                ),
              ),
              Visibility(
                visible:
                    user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                        ? true
                        : false,
                child: Container(
                  margin: EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      if (user.usuarioResp?.indOffline == 1) {
                        _userService.changeStatusUser(user.usuarioResp, 0);
                        user.usuarioResp?.indOffline = 0;
                      } else if (user.usuarioResp?.indOffline == null ||
                          user.usuarioResp?.indOffline == 0) {
                        _userService.changeStatusUser(user.usuarioResp, 1);
                        user.usuarioResp?.indOffline = 1;
                      }
                      this.setState(() {});
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (user.usuarioResp?.indOffline == 1
                            ? Color(0xFF9E9E9E)
                            : Color(0xFF2ECC71)),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (user.usuarioResp?.indOffline == 1
                                ? Color(0xFF9E9E9E)
                                : Color(0xFF2ECC71))
                                .withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            (user.usuarioResp?.indOffline == 1 ? "Offline" : "Online"),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      Icons.menu_rounded,
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
          body: user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
              ? Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: initialLocation,
                      markers: _markers,
                      //circles: Set.of((circle != null) ? [circle!] : []),
                      onMapCreated: (GoogleMapController controller) {
                        controller.setMapStyle(Utils.mapStyles);
                        _controller = controller;
                        _isMovingManually = false;
                        getCurrentLocation();
                      },
                      onCameraMoveStarted: () {
                        _isMovingManually = true;
                      },
                    ),
                    // Logo FOLL no canto inferior esquerdo
                    Positioned(
                      left: 12,
                      bottom: 100,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          AppImages.logo,
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                    // Badge de status online/offline no canto superior direito
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (user.usuarioResp?.indOffline == 1
                              ? Color(0xFF9E9E9E)
                              : Color(0xFF2ECC71)),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (user.usuarioResp?.indOffline == 1
                                  ? Color(0xFF9E9E9E)
                                  : Color(0xFF2ECC71))
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              (user.usuarioResp?.indOffline == 1 ? "Offline" : "Online"),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : InfoCorridaPage(
                  userInfo: user,
                ), // montaTelaInicialEmpresa(width),
          floatingActionButton: botaoPanico(
              user: user,
              locationTracker: _locationTracker,
              userService: _userService),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          drawer: Drawer(
            backgroundColor: Colors.white,
            child: ListView(
              scrollDirection: Axis.vertical,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F6FA),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (!mounted) return;
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            if (mounted) {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.editarCadastro,
                              );
                              if (mounted) {
                                this.setState(() {});
                              }
                            }
                          });
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 30.0,
                              backgroundColor: Color(0xFFE53935),
                              backgroundImage: (user.usuarioResp?.motoristas != null &&
                                      user.usuarioResp!.motoristas!.isNotEmpty &&
                                      user.usuarioResp!.motoristas!.first.desFotoPerfil != null &&
                                      user.usuarioResp!.motoristas!.first.desFotoPerfil!.isNotEmpty)
                                  ? MemoryImage(base64.decode(user.usuarioResp!.motoristas!.first.desFotoPerfil!))
                                  : null,
                              child: (user.usuarioResp?.motoristas == null ||
                                      user.usuarioResp!.motoristas!.isEmpty ||
                                      user.usuarioResp!.motoristas!.first.desFotoPerfil == null ||
                                      user.usuarioResp!.motoristas!.first.desFotoPerfil!.isEmpty)
                                  ? Text(
                                      (user.desNome?.toUpperCase().substring(0, 1) ?? 'A'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        user.desNome ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        user.usuario ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                    visible: user.indTipo == 1 ? true : true,
                    child: ListTile(
                        leading: Icon(Icons.person_outline, color: Color(0xFF9E9E9E)),
                        title: Text(
                          "Dados",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        subtitle: Text(
                          "Minhas informações",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF757575),
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                        onTap: () async {
                          if (!mounted) return;
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            if (mounted) {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.editarCadastro,
                              );
                              if (mounted) {
                                this.setState(() {});
                              }
                            }
                          });
                        }),
                    ),
                Visibility(
                  visible: user.indTipo == 1 ? true : false,
                  child: ListTile(
                      leading: Icon(Icons.chat_bubble_outline, color: Color(0xFF9E9E9E)),
                      title: Text(
                        "Mensagens",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      subtitle: Text(
                        "Conversas e mensagens",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF757575),
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
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
                                'currentUserName': user.desNome ?? 'Motorista',
                                'currentUserType': 'motorista',
                              },
                            );
                          }
                        });
                      }),
                ),
                Visibility(
                  visible: user.indTipo == 1 ? true : false,
                  child: ListTile(
                      leading: Icon(Icons.delivery_dining_outlined, color: Color(0xFF9E9E9E)),
                      title: Text(
                        "Corridas",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      subtitle: Text(
                        "Corridas em andamento",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF757575),
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
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
                    visible: user.indTipo == 1 ? false : false,
                    child: ListTile(
                        leading: Icon(Icons.motorcycle_outlined, color: Color(0xFF9E9E9E)),
                        title: Text(
                          "Corridas",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        subtitle: Text(
                          "Minhas corridas",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF757575),
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                        onTap: () {
                          if (!mounted) return;
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.corridasEmpresa,
                                arguments: {'indTipoDefault': -1},
                              );
                            }
                          });
                        }),
                    ),
                Visibility(
                  visible:
                      user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                          ? true
                          : true,
                  child: ListTile(
                      leading: Icon(Icons.star_outline, color: Color(0xFF9E9E9E)),
                      title: Text(
                        "Saldos",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      subtitle: Text(
                        "Meus valores",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF757575),
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                      onTap: () {
                        if (!mounted) return;
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.saldos,
                              arguments: {'userInfo': user},
                            );
                          }
                        });
                      }),
                ),
                Visibility(
                  visible:
                      user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                          ? true
                          : true,
                  child: ListTile(
                      leading: Icon(Icons.history_outlined, color: Color(0xFF9E9E9E)),
                      title: Text(
                        "Histórico",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      subtitle: Text(
                        user.indTipo ==
                                ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                            ? "Meu histórico de entregas"
                            : "Histórico de chamados",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF757575),
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                      onTap: () {
                        if (!mounted) return;
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            if (user.indTipo ==
                                ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.corridas,
                              );
                            } else {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.corridasEmpresa,
                                arguments: {'indTipoDefault': -1},
                              );
                            }
                          }
                        });
                      }),
                ),
                Visibility(
                  visible:
                      user.indTipo == ApiBaseHelper.IND_TIP_PERFIL_1_MOTORISTA
                          ? false
                          : false,
                  child: ListTile(
                      leading: Icon(Icons.contact_phone_outlined, color: Color(0xFF9E9E9E)),
                      title: Text(
                        "Números gerais",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      subtitle: Text(
                        "Info gerencial corridas",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF757575),
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                      onTap: () {
                        if (!mounted) return;
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.infoCorrida,
                              arguments: user,
                            );
                          }
                        });
                      }),
                ),
                Divider(height: 1, color: Color(0xFFE6E7EB)),
                Visibility(
                  visible: user.indTipo == 1 ? true : true,
                  child: ListTile(
                      leading: Icon(Icons.logout_outlined, color: Color(0xFF9E9E9E)),
                      title: Text(
                        "Sair",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      onTap: () {
                        showAlertDialog(context);
                      }),
                ),
                SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
    );
  }

  showAlertDialog(BuildContext context) {
    const Color primaryRed = Color(0xFFE53935);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF757575);
    const Color borderColor = Color(0xFFE6E7EB);

    Widget cancelButton = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        "Cancelar",
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      onPressed: () async {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Fecha o dialog primeiro
        await _userService.logoffLocalDB();
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.splash,
          (Route<dynamic> route) => false,
        );
      },
    );

    AlertDialog alert = AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        "Confirmar",
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      content: Text(
        "Deseja realmente sair?",
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
      actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
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
                color: Colors.white,
                width: 3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(AppImages.logo),
            ),
            backgroundColor: Color(0xFFE53935),
            onPressed: () async {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.corridas,
                    arguments: {
                      'indTipoDefault': ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO,
                    },
                  );
                }
              });
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
