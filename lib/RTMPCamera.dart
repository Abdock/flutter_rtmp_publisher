import 'dart:async';
import 'package:flutter/services.dart';

const MethodChannel _channel =
MethodChannel('flutter_rtmp_publisher/method');

class CameraSize {
  final int width;
  final int height;
  CameraSize(this.width, this.height);
}

typedef CameraSizeCallback = void Function(CameraSize size);

class RTMPCamera {
  final Future<dynamic> _id = _channel.invokeMethod("NewRTMPCamera");
  late final MethodChannel _methodChannel;

  RTMPCamera() {
    _id.then((id) {
      print("Init RTMPCamera id: $id");
      _methodChannel =
          MethodChannel('flutter_rtmp_publisher/method/RTMPCamera_$id');
    });
  }

  Future<void> unsetView() async {
    await _methodChannel.invokeMethod("unsetView");
  }

  Future<void> dispose() async {
    await _methodChannel.invokeMethod("dispose");
  }

  Future<dynamic> getId() async {
    return _id;
  }

  Future<List<CameraSize>> getResolutions() async {
    final List<dynamic> res =
    await _methodChannel.invokeMethod("getResolutions");
    return List.generate(res.length, (index) {
      final item = res[index];
      return CameraSize(item["width"], item["height"]);
    });
  }

  Future<bool> prepareVideo({
    int width = 640,
    int height = 480,
    int fps = 30,
    int bitrate = 2500 * 1024,
    bool hardwareRotation = false,
    int rotation = 90,
  }) async {
    return await _methodChannel.invokeMethod("prepareVideo", {
      "width": width,
      "height": height,
      "fps": fps,
      "bitrate": bitrate,
      "hardwareRotation": hardwareRotation,
      "rotation": rotation,
    });
  }

  Future<bool> prepareAudio({
    int bitrate = 128,
    int sampleRate = 44100,
    bool isStereo = true,
    bool echoCanceler = false,
    bool noiseSuppressor = false,
  }) async {
    return await _methodChannel.invokeMethod("prepareAudio", {
      "bitrate": bitrate,
      "sampleRate": sampleRate,
      "isStereo": isStereo,
      "echoCanceler": echoCanceler,
      "noiseSuppressor": noiseSuppressor,
    });
  }

  Future<void> startPreview() async {
    if (!(await onPreview())) {
      await _methodChannel.invokeMethod("startPreview");
    } else {
      print("Ignore startPreview.");
    }
  }

  Future<void> stopPreview() async {
    if (await onPreview()) {
      await _methodChannel.invokeMethod("stopPreview");
    } else {
      print("Ignore stopPreview.");
    }
  }

  Future<void> startStream(String url) async {
    if (!(await isStreaming())) {
      await _methodChannel.invokeMethod("startStream", url);
    } else {
      print("Ignore startStream.");
    }
  }

  Future<void> stopStream() async {
    if (await isStreaming()) {
      await _methodChannel.invokeMethod("stopStream");
    } else {
      print("Ignore stopStream.");
    }
  }

  Future<void> switchCamera() async {
    await _methodChannel.invokeMethod("switchCamera");
  }

  Future<bool> isStreaming() async {
    return await _methodChannel.invokeMethod("isStreaming");
  }

  Future<bool> onPreview() async {
    return await _methodChannel.invokeMethod("isOnPreview");
  }
}
