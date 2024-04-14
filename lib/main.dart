import 'dart:html';
import 'dart:ui' as ui;
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey _containerKey = GlobalKey();

  late final List<DeviceInfo> allDevices;
  late DeviceInfo currentDevice;

  var align = Alignment.bottomCenter;
  @override
  void initState() {
    allDevices = Devices.all;
    currentDevice = allDevices.first;
    super.initState();
  }

  int selectedIndex = 0;
  Uint8List? image;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Row(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(children: [
                    ...allDevices
                        .asMap()
                        .map((ind, e) => MapEntry(
                            ind,
                            InkWell(
                              onTap: () {
                                selectedIndex = ind;
                                currentDevice = allDevices[ind];
                                setState(() {});
                              },
                              child: Container(
                                // height: size.height / 1.5,
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: selectedIndex == ind
                                          ? Colors.blue
                                          : Colors.black,
                                      width: 3),
                                  color: Colors.white,
                                ),
                                child: DeviceFrame(
                                    device: e,
                                    screen: Container(
                                      color: Colors.white,
                                    )),
                              ),
                            )))
                        .values
                        .toList(),
                  ]),
                ),
              ),
              Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: RepaintBoundary(
                            key: _containerKey,
                            child: DeviceFrame(
                                device: currentDevice,
                                screen: Container(
                                  color: Colors.white,
                                  child: image != null
                                      ? InkWell(
                                          onTap: () async {
                                            ImagePicker imagePicker =
                                                ImagePicker();
                                            final selected =
                                                await imagePicker.pickImage(
                                                    source:
                                                        ImageSource.gallery);
                                            if (selected != null) {
                                              final byte =
                                                  await selected.readAsBytes();
                                              setState(() {
                                                image = byte;
                                              });
                                            }
                                          },
                                          child: Image.memory(
                                            image!,
                                            fit: BoxFit.fitWidth,
                                            alignment: align,
                                          ))
                                      : Center(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              ImagePicker imagePicker =
                                                  ImagePicker();
                                              final selected =
                                                  await imagePicker.pickImage(
                                                      source:
                                                          ImageSource.gallery);
                                              if (selected != null) {
                                                final byte = await selected
                                                    .readAsBytes();
                                                setState(() {
                                                  image = byte;
                                                });
                                              }
                                            },
                                            child: const Text('Add image'),
                                          ),
                                        ),
                                )),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
  ElevatedButton(
                          onPressed: () async {
                            captureAndSaveScreenshot();
                          },
                          child: const Text('Download')),
                              SizedBox(
                        height: 10,
                      ),

                      ElevatedButton(
                          onPressed: () async {
                            if (align == Alignment.bottomCenter) {
                              align = Alignment.topCenter;
                            } else {
                              align = Alignment.bottomCenter;
                            }
                            setState(() {});
                          },
                          child:  Text('Align ${align.toString()}'))
                      ],),
                      
                      // ElevatedButton(
                      //     onPressed: () async {
                      //       if (align == Alignment.bottomCenter) {
                      //         align = Alignment.topCenter;
                      //       } else {
                      //         align = Alignment.bottomCenter;
                      //       }
                      //       setState(() {});
                      //     },
                      //     child:  Text('Rotate ${align.toString()}'))
                      // ],)
                    
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> captureScreenshot() async {
    try {
      RenderRepaintBoundary boundary = _containerKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        return pngBytes;
      }
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<void> saveScreenshot(Uint8List screenshotBytes) async {
    download(screenshotBytes, DateTime.now().microsecondsSinceEpoch.toString());
  }

  Future<void> captureAndSaveScreenshot() async {
    Uint8List? screenshotBytes = await captureScreenshot();
    if (screenshotBytes != null) {
      await saveScreenshot(screenshotBytes);
    }
  }

  download(Uint8List imageBytes, String name) async {
    // Create a Blob from the Uint8List data
    final String fileName = '${name}_generated.png'; // Custom file name

    final blob = Blob([imageBytes]);
    final anchorElement = AnchorElement()
      ..href = Url.createObjectUrl(blob)
      ..download =
          fileName; // Set the download attribute with the custom file name

    anchorElement.click();
    Url.revokeObjectUrl(anchorElement.href!);
  }
}
