import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:map_launcher/map_launcher.dart' as mapN;

class MapsSheet {
  static show({
    required BuildContext context,
    required Function(mapN.AvailableMap map) onMapTap,
  }) async {
    final availableMaps = await mapN.MapLauncher.installedMaps;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    child: Wrap(
                      children: <Widget>[
                        for (var map in availableMaps)
                          ListTile(
                            onTap: () => onMapTap(map),
                            title: Text(map.mapName),
                            leading: SvgPicture.asset(
                              map.icon,
                              height: 30.0,
                              width: 30.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
