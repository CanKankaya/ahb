//* Dart and Flutter packages
import 'package:flutter/material.dart';

//* Custom packages
import 'package:permission_handler/permission_handler.dart';

class CameraDeniedScreen extends StatefulWidget {
  const CameraDeniedScreen({super.key});

  static const String routeName = '/camera_denied';

  @override
  CameraDeniedScreenState createState() => CameraDeniedScreenState();
}

class CameraDeniedScreenState extends State<CameraDeniedScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      var status = await Permission.camera.status;
      if (status.isGranted) {
        WidgetsBinding.instance.removeObserver(this);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/camera');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 23, 23, 23),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 45, 45, 45),
        title: const Text('Kamera Engellendi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Kamera erişimi reddedildi.',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              onPressed: () async {
                var status = await Permission.camera.status;
                if (status.isPermanentlyDenied) {
                  await openAppSettings();
                } else {
                  status = await Permission.camera.request();
                }
              },
              child: const Text(
                'Erişim Ver',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            )
          ],
        ),
      ),
    );
  }
}
