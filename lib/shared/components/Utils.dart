import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:map_launcher/map_launcher.dart';

class Utils {
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

    return Colors.orange;
  }

  static Future<List<AvailableMap>> getInstalledMaps() {
    return MapLauncher.installedMaps;
  }

  static Future<List<Location>> getLocationByAddress(String addres) {
    //Formato Endereco rua numero, cidade
    return locationFromAddress(addres);
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> getSnackBar(
      String msg, BuildContext context) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 5),
        content: Text(msg),
      ),
    );
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
}
