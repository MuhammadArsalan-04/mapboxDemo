import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:map_box_app/navigation/navigation_view.dart';
import 'package:map_box_app/utils/api_key.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:map_box_app/map_screen/search_api.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:permission_handler/permission_handler.dart' as permission;

import 'package:mapbox_polyline_points/mapbox_polyline_points.dart'
    as polyLines;

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  MapboxMap? customMapboxMap;
  Location location = Location();

  LocationData? _locationData;

  bool showNavigationIcon = false;

  double? destinationLat;
  double? destinationLong;
  String? destinationName;
  double? originLat;
  double? originLong;
  String? originName;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //checking location permission
    Future.delayed(Duration.zero).then(
      (_) async {
        permission.PermissionWithService locationPermission =
            permission.Permission.location;
        PermissionStatus _locationPermissionStatus;

        bool _serviceEnabled;

        _serviceEnabled = await location.serviceEnabled();
        if (!_serviceEnabled) {
          _serviceEnabled = await location.requestService();
        }

        _locationPermissionStatus = await location.hasPermission();
        if (_locationPermissionStatus == PermissionStatus.denied) {
          _locationPermissionStatus = await location.requestPermission();
        }

        if (await locationPermission.isDenied ||
            await locationPermission.isPermanentlyDenied ||
            await locationPermission.isLimited) {
          permission.Permission.locationWhenInUse.request();
        }

        _locationData = await location.getLocation();

        //animating to user current location
        if (customMapboxMap != null && _locationData != null) {
          CameraOptions cameraOptions = CameraOptions(
            pitch: 10,
            zoom: 19,
            center: Point(
              coordinates:
                  Position(_locationData!.longitude!, _locationData!.latitude!),
            ).toJson(),
          );

          customMapboxMap?.flyTo(
            cameraOptions,
            MapAnimationOptions(
              duration: 6000,
              startDelay: 0,
            ),
          );

          _onMapCreated(customMapboxMap!);
        }

        debugPrint("Here1");
        final response = await Dio().get(
            "https://api.mapbox.com/geocoding/v5/mapbox.places/${_locationData!.longitude},${_locationData!.latitude}.json?access_token=${APIKEY.accessToken}");

        debugPrint(response.data.toString());

        debugPrint("Here 2");
        if (response.statusCode == 200) {
          debugPrint("Here 3");
          originName = response.data["features"][0]["text"];
          originLat = _locationData!.latitude;
          originLong = _locationData!.longitude;

          debugPrint("Assigned");
        }

        setState(() {});
      },
    );
  }

  bool isDark = false;
  bool isSearchBarFocused = false;

  List<Map<String, dynamic>> searchResults = [];
  FloatingSearchBarController searchController = FloatingSearchBarController();

  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  PointAnnotation? markerPoinAnnotation;
  PolylineAnnotation? polyLinePointAnnotaion;

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    MapWidget mapWidget = MapWidget(
      resourceOptions: ResourceOptions(accessToken: APIKEY.accessToken),
      key: const ValueKey("mapWidget"),
      onMapCreated: _onMapCreated,
      // styleUri: MapboxStyles.MAPBOX_STREETS,
    );
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: startNavigation,
            child: const Icon(Icons.navigation),
          ),
          const SizedBox(
            height: 6,
          ),
          FloatingActionButton(
            onPressed: () async {
              await onCameraPositionChanged(
                  _locationData!.longitude!, _locationData!.latitude!);
            },
            child: const Icon(Icons.location_searching),
          ),
        ],
      ),
      body: Stack(
        children: [
          mapWidget,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Align(
              alignment: Alignment.topCenter,
              child: Row(
                children: [
                  // Align(
                  //   alignment: Alignment.topCenter,
                  //   child: IconButton(
                  //     onPressed: () {},
                  //     icon: const Padding(
                  //       padding: EdgeInsets.only(top: 10),
                  //       child: Icon(
                  //         Icons.menu,
                  //         size: 28,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Expanded(
                    child: FloatingSearchBar(
                      controller: searchController,
                      hint: 'Search...',
                      backgroundColor: Colors.white.withOpacity(0.4),
                      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
                      transitionDuration: const Duration(milliseconds: 800),
                      transitionCurve: Curves.easeInOut,
                      physics: const BouncingScrollPhysics(),
                      axisAlignment: isPortrait ? 0.0 : -1.0,
                      clearQueryOnClose: false,
                      openAxisAlignment: 0.0,
                      width: isPortrait ? double.infinity : 500,
                      debounceDelay: const Duration(milliseconds: 500),
                      autocorrect: true,
                      onQueryChanged: (query) async {
                        //-------------------------------------------
                        searchResults = [];
                        isSearchBarFocused = true;
                        searchResults = await getSearchPlaces(query);
                        setState(() {});
                      },
                      builder: (context, transition) {
                        return
                            // !isSearchBarFocused
                            //     ? Container()
                            //     :
                            Container(
                          constraints: const BoxConstraints(
                            maxHeight: 300,
                          ),
                          child: SingleChildScrollView(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Material(
                                color: Colors.white,
                                elevation: 4.0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: searchResults.map((place) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            searchController.query =
                                                place["place_name"];
                                            searchController.close();

                                            destinationLat = place["geometry"]
                                                ["coordinates"][1];

                                            destinationLong = place["geometry"]
                                                ["coordinates"][0];

                                            destinationName = place["text"];

                                            debugPrint(
                                                place["bbox"].toString());

                                            createSignleMarker(
                                                place["center"][1],
                                                place["center"][0],
                                                place["properties"]
                                                    ["mapbox_id"],
                                                place["bbox"]);

                                            createPolyLine(
                                                place["geometry"]["coordinates"]
                                                    [0],
                                                place["geometry"]["coordinates"]
                                                    [1],
                                                place["bbox"]);
                                            setState(() {
                                              isSearchBarFocused = false;
                                            });
                                          },
                                          child: Container(
                                            height: 40,
                                            width: double.infinity,
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Text(
                                              "${place["place_name"]}",
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Divider(),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Functions

  //On map created
  _onMapCreated(MapboxMap mapboxMap) async {
    await mapboxMap.compass.updateSettings(
      CompassSettings(
          position: OrnamentPosition.TOP_RIGHT,
          marginTop: MediaQuery.of(context).size.height * 0.095),
    );

    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        // puckBearing: PuckBearing.COURSE,
        puckBearingSource: PuckBearingSource.COURSE,
        puckBearingEnabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
        enabled: true,
      ),
    );

    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(
      marginTop: MediaQuery.of(context).size.height * 0.095,
    ));

    customMapboxMap = mapboxMap;
  }

  // //LocationChangedListener
  // void _locationChangedListener() {
  //   location.onLocationChanged.listen((locationData) {
  //     // customMapboxMap?.location.updateSettings(LocationComponentSettings());
  //     // setState(() {});
  //     debugPrint(
  //         "Lat : ${locationData.latitude}, Long: ${locationData.longitude}");

  //     onCameraPositionChanged(locationData);
  //   });
  // }

  Future<void> onCameraPositionChanged(double long, double lat,
      [ScreenCoordinate? anchor, double? zoom]) async {
    CameraOptions cameraOptions = CameraOptions(
      anchor: anchor,
      center: Point(coordinates: Position(long, lat)).toJson(),
      zoom: zoom,
    );

    // await customMapboxMap?.coordinateBoundsForCamera(CameraOptions()).then(
    //     (value) => CoordinateBounds(
    //         southwest: value.southwest,
    //         northeast: value.northeast,
    //         infiniteBounds: value.infiniteBounds));
    await customMapboxMap?.setCamera(cameraOptions);
    await customMapboxMap?.flyTo(cameraOptions, MapAnimationOptions());

    // _onMapCreated(customMapboxMap!);
  }

  void createSignleMarker(
      double lat, double long, String? id, List<dynamic> boundedBox) async {
    // pointAnnotation.geometry
    if (customMapboxMap != null) {
      await customMapboxMap?.annotations
          .createPointAnnotationManager()
          .then((markerAnnotationManager) async {
        if (_pointAnnotationManager != null) {
          _pointAnnotationManager!.deleteAll();
        }

        _pointAnnotationManager = markerAnnotationManager;
        // _pointAnnotationManager.delete(annotation)

        final ByteData bytes = await rootBundle.load('lib/assets/location.png');
        final Uint8List list = bytes.buffer.asUint8List();

        await markerAnnotationManager
            .create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                long,
                lat,
              ),
            ).toJson(),
            iconSize: 0.25,
            image: list,
          ),
        )
            .then((pointAnnotation) async {
          await onCameraPositionChanged(long, lat);
        });
      });
    }
  }

  void createPolyLine(double long, double lat, List<dynamic> boundedBox) async {
    //fetching all the route coordinates

    //created polyline object
    polyLines.MapboxpolylinePoints mapboxPolylinePoints =
        polyLines.MapboxpolylinePoints();

    //fetching coordinates
    polyLines.MapboxPolylineResult result =
        await mapboxPolylinePoints.getRouteBetweenCoordinates(
      APIKEY.accessToken,
      polyLines.PointLatLng(
          latitude: _locationData!.latitude!,
          longitude: _locationData!.longitude!),
      polyLines.PointLatLng(latitude: lat, longitude: long),
      polyLines.TravelType.driving,
    );

    await customMapboxMap?.annotations.createPolylineAnnotationManager().then(
      (polylineAnnotationManager) async {
        if (_polylineAnnotationManager != null) {
          _polylineAnnotationManager?.deleteAll();
        }

        _polylineAnnotationManager = polylineAnnotationManager;

        _polylineAnnotationManager?.setLineCap(LineCap.ROUND);

        // List<Position> positions = result.points.map((point) => Position(point.map((e) => null) .longitude, point.latitude)).toList();
        for (var listOfPointsLatLng in result.points) {
          await _polylineAnnotationManager!
              .create(
            PolylineAnnotationOptions(
              lineJoin: LineJoin.ROUND,
              geometry: LineString(
                bbox: BBox.named(
                    lng1: double.parse(boundedBox[0].toString()),
                    lat1: double.parse(boundedBox[1].toString()),
                    lng2: double.parse(boundedBox[2].toString()),
                    lat2: double.parse(boundedBox[3].toString())),
                coordinates: [
                  ...listOfPointsLatLng.map((e) {
                    return Position(e.longitude, e.latitude);
                  })
                ],
              ).toJson(),
              lineColor: Colors.orange.value,
              lineWidth: 5,
            ),
          )
              .then((polyLinePointAnnotation) async {
            polyLinePointAnnotaion = polyLinePointAnnotation;

            onCameraPositionChanged(
              long,
              lat,
              // ScreenCoordinate(
              //     x: _locationData!.longitude!, y: _locationData!.latitude!),
              // 14
            );
          });
        }
      },
    );
  }

  //Navigation
  void startNavigation() {
    debugPrint(destinationLat.toString());
    debugPrint(destinationLong.toString());
    debugPrint(destinationName.toString());
    debugPrint(originLat.toString());
    debugPrint(originLong.toString());
    debugPrint(originName.toString());
    if (destinationLat != null &&
        destinationLong != null &&
        destinationName != null &&
        originLat != null &&
        originLong != null &&
        originName != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return NavigationView(
              destinationLat: destinationLat!,
              destinationLong: destinationLong!,
              destinationName: destinationName!,
              originLat: originLat!,
              originLong: originLong!,
              originName: originName!,
            );
          },
        ),
      );
    }
  }
}
