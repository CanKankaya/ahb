import 'package:flutter/material.dart';

import 'package:camera/camera.dart';

import 'package:ahb/screens/camera_denied_screen.dart';
import 'package:ahb/screens/camera_screen.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  final firstCamera = cameras.first;
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MyApp(firstCamera: firstCamera),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.firstCamera,
  }) : super(key: key);

  final CameraDescription? firstCamera;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        splashColor: Colors.black,
        primaryColor: Colors.black,
        hintColor: Colors.amber,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => CameraScreen(
              camera: firstCamera!,
            ),
        '/camera': (context) => CameraScreen(
              camera: firstCamera!,
            ),
        '/camera_denied': (context) => const CameraDeniedScreen(),
      },
    );
  }
}
