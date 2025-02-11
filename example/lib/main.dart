import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rtmp_publisher/flutter_rtmp_publisher.dart';
import 'language.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final RTMPCamera cameraController = RTMPCamera();
  final StreamController<List<CameraSize>> streamController =
  StreamController<List<CameraSize>>();

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('RTMP Publisher'),
        ),
        body: ListView(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 3 / 4,
              child: RTMPCameraPreview(
                controller: cameraController,
                createdCallback: (int id) {
                  cameraController.getResolutions().then((resolutionList) {
                    streamController.add(resolutionList);
                  });
                },
              ),
            ),
            Container(
              // height: 200,
              child: MyAppState(
                cameraController: cameraController,
                resolutionStream: streamController.stream,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyAppState extends StatefulWidget {
  final RTMPCamera cameraController;
  final Stream<List<CameraSize>> resolutionStream;
  const MyAppState({
    Key? key,
    required this.cameraController,
    required this.resolutionStream,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyAppState> {
  final TextEditingController textController = TextEditingController(
      text: "rtmp://10.240.169.163:19356/myapp/mystream");

  final TextEditingController videoBitrateController =
  TextEditingController(text: "2560000");
  final TextEditingController fpsController =
  TextEditingController(text: "30");
  final TextEditingController audioBitrateController =
  TextEditingController(text: "128");
  final TextEditingController sampleRateController =
  TextEditingController(text: "44100");
  final TextEditingController usernameController =
  TextEditingController(text: "");
  final TextEditingController passwordController =
  TextEditingController(text: "");

  bool hardwareController = false;
  bool echoCancelerController = false;
  bool noiseSuppressorController = false;

  // Предполагается, что language – это глобальный список из language.dart
  Language lang = language[0].useThis();
  CameraSize? size;

  bool onPreview = false;
  bool isStreaming = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          TextField(
            controller: textController,
            decoration: InputDecoration(
              labelText: lang.address,
            ),
          ),
          languageChooser(),
          buttonArea(),
          settingArea(),
        ],
      ),
    );
  }

  void makeToast({required String text, String? action, VoidCallback? callback}) {
    // Используем ScaffoldMessenger вместо Scaffold.of(context)
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        action: action != null
            ? SnackBarAction(
          label: action,
          onPressed: callback ?? () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        )
            : null,
      ),
    );
  }

  Widget languageChooser() {
    return Container(
      child: Wrap(
        children: List.generate(
          language.length,
              (index) {
            return Checker(
              text: language[index].language,
              value: language[index].use,
              callbackFunc: (bool value) {
                setState(() {
                  for (var l in language) {
                    l.use = false;
                  }
                  lang = language[index].useThis();
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget makeTextField(String label, TextEditingController controller) {
    return Container(
      width: 150,
      child: TextField(
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
        ),
        controller: controller,
      ),
    );
  }

  Widget settingArea() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            lang.video,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ResolutionChooser(
            stream: widget.resolutionStream,
            lang: lang,
            callbackFunc: (CameraSize size) {
              this.size = size;
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              makeTextField(lang.videoBitrate, videoBitrateController),
              makeTextField(lang.audioBitrate, audioBitrateController),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              makeTextField(lang.fps, fpsController),
              Checker(
                text: lang.hardwareRotation,
                value: hardwareController,
                callbackFunc: (bool value) {
                  setState(() {
                    hardwareController = value;
                  });
                },
              ),
            ],
          ),
          Text(
            lang.audio,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              makeTextField(lang.audioBitrate, audioBitrateController),
              makeTextField(lang.sampleRate, sampleRateController),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Checker(
                text: lang.noiseSuppressor,
                value: noiseSuppressorController,
                callbackFunc: (bool value) {
                  setState(() {
                    noiseSuppressorController = value;
                  });
                },
              ),
              Checker(
                text: lang.echoCanceler,
                value: echoCancelerController,
                callbackFunc: (bool value) {
                  setState(() {
                    echoCancelerController = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buttonArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      alignment: Alignment.center,
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: <Widget>[
          previewButton(),
          streamButton(),
          makeButton(
            icon: Icons.switch_camera,
            text: lang.switchCamera,
            func: () {
              widget.cameraController.switchCamera();
            },
          ),
        ],
      ),
    );
  }

  Future<bool> prepareEncode() async {
    return await widget.cameraController.prepareAudio(
      bitrate: int.parse(audioBitrateController.text),
      sampleRate: int.parse(sampleRateController.text),
      echoCanceler: echoCancelerController,
      noiseSuppressor: noiseSuppressorController,
    ) &&
        await widget.cameraController.prepareVideo(
          width: size!.width,
          height: size!.height,
          fps: int.parse(fpsController.text),
          bitrate: int.parse(videoBitrateController.text),
          hardwareRotation: hardwareController,
        );
  }

  Widget makeButton({
    required IconData icon,
    required String text,
    required VoidCallback func,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      constraints: const BoxConstraints(maxWidth: 170),
      height: 50,
      child: ElevatedButton(
        onPressed: func,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget previewButton() {
    if (!onPreview) {
      return makeButton(
        icon: Icons.play_circle_filled,
        text: lang.startPreview,
        func: () async {
          if (size == null) {
            makeToast(text: lang.errorResolutionFirst, action: lang.gotIt);
          } else {
            if (await prepareEncode()) {
              await widget.cameraController.startPreview();
              widget.cameraController.onPreview().then((preview) {
                setState(() {
                  onPreview = preview;
                });
              });
            } else {
              makeToast(text: "Error");
            }
          }
        },
      );
    } else {
      return makeButton(
        icon: Icons.pause_circle_filled,
        text: lang.stopPreview,
        func: () async {
          await widget.cameraController.stopPreview();
          widget.cameraController.onPreview().then((preview) {
            setState(() {
              onPreview = preview;
            });
          });
        },
      );
    }
  }

  Widget streamButton() {
    if (!isStreaming) {
      return makeButton(
        icon: Icons.play_circle_filled,
        text: lang.startStream,
        func: () async {
          if (await widget.cameraController.onPreview() == false ||
              await prepareEncode()) {
            await widget.cameraController.startStream(textController.text);
            widget.cameraController.isStreaming().then((streaming) {
              setState(() {
                isStreaming = streaming;
              });
            });
          } else {
            makeToast(text: "Error!");
          }
        },
      );
    } else {
      return makeButton(
        icon: Icons.pause_circle_filled,
        text: lang.stopStream,
        func: () async {
          await widget.cameraController.stopStream();
          widget.cameraController.isStreaming().then((streaming) {
            setState(() {
              isStreaming = streaming;
            });
          });
        },
      );
    }
  }
}

/* Dropdown */

class ResolutionChooser extends StatefulWidget {
  final Stream<List<CameraSize>> stream;
  final Language lang;
  final CameraSizeCallback callbackFunc;

  const ResolutionChooser({
    Key? key,
    required this.stream,
    required this.lang,
    required this.callbackFunc,
  }) : super(key: key);

  @override
  _ResolutionChooserState createState() => _ResolutionChooserState();
}

class _ResolutionChooserState extends State<ResolutionChooser> {
  List<CameraSize>? resolutionList;
  CameraSize? size;
  int? selected;
  StreamSubscription<List<CameraSize>>? listener;

  @override
  void initState() {
    super.initState();
    listener = widget.stream.listen((rl) {
      setState(() {
        resolutionList = rl;
        if (rl.isNotEmpty) {
          selected = 0;
          widget.callbackFunc(rl[0]);
        }
      });
    });
  }

  @override
  void dispose() {
    listener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return resolutionList == null
        ? Text(widget.lang.resolutionIsLoding)
        : DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        items: List.generate(resolutionList!.length, (index) {
          CameraSize resolution = resolutionList![index];
          return DropdownMenuItem<int>(
            value: index,
            child: Text("${resolution.width}×${resolution.height}"),
          );
        }),
        hint: Text(widget.lang.resolutionFirst),
        value: selected,
        onChanged: (int? i) {
          if (i != null) {
            widget.callbackFunc(resolutionList![i]);
          }
          setState(() {
            selected = i;
          });
        },
      ),
    );
  }
}

class Checker extends StatefulWidget {
  final bool value;
  final String text;
  final ValueChanged<bool> callbackFunc;
  const Checker({
    Key? key,
    required this.callbackFunc,
    required this.text,
    required this.value,
  }) : super(key: key);

  @override
  _CheckerState createState() => _CheckerState(initialValue: value);
}

class _CheckerState extends State<Checker> {
  bool initialValue;
  _CheckerState({required this.initialValue});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Checkbox(
          value: widget.value,
          onChanged: (bool? newValue) {
            if (newValue != null) {
              widget.callbackFunc(newValue);
            }
          },
        ),
        Text(widget.text),
      ],
    );
  }
}
