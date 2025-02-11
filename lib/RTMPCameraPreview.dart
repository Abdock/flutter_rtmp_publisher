import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'RTMPCamera.dart';

class RTMPCameraPreview extends StatefulWidget {
  final RTMPCamera? controller;
  final PlatformViewCreatedCallback? createdCallback;

  const RTMPCameraPreview({Key? key, this.controller, this.createdCallback})
      : super(key: key);

  @override
  State<RTMPCameraPreview> createState() => _RTMPCameraPreviewState();
}

class _RTMPCameraPreviewState extends State<RTMPCameraPreview> {
  Future<Widget> waitWidget() async {
    // Так как проверка на null уже выполняется в build, используем !
    int id = await widget.controller!.getId();
    print("Build preview on camera id $id.");
    return AndroidView(
      viewType: 'flutter_rtmp_publisher/RTMPCameraPreview',
      creationParams: id,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  FutureBuilder<Widget> buildFutureBuilder() {
    return FutureBuilder<Widget>(
      future: waitWidget(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active) {
          return const CircularProgressIndicator();
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Text("Error: Controller id error.");
          } else if (snapshot.hasData) {
            return snapshot.data!;
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return Text(
          "$defaultTargetPlatform is not yet supported by the plugin");
    } else {
      if (widget.controller == null) {
        return const Text("Controller not set.");
      } else {
        return buildFutureBuilder();
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.unsetView();
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    print("Preview created $id");
    if (widget.createdCallback != null) {
      widget.createdCallback!(id);
    }
  }
}
