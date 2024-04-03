import 'package:flutter/material.dart';
import 'package:map_box_app/map_screen/map_view.dart';
import 'package:map_box_app/utils/api_key.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // MapboxOptions.setAccessToken(APIKEY.accessToken);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: SafeArea(child: MapView()),
    );
  }
}
