import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:delivery_front/shared/components/app_alert.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';

class Utils {
  static final _brlFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
    decimalDigits: 2,
  );

  static String formatBRL(double? value) {
    return _brlFormatter.format(value ?? 0.0);
  }

  static String getDesStatusCorrida(int? indStatusCorrida) {
    if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA == indStatusCorrida)
      return "Nova corrida";

    if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
        indStatusCorrida) return "Corrida aceita";

    if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO == indStatusCorrida)
      return "Corrida em andamento";

    if (ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA == indStatusCorrida)
      return "Corrida concluída";

    if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA == indStatusCorrida)
      return "Corrida cancelada";

    if (ApiBaseHelper.IND_STATUS_CORRIDA_5_AGUARDANDO_COBRANCA == indStatusCorrida)
      return "Aguardando cobrança";

    if (ApiBaseHelper.IND_STATUS_CORRIDA_6_PENDENCIA_ABERTA == indStatusCorrida)
      return "Pendência aberta";

    return "";
  }

  static int getDesStatusProxStatusCorrida(int? indStatusCorrida) {
    if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA == indStatusCorrida)
      return ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
        indStatusCorrida)
      return ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO == indStatusCorrida)
      return ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA;

    // if (ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA == indStatusCorrida)
    //   return "Corrida concluída";
    //
    // if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA == indStatusCorrida)
    //   return "Corrida cancelada";

    return 0;
  }

  static String getDesTextoProxStatusCorrida(int? indStatusCorrida) {
    if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA == indStatusCorrida)
      return "Aceitar";

    if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
        indStatusCorrida) return "Iniciar";

    if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO == indStatusCorrida)
      return "Encerrar";

     if (ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA == indStatusCorrida)
       return "Concluída";
    //
     if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA == indStatusCorrida)
       return "Cancelada";

    return "";
  }

  static Icon getIconStatusCorrida(int? indStatusCorrida) {
    return Icon(getIconStatusCorridaIconData(indStatusCorrida));
  }

  static IconData getIconStatusCorridaIconData(int? indStatusCorrida) {
    if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA == indStatusCorrida)
      return Icons.near_me;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
        indStatusCorrida) return Icons.where_to_vote;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO == indStatusCorrida)
      return Icons.motorcycle_sharp;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA == indStatusCorrida)
      return Icons.insert_emoticon;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA == indStatusCorrida)
      return Icons.cancel;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_5_AGUARDANDO_COBRANCA == indStatusCorrida)
      return Icons.payments_rounded;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_6_PENDENCIA_ABERTA == indStatusCorrida)
      return Icons.warning_amber_rounded;

    return Icons.where_to_vote_sharp;
  }

  static MaterialColor getColorStatusCorrida(int? indStatusCorrida) {
    if (ApiBaseHelper.IND_STATUS_CORRIDA_0_NOVA_CORRIDA == indStatusCorrida)
      return Colors.orange;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_1_SOLICITACAO_ACEITA ==
        indStatusCorrida) return Colors.blue;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_2_EM_ANDAMENTO == indStatusCorrida)
      return Colors.orange;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_3_CONCLUIDA == indStatusCorrida)
      return Colors.green;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_4_CANCELADA == indStatusCorrida)
      return Colors.red;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_5_AGUARDANDO_COBRANCA == indStatusCorrida)
      return Colors.purple;

    if (ApiBaseHelper.IND_STATUS_CORRIDA_6_PENDENCIA_ABERTA == indStatusCorrida)
      return Colors.deepOrange;

    return Colors.orange;
  }

  static Future<List<AvailableMap>> getInstalledMaps() {
    return MapLauncher.installedMaps;
  }

  static Future<List<Location>> getLocationByAddress(String addres) {
    //Formato Endereco rua numero, cidade
    return locationFromAddress(addres);
  }

  static void getSnackBar(String msg, BuildContext context,
      {bool isError = false, bool isSuccess = false}) {
    AppAlert.show(context, msg, isError: isError, isSuccess: isSuccess);
  }

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

  static String darkMapStyles = '''[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]''';
}
