// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:cyberme_flutter/api/location.dart';
import 'package:cyberme_flutter/pocket/app/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationView extends ConsumerStatefulWidget {
  const LocationView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LocationViewState();
}

class _LocationViewState extends ConsumerState<LocationView> {
  MapController controller = MapController();
  LatLng? choosed;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    ref.read(getTrackSummaryProvider.future).then((d) =>
        controller.move(d.values.first.first.gcLatLng, controller.camera.zoom));
  }

  @override
  Widget build(BuildContext context) {
    final d = (ref.watch(getTrackSummaryProvider).value ?? {})
        .entries
        .toList(growable: false);
    final u = d.expand((element) => element.value).toList(growable: false)
      ..sort((a, b) {
        if (a.gcLatLng == choosed)
          return 100;
        else if (b.gcLatLng == choosed)
          return -100;
        else
          return a.updateTime.compareTo(b.updateTime);
      });
    return Scaffold(
        body: Stack(children: [
      Column(children: [
        Expanded(
            flex: 3,
            child: FlutterMap(
                mapController: controller,
                options: const MapOptions(
                    interactionOptions:
                        InteractionOptions(enableMultiFingerGestureRace: true),
                    initialZoom: 13,
                    initialCenter: LatLng(30, 114)),
                children: [
                  TileLayer(
                      urlTemplate:
                          //'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          //'http://gac-geo.googlecnapps.cn/maps/vt?lyrs=m&x={x}&y={y}&z={z}'
                          'http://webrd01.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scale=1&style=8'
                          ''),
                  MarkerLayer(
                      markers: u.map((e) {
                    //final name = u.key;
                    final g = e.gcLatLng;
                    return Marker(
                        point: g,
                        child: Icon(Icons.place,
                            color: choosed == g ? Colors.red : Colors.orange));
                  }).toList(growable: false))
                ])),
        Expanded(
            flex: 2,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final dd = d[index];
                  return buildTrackItems(dd.key, dd.value);
                },
                itemCount: d.length))
      ]),
      const Positioned(left: 5, top: 5, child: SafeArea(child: BackButton()))
    ]));
  }

  Widget buildTrackItems(String name, List<LocationInfo> data) {
    return SizedBox(
        width: 200,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 15,
                          height: 2,
                          fontWeight: FontWeight.bold))),
              Expanded(
                  child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final e = data[index];
                        return buildLocationRow(context, e);
                      },
                      itemCount: data.length))
            ]));
  }

  InkWell buildLocationRow(BuildContext context, LocationInfo e) {
    final g = e.gcLatLng;
    final isChoosed = choosed == g;
    return InkWell(
        onLongPress: () => showDebugBar(context, e),
        onTap: () {
          setState(() => choosed = g);
          controller.move(g, controller.camera.zoom);
        },
        child: Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 3),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(e.updateTime.split(".").first,
                      style: isChoosed
                          ? const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)
                          : const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(e.note1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight:
                              isChoosed ? FontWeight.bold : FontWeight.normal))
                ])));
  }
}
