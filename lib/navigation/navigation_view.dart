import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

class NavigationView extends StatefulWidget {
  String originName;
  String destinationName;
  double originLat;
  double originLong;
  double destinationLat;
  double destinationLong;

  NavigationView(
      {super.key,
      required this.originName,
      required this.destinationName,
      required this.originLat,
      required this.originLong,
      required this.destinationLat,
      required this.destinationLong});

  @override
  State<NavigationView> createState() => _NavigationViewState();
}

class _NavigationViewState extends State<NavigationView> {
  MapBoxNavigationViewController? _controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);

    Future.delayed(Duration.zero).then((value) async {
      WayPoint origin = WayPoint(
          name: widget.originName,
          latitude: widget.originLat,
          longitude: widget.originLong);
      WayPoint destination = WayPoint(
          name: widget.destinationName,
          latitude: widget.destinationLat,
          longitude: widget.destinationLong);

      List<WayPoint> wayPoints = [];
      wayPoints.add(origin);
      wayPoints.add(destination);

      await MapBoxNavigation.instance.startNavigation(wayPoints: wayPoints);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MapBoxNavigationView(
            options: MapBoxOptions(
              initialLatitude: widget.originLat,
              initialLongitude: widget.originLong,
              zoom: 16.0,
              tilt: 0.0,
              bearing: 0.0,
              enableRefresh: false,
              alternatives: true,
              voiceInstructionsEnabled: true,
              bannerInstructionsEnabled: true,
              allowsUTurnAtWayPoints: true,
              mode: MapBoxNavigationMode.drivingWithTraffic,
              units: VoiceUnits.imperial,
              simulateRoute: true,
              language: "en",
            ),
            // onRouteEvent: _onRouteEvent,
            onCreated: (MapBoxNavigationViewController controller) async {
              _controller = controller;
            }),
      ),
    );
  }

  Future<void> _onRouteEvent(e) async {
    //  cityhall =
    //     WayPoint(name: "City Hall", latitude: 42.886448, longitude: -78.878372);
    //  downtown = WayPoint(
    //     name: "Downtown Buffalo", latitude: 42.8866177, longitude: -78.8814924);

    // var wayPoints = [] as List<WayPoint>;
    // wayPoints.add(cityhall);
    // wayPoints.add(downtown);

    // await MapBoxNavigation.instance.startNavigation(wayPoints: wayPoints);

    // _distanceRemaining = await _directions.distanceRemaining;
    // _durationRemaining = await _directions.durationRemaining;

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        // _arrived = progressEvent.arrived;
        if (progressEvent.currentStepInstruction != null)
          // _instruction = progressEvent.currentStepInstruction;
          break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        // _routeBuilt = true;
        break;
      case MapBoxEvent.route_build_failed:
        // _routeBuilt = false;
        break;
      case MapBoxEvent.navigation_running:
        // _isNavigating = true;
        break;
      case MapBoxEvent.on_arrival:
        await _controller?.finishNavigation();
        // _arrived = true;
        // if (!_isMultipleStop) {
        //   await Future.delayed(Duration(seconds: 3));
        //   await _controller.finishNavigation();
        // } else {}
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        // _routeBuilt = false;
        // _isNavigating = false;
        break;
      default:
        break;
    }
    //refresh UI
    setState(() {});
  }
}
