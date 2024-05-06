import 'dart:async';
import 'package:flutter/material.dart';

import 'package:connectivity/connectivity.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ahb/utils/object_detection.dart';

import 'package:ahb/widgets/api_container.dart';
import 'package:ahb/widgets/custom_clipper.dart';
import 'package:ahb/widgets/custom_error_message.dart';
import 'package:ahb/widgets/simpler_custom_loading.dart';

import 'package:ahb/constants/device_sizes.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);
  final CameraDescription camera;
  static const String routeName = '/camera';

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  var _isLoading = false;
  var _flashMode = FlashMode.off;
  var _isOnline = false;
  var topPadding = 24.0;
  var compressed = true;

  ObjectDetection? objectDetection;
  List<int> apiResult = [];

  // var compressTimeDiff = const Duration();
  // var apiTimeDiff = const Duration();
  // var timeDiff = const Duration();
  var backgroundTime = DateTime.now();
  @override
  void dispose() {
    _controller?.dispose();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      backgroundTime = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (DateTime.now().difference(backgroundTime) > const Duration(seconds: 50)) {
        _checkCameraPermission();
      }
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      size = MediaQuery.of(context).size;
      viewPadding = MediaQuery.of(context).viewPadding;
      topPadding = MediaQuery.of(context).viewPadding.top == 0
          ? 24.0
          : MediaQuery.of(context).viewPadding.top;
    });
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.camera.request();
    }
    if (status.isDenied || status.isPermanentlyDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/camera_denied');
      });
    } else {
      objectDetection = ObjectDetection();
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _initializeControllerFuture = _controller?.initialize().then(
        (_) {
          _controller?.setFocusMode(FocusMode.auto);
          _controller?.lockCaptureOrientation(DeviceOrientation.portraitUp);
          _controller?.setFlashMode(FlashMode.off);
          setState(() {});
        },
      );

      _connectivitySubscription =
          Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        setState(() {
          _isOnline = result != ConnectivityResult.none;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 23, 23, 23),
      body: Column(
        children: [
          Container(
            height: topPadding,
            width: double.infinity,
            color: const Color.fromARGB(255, 23, 23, 23),
          ),
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      SizedBox(
                        child: CameraPreview(_controller!),
                      ),
                      const OverlayWithRectangleClipping(),
                      ApiContainer(result: apiResult),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildApiButton(),
                      ),
                      // Align(
                      //   alignment: Alignment.bottomRight,
                      //   child: _buildCompressButton(),
                      // ),
                      // _buildApiTimer(),
                      Positioned(
                        right: 0,
                        child: _buildFlashButton(),
                      ),
                      if (!_isOnline)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: _buildErrorBar(),
                        ),
                    ],
                  );
                } else {
                  return const SimplerCustomLoader();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Container _buildErrorBar() {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.all(12.0),
      child: const Text(
        'İnternet bağlantınızı kontrol edin.',
        style: TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Padding _buildApiButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: IconButton(
        color: const Color.fromARGB(215, 255, 193, 7),
        iconSize: 60,
        onPressed: _isLoading || !_isOnline
            ? null
            : () async {
                setState(() {
                  _isLoading = true;
                });

                await _initializeControllerFuture;

                if (_controller == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    customErrorMessage(
                      context,
                      'Kamera açılırken bir hata oluştu. Lütfen tekrar deneyin.',
                      '',
                      null,
                      false,
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  });
                  return;
                }

                final image = await _controller?.takePicture();

                if (image == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    customErrorMessage(
                      context,
                      'Fotoğraf çekilirken bir hata oluştu. Lütfen tekrar deneyin.',
                      '',
                      null,
                      false,
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  });
                  return;
                }
                if (objectDetection == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    customErrorMessage(
                      context,
                      'Object Detection modeli yüklenirken bir hata oluştu. Lütfen tekrar deneyin.',
                      '',
                      null,
                      false,
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  });
                  return;
                }

                var tempResult = await objectDetection?.runInferenceOnAPI(
                    imagePath: image.path, compressed: compressed);

                // compressTimeDiff = tempResult?['compressTimeDiff'] ?? const Duration();
                // apiTimeDiff = tempResult?['apiTimeDiff'] ?? const Duration();
                // timeDiff = compressTimeDiff + apiTimeDiff;

                if (tempResult == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    customErrorMessage(
                      context,
                      'Server\'a bağlanırken bir hata oluştu. Lütfen tekrar deneyin.',
                      '',
                      null,
                      false,
                    );

                    setState(() {
                      _isLoading = false;
                    });
                  });

                  return;
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    apiResult = tempResult["prediction"];
                    _isLoading = false;
                  });
                });
              },
        icon: _isLoading
            ? const SimplerCustomLoader()
            : const Icon(
                Icons.camera,
              ),
      ),
    );
  }

  Padding _buildFlashButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(),
      child: IconButton(
        iconSize: 30,
        onPressed: () async {
          if (_flashMode == FlashMode.off) {
            await _controller?.setFlashMode(FlashMode.torch);
            setState(() {
              _flashMode = FlashMode.torch;
            });
          } else {
            await _controller?.setFlashMode(FlashMode.off);
            setState(() {
              _flashMode = FlashMode.off;
            });
          }
        },
        icon: Icon(
          _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
          color: _flashMode == FlashMode.off ? Colors.white54 : Colors.amber,
        ),
      ),
    );
  }

  // Container _buildApiTimer() {
  //   return Container(
  //     margin: const EdgeInsets.all(4),
  //     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
  //     child: Column(
  //       children: [
  //         Row(
  //           children: [
  //             const Text(
  //               'Compress Time: ',
  //               style: TextStyle(
  //                 color: Color.fromARGB(255, 200, 200, 200),
  //                 fontSize: 14,
  //               ),
  //             ),
  //             Text(
  //               '${compressTimeDiff.inMilliseconds} ms',
  //               style: const TextStyle(
  //                 color: Color.fromARGB(255, 200, 200, 200),
  //                 fontSize: 16,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Row(
  //           children: [
  //             const Text(
  //               'API Time: ',
  //               style: TextStyle(
  //                 color: Color.fromARGB(255, 200, 200, 200),
  //                 fontSize: 14,
  //               ),
  //             ),
  //             Text(
  //               '${apiTimeDiff.inMilliseconds} ms',
  //               style: const TextStyle(
  //                 color: Color.fromARGB(255, 200, 200, 200),
  //                 fontSize: 16,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Row(
  //           children: [
  //             const Text(
  //               'Total Time: ',
  //               style: TextStyle(
  //                 color: Color.fromARGB(255, 200, 200, 200),
  //                 fontSize: 14,
  //               ),
  //             ),
  //             Text(
  //               '${timeDiff.inMilliseconds} ms',
  //               style: const TextStyle(
  //                 color: Color.fromARGB(255, 200, 200, 200),
  //                 fontSize: 16,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

// Widget _buildCompressButton() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(),
  //     child: IconButton(
  //       iconSize: 30,
  //       onPressed: () async {
  //         setState(() {
  //           compressed = !compressed;
  //         });
  //       },
  //       icon: Icon(
  //         compressed ? Icons.compress : Icons.compress_outlined,
  //         color: compressed ? Colors.amber : Colors.white54,
  //       ),
  //     ),
  //   );
  // }
}
