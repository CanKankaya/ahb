//* Dart and Flutter packages
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

//* Dart and Flutter packages
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:http_parser/http_parser.dart';

//* Custom packages
import 'package:ahb/constants/device_sizes.dart';
import 'package:ahb/constants/api.dart';

class ObjectDetection {
  Future<Map<String, dynamic>?> runInferenceOnAPI(
      {required String imagePath, bool compressed = false}) async {
    log('Running inference on API...');
    //timer
    // var startTime = DateTime.now();

    var image = File(imagePath);
    img.Image? croppedImage;

    // var timer = DateTime.now();
    if (compressed) {
      var cropimage = img.decodeImage(image.readAsBytesSync())!;
      log(viewPadding?.top.toString() ?? 'null');

      croppedImage = img.copyCrop(
        cropimage,
        x: cropimage.width ~/ 5,
        y: (cropimage.height * 0.20).toInt(),
        width: (cropimage.width * 0.6).toInt(),
        height: (cropimage.height * 0.12).toInt(),
      );
    }
    // log('Time taken to process cropping: ${DateTime.now().difference(timer).inMilliseconds} ms');

    //timer
    // var endTime = DateTime.now();
    // var compressTimeDiff = endTime.difference(startTime);
    // log('Time taken to compress and resize image: ${compressTimeDiff.inMilliseconds} ms');
    // startTime = DateTime.now();

    http.MultipartRequest request;

    // if (!compressed) {
    //   request = http.MultipartRequest('POST', Uri.parse("$baseApiUrl/predict/"))
    //     ..files.add(await http.MultipartFile.fromPath(
    //       'file',
    //       image.path,
    //       contentType: MediaType('image', 'jpeg'),
    //     ));
    // } else {
    request = http.MultipartRequest('POST', Uri.parse("$baseApiUrl/predict/"))
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        img.encodeJpg(croppedImage!),
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    // }

    //request to send the cropped image

    var response = await request.send();

    //timer
    // endTime = DateTime.now();
    // var apiTimeDiff = endTime.difference(startTime);
    // log('Time taken to send request: ${apiTimeDiff.inMilliseconds} ms');

    if (response.statusCode == 200) {
      log('Response: 200');
      var responseData = await response.stream.toBytes();

      var responseString = String.fromCharCodes(responseData);
      log(responseString);
      var jsonResponse = jsonDecode(responseString);
      if (jsonResponse is Map<String, dynamic> && jsonResponse['prediction'] is List) {
        return {
          'prediction': List<int>.from(
            jsonResponse['prediction'].map((x) => x as int),
          ),
          'apiTimeDiff': 0,
          'compressTimeDiff': 0,
        };
      } else {
        return null;
      }
    } else {
      log('Error: ${response.statusCode}');
      return null;
    }
  }
}
