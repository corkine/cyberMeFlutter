import 'package:cyberme_flutter/api/location.dart';
import 'package:cyberme_flutter/pocket/app/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    return Scaffold(
        body: Stack(children: [
      Column(children: [
        Expanded(
            flex: 3,
            child: FlutterMap(
                mapController: controller,
                options: const MapOptions(
                    initialZoom: 13, initialCenter: LatLng(30, 114)),
                children: [
                  TileLayer(
                      urlTemplate:
                          //'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          //'http://gac-geo.googlecnapps.cn/maps/vt?lyrs=m&x={x}&y={y}&z={z}'
                          'http://webrd01.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scale=1&style=8'
                          ''),
                  MarkerLayer(
                      markers: d
                          .expand((u) => u.value.map((e) {
                                //final name = u.key;
                                return Marker(
                                    point: e.gcLatLng,
                                    child: const Icon(Icons.place,
                                        color: Colors.deepOrange));
                              }).toList(growable: false))
                          .toList(growable: false))
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
      const Positioned(left: 5, top: 5, child: BackButton())
    ]));
  }

  Widget buildTrackItems(String name, List<LocationInfo> data) {
    return SizedBox(
        width: 200,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 15, height: 2, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                  child: ListView.builder(
                      itemBuilder: (context, index) {
                        final e = data[index];
                        return InkWell(
                            onLongPress: () => showDebugBar(context, e),
                            onTap: () {
                              controller.move(
                                  e.gcLatLng, controller.camera.zoom);
                            },
                            child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, bottom: 3),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e.updateTime.split(".").first,
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13)),
                                      Text(e.note1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 11))
                                    ])));
                      },
                      itemCount: data.length))
            ]));
  }
}
