// lib/home/map_page.dart
// NOTE: Arquivo extraído de lib/home/home_page.dart (linhas aproximadas: 400-1140)
// Preserva 100% da lógica: métodos, controllers, streams, subscriptions

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/bussiness/service/user_service.dart';
import 'package:delivery_front/core/app_images.dart';
import 'package:delivery_front/core/core.dart';
import 'package:delivery_front/core/routes/app_routes.dart';
import 'package:delivery_front/shared/components/Utils.dart';
import 'package:delivery_front/ui/app_drawer.dart';
import 'package:delivery_front/shared/models/motorista/models/motoristas_proximos.dart';
import 'package:delivery_front/shared/models/usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';

int currentTimeInSeconds() {
  var ms = (new DateTime.now()).millisecondsSinceEpoch;
  return (ms / 1000).round();
}

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  StreamSubscription? _locationSubscription;
  Timer? _gpsVerificationTimer;
  bool _isDisposed = false;
  loc.Location _locationTracker = loc.Location();

  Usuario user = Usuario();
  int? timeStampInicial = 0;

  UserService _userService = new UserService();
  bool _isMovingManually = false;

  Marker? marker;
  Circle? circle;
  GoogleMapController? _controller;
  Set<Marker> _markers = Set<Marker>();

  BitmapDescriptor? otherCars;

  static final CameraPosition initialLocation = CameraPosition(
    target: LatLng(-32.0332, -52.0986),
    zoom: 12.4746,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    carregaPerfil();
    setSourceAndDestinationIcons();
    _verificaGPSAtivo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _gpsVerificationTimer?.cancel();
    _isDisposed = true;
    _controller?.dispose();
    super.dispose();
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
        return;
      }

      try {
        final serviceEnabled = await _locationTracker.serviceEnabled();
        if (!serviceEnabled) {
          final hasPermission = await _locationTracker.hasPermission() == loc.PermissionStatus.granted;
          if (hasPermission) {
            final position = await Geolocator.getCurrentPosition();
            ApiBaseHelper.lat = position.latitude;
            ApiBaseHelper.long = position.longitude;
          } else {
            await _locationTracker.requestPermission();
          }
        }
      } catch (e) {
        debugPrint('Erro ao verificar GPS: $e');
      }
    });
  }

  Future<void> carregaPerfil() async {
    // Sempre usa o ApiBaseHelper.userSessao como fonte da verdade
    final currentUser = ApiBaseHelper.userSessao;
    if (currentUser != null) {
      user = currentUser;
    } else {
      // Se não existe, busca do servidor
      final fetchedUser = await _userService.getCurrentUser();
      if (fetchedUser != null) {
        user = fetchedUser;
        ApiBaseHelper.userSessao = fetchedUser;
      } else {
        user = Usuario();
      }
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      late final Map<ph.Permission, ph.PermissionStatus> statusess;

      if (androidInfo.version.sdkInt >= 33) {
        statusess = await [ph.Permission.notification].request();

        var allAccepted = true;
        statusess.forEach((permission, status) {
          if (status != ph.PermissionStatus.granted) {
            allAccepted = false;
          }
        });

        if (!allAccepted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Necessário autorizar notificações para receber novas informações"),
            ),
          );
        }
      }
    }
  }

  Future<Uint8List> getMarker() async {
    // Atualiza os dados do usuário antes de pegar a cor e tipo da moto
    if (user.usuarioResp == null || user.usuarioResp!.motoristas == null || user.usuarioResp!.motoristas!.isEmpty) {
      // Tenta buscar dados atualizados do usuário
      final updatedUser = await _userService.getCurrentUser();
      if (updatedUser != null && updatedUser.usuarioResp != null) {
        user.usuarioResp = updatedUser.usuarioResp;
      }
    }
    
    // Verifica se o motorista tem tipo e cor definidos
    final motorista = user.usuarioResp?.motoristas?.first;
    final tipoMoto = (motorista?.desTipoMoto?.isNotEmpty == true) 
        ? motorista!.desTipoMoto! 
        : 'Street';
    final corMoto = (motorista?.desCorMoto?.isNotEmpty == true) 
        ? motorista!.desCorMoto! 
        : '#E53935';
    
    print('🎨 Criando marker - Tipo: $tipoMoto, Cor: $corMoto');
    
    // Cria um marker personalizado de moto com a cor e tipo escolhidos
    return await _createMotoMarker(tipoMoto, corMoto);
  }

  Future<Uint8List> _createMotoMarker(String tipoMoto, String corHex) async {
    // Parse da cor HEX
    Color corMoto;
    try {
      // Remove # se existir e adiciona 0xFF para alpha
      String hex = corHex.replaceFirst('#', '');
      if (hex.length == 6) {
        corMoto = Color(int.parse('0xFF$hex'));
      } else if (hex.length == 8) {
        corMoto = Color(int.parse('0x$hex'));
      } else {
        corMoto = Color(0xFFE53935); // Vermelho FOLL padrão
      }
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

    // Desenha ícone de moto baseado no tipo
    paint.style = PaintingStyle.fill;
    paint.color = corMoto;
    
    // Normaliza o tipo da moto (case insensitive)
    final tipoNormalizado = tipoMoto.toLowerCase().trim();
    
    // Desenha a moto baseado no tipo
    if (tipoNormalizado == 'scooter') {
      _drawScooter(canvas, paint, size);
    } else if (tipoNormalizado == 'sport') {
      _drawSport(canvas, paint, size);
    } else if (tipoNormalizado == 'big trail' || tipoNormalizado == 'bigtrail') {
      _drawBigTrail(canvas, paint, size);
    } else if (tipoNormalizado == 'cargo') {
      _drawCargo(canvas, paint, size);
    } else {
      // Street (padrão) ou qualquer outro tipo
      _drawStreet(canvas, paint, size);
    }

    // Finaliza o desenho
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Desenha moto tipo Street (padrão)
  void _drawStreet(Canvas canvas, Paint paint, double size) {
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
  }

  // Desenha moto tipo Scooter (mais compacta, guidão mais baixo)
  void _drawScooter(Canvas canvas, Paint paint, double size) {
    // Corpo mais curto e arredondado
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size / 2 - 12, size / 2 - 3, 24, 8),
      Radius.circular(8),
    );
    canvas.drawRRect(rect, paint);

    // Rodas menores e mais próximas
    canvas.drawCircle(Offset(size / 2 - 8, size / 2 + 7), 5, paint);
    canvas.drawCircle(Offset(size / 2 + 8, size / 2 + 7), 5, paint);

    // Guidão mais baixo e reto
    paint.strokeWidth = 2.5;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size / 2 + 8, size / 2 - 3),
      Offset(size / 2 + 12, size / 2 - 6),
      paint,
    );
  }

  // Desenha moto tipo Sport (mais aerodinâmica, guidão mais baixo)
  void _drawSport(Canvas canvas, Paint paint, double size) {
    // Corpo mais longo e inclinado
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size / 2 - 18, size / 2 - 7, 36, 8),
      Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);

    // Rodas maiores
    canvas.drawCircle(Offset(size / 2 - 14, size / 2 + 9), 7, paint);
    canvas.drawCircle(Offset(size / 2 + 14, size / 2 + 9), 7, paint);

    // Guidão esportivo (mais baixo)
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size / 2 + 12, size / 2 - 7),
      Offset(size / 2 + 16, size / 2 - 12),
      paint,
    );
    
    // Carenagem frontal (pequeno triângulo)
    paint.style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size / 2 + 16, size / 2 - 12);
    path.lineTo(size / 2 + 20, size / 2 - 8);
    path.lineTo(size / 2 + 16, size / 2 - 7);
    path.close();
    canvas.drawPath(path, paint);
  }

  // Desenha moto tipo Big Trail (mais alta, guidão mais alto)
  void _drawBigTrail(Canvas canvas, Paint paint, double size) {
    // Corpo mais alto
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size / 2 - 16, size / 2 - 8, 32, 12),
      Radius.circular(6),
    );
    canvas.drawRRect(rect, paint);

    // Rodas grandes
    canvas.drawCircle(Offset(size / 2 - 13, size / 2 + 10), 8, paint);
    canvas.drawCircle(Offset(size / 2 + 13, size / 2 + 10), 8, paint);

    // Guidão alto (trail)
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size / 2 + 10, size / 2 - 8),
      Offset(size / 2 + 14, size / 2 - 15),
      paint,
    );
    
    // Pequeno para-brisa (retângulo pequeno)
    paint.style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(size / 2 + 12, size / 2 - 15, 4, 3),
      paint,
    );
  }

  // Desenha moto tipo Cargo (com caixa de carga)
  void _drawCargo(Canvas canvas, Paint paint, double size) {
    // Corpo da moto
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size / 2 - 15, size / 2 - 5, 30, 10),
      Radius.circular(5),
    );
    canvas.drawRRect(rect, paint);

    // Caixa de carga (retângulo atrás)
    paint.color = paint.color.withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size / 2 - 18, size / 2 - 2, 12, 8),
        Radius.circular(3),
      ),
      paint,
    );
    paint.color = paint.color.withOpacity(1.0); // Restaura opacidade

    // Rodas
    canvas.drawCircle(Offset(size / 2 - 12, size / 2 + 8), 6, paint);
    canvas.drawCircle(Offset(size / 2 + 12, size / 2 + 8), 6, paint);

    // Guidão
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size / 2 + 10, size / 2 - 5),
      Offset(size / 2 + 15, size / 2 - 10),
      paint,
    );
  }

  Future<Uint8List> getMarkerOtherCars() async {
    return getBytesFromAsset(AppImages.logoAppNovo, 55);
  }

  void setSourceAndDestinationIcons() async {
    Uint8List imageData = await getMarkerOtherCars();
    otherCars = BitmapDescriptor.fromBytes(imageData);
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
      loc.LocationData newLocalData, Uint8List imageData) async {
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

    if (this.mounted) {
      this.setState(() {
        // Limpa markers antigos do motorista antes de adicionar novo
        _markers.removeWhere((m) => m.markerId.value == "home");
        
        if (user.indTipo == 1) {
          marker = Marker(
              markerId: MarkerId("home"),
              position: latlng,
              rotation: newLocalData.heading ?? 0.0,
              draggable: false,
              zIndex: 2,
              flat: true,
              anchor: Offset(0.5, 0.5),
              icon: BitmapDescriptor.fromBytes(imageData));

          _markers.add(marker!);
        }

        circle = Circle(
            circleId: CircleId("car"),
            radius: newLocalData.accuracy ?? 50.0,
            zIndex: 1,
            strokeColor: Colors.orange,
            center: latlng,
            fillColor: Colors.blue.withAlpha(70));
      });
    }
  }

  Future<void> atualizaMotoristasProximos(loc.LocationData newLocalData) async {
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
      }
    }
  }

  void getCurrentLocation() async {
    try {
      // Solicita permissão se necessário
      bool serviceEnabled = await _locationTracker.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationTracker.requestService();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Serviço de localização desabilitado. Por favor, ative o GPS."),
              ),
            );
          }
          return;
        }
      }

      loc.PermissionStatus permissionGranted = await _locationTracker.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _locationTracker.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Permissão de localização negada. Por favor, permita o acesso à localização."),
              ),
            );
          }
          return;
        }
      }

      Uint8List imageData = await getMarker();
      var currentLocation = await _locationTracker.getLocation();

      // Centraliza a câmera na localização atual imediatamente
      if (_controller != null && mounted) {
        _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(currentLocation.latitude!, currentLocation.longitude!),
              zoom: 15.0,
            ),
          ),
        );
      }

      updateMarkerAndCircle(currentLocation, imageData);

      // Cancela subscription anterior se existir
      if (_locationSubscription != null) {
        _locationSubscription!.cancel();
      }

      // Configura atualização contínua da localização
      _locationTracker.changeSettings(
        accuracy: loc.LocationAccuracy.high,
        interval: 1000, // Atualiza a cada 1 segundo
        distanceFilter: 5, // Atualiza a cada 5 metros
      );

      _locationSubscription =
          _locationTracker.onLocationChanged.listen((newLocalData) {
        if (this.mounted) {
          if (_controller != null) {
            if (!_isMovingManually) {
              _controller!.animateCamera(CameraUpdate.newCameraPosition(
                  new CameraPosition(
                      bearing: newLocalData.heading ?? 0.0,
                      target: LatLng(
                          newLocalData.latitude!, newLocalData.longitude!),
                      tilt: 0,
                      zoom: 15.0))); // Zoom mais próximo para melhor visualização
            }
          }
          updateMarkerAndCircle(newLocalData, imageData);
        }
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Necessário permissão para acessar a localização!!"),
            ),
          );
        }
      }
      if (e.code == '90') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tente novamente sistema GPS fora do ar"),
            ),
          );
        }
        debugPrint("Tente novamente sistema GPS fora do ar");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Color(0xFF1A1A1A),
                  size: 20,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            );
          },
        ),
        title: Text(
          "Mapa — Nova corrida",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Botão centralizar localização
          Container(
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
          // Botão Online/Offline
          Container(
            margin: EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                // Usa sempre o ApiBaseHelper.userSessao como fonte da verdade
                final currentUser = ApiBaseHelper.userSessao ?? user;
                if (currentUser.usuarioResp == null) return;
                
                // Determina o novo status (1 = Offline, 0 = Online)
                final novoStatus = (currentUser.usuarioResp!.indOffline == 1) ? 0 : 1;
                
                print('🔄 Mudando status: ${currentUser.usuarioResp!.indOffline} -> $novoStatus');
                
                // Atualiza no servidor
                await _userService.changeStatusUser(currentUser.usuarioResp, novoStatus);
                
                // Atualiza no ApiBaseHelper.userSessao (fonte da verdade)
                // IMPORTANTE: Atualiza diretamente no objeto do ApiBaseHelper
                if (ApiBaseHelper.userSessao != null && ApiBaseHelper.userSessao!.usuarioResp != null) {
                  ApiBaseHelper.userSessao!.usuarioResp!.indOffline = novoStatus;
                }
                
                // Atualiza também no currentUser e user local
                currentUser.usuarioResp!.indOffline = novoStatus;
                if (user.usuarioResp != null) {
                  user.usuarioResp!.indOffline = novoStatus;
                }
                
                // Garante que ApiBaseHelper.userSessao aponta para o objeto atualizado
                ApiBaseHelper.userSessao = currentUser;
                
                // Salva no banco local usando o ApiBaseHelper.userSessao
                await _userService.saveLocalDB(ApiBaseHelper.userSessao!);
                
                print('✅ Status atualizado: indOffline = ${ApiBaseHelper.userSessao?.usuarioResp?.indOffline}');
                print('✅ ApiBaseHelper.userSessao.indOffline = ${ApiBaseHelper.userSessao?.usuarioResp?.indOffline}');
                
                // Atualiza a UI
                if (mounted) {
                  setState(() {});
                }
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
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialLocation,
            markers: _markers,
            circles: Set.of((circle != null) ? [circle!] : []),
            myLocationEnabled: true, // Mostra o ponto azul do usuário
            myLocationButtonEnabled: false, // Desabilita botão padrão (usamos o customizado)
            zoomControlsEnabled: true,
            compassEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              controller.setMapStyle(Utils.mapStyles);
              _controller = controller;
              _isMovingManually = false;
              // Inicia rastreamento imediatamente
              getCurrentLocation();
            },
            onCameraMoveStarted: () {
              _isMovingManually = true;
            },
            onCameraIdle: () {
              // Permite que a câmera volte a seguir após um tempo sem movimento manual
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && !_isMovingManually) {
                  _isMovingManually = false;
                }
              });
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
          // Badge de status online/offline no canto superior direito (já está na AppBar)
        ],
      ),
      drawer: AppDrawer(
        user: user,
        userService: _userService,
      ),
      floatingActionButton: botaoPanico(
        user: user,
        locationTracker: _locationTracker,
        userService: _userService,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

// COPIA: botaoPanico extraído de lib/home/home_page.dart (linha ~1586)
class botaoPanico extends StatelessWidget {
  const botaoPanico({
    Key? key,
    required this.user,
    required loc.Location locationTracker,
    required UserService userService,
  })  : _locationTracker = locationTracker,
        _userService = userService,
        super(key: key);

  final Usuario user;
  final loc.Location _locationTracker;
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

