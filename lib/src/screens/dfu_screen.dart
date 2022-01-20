import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_nordic_dfu/flutter_nordic_dfu.dart';
import 'package:blelora_app/src/screens/browse_community_firmware_modules_screen.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/utils/textStyles.dart';

import 'device_screen.dart';

class DFUScreen extends StatefulWidget {
  DFUScreen(
      {Key? key,
      required this.device,
      this.dfuFileName = "",
      this.dfuFilePath = "",
      this.dfuEnable = false})
      : super(key: key);
  final BluetoothDevice device;
  String dfuFileName;
  String dfuFilePath;
  bool dfuEnable;
  _DFUScreenState createState() => _DFUScreenState();
}

class _DFUScreenState extends State<DFUScreen> {
  bool dfuRunning = false;
  late int dfuRunningInx;

  StreamController<double> dfuProgressPercentStreamController =
      StreamController<double>.broadcast();

  StreamController<String> dfuProgressStatusStreamController =
      StreamController<String>.broadcast();

  StreamController<String> dfuFilePathStreamController =
      StreamController<String>.broadcast();

  StreamController<bool> dfuEnableStreamController =
      StreamController<bool>.broadcast();

  @override
  void dispose() {
    super.dispose();
    dfuProgressPercentStreamController.close();
    dfuProgressStatusStreamController.close();
    dfuFilePathStreamController.close();
    dfuEnableStreamController.close();
  }

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    dfuProgressPercentStreamController.add(0.0);
    dfuProgressStatusStreamController.add("");
    dfuFilePathStreamController.add("Select Firmware Above");
  }

  Future<void> doDfu(String deviceId) async {
    dfuRunning = true;
    dfuProgressStatusStreamController.add("Starting DFU, Stay on Screen");
    try {
      var s = await FlutterNordicDfu.startDfu(
        deviceId,
        widget.dfuFilePath,
        fileInAsset: false,
        numberOfPackets: 10,
        enablePRNs: true,
        progressListener:
            DefaultDfuProgressListenerAdapter(onProgressChangedHandle: (
          deviceAddress,
          percent,
          speed,
          avgSpeed,
          currentPart,
          partsTotal,
        ) {
          if (percent > 0 && percent < 100) {
            dfuProgressStatusStreamController.add("$percent %");
          } else if (percent == 100) {
            dfuProgressStatusStreamController.add("DFU Update Complete");
          }
          dfuProgressPercentStreamController.add(percent * 0.01);
          print('deviceAddress: $deviceAddress, percent: $percent');
        }),
      );
      print(s);
      dfuRunning = false;
    } catch (e) {
      dfuRunning = false;
      print(e.toString());
      dfuProgressStatusStreamController.add("No Firmware Zip Selected Yet");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return DeviceScreen(device: widget.device);
        }));
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: ThemeColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: ThemeColors.appBarBackground,
          title: Text('DFU Control', style: ThemeTextStyles.appBarTitle),
          actions: <Widget>[],
        ),
        body: SingleChildScrollView(
          child: Column(children: <Widget>[
            ButtonTheme(
              minWidth: 240.0,
              child: RaisedButton(
                color: ThemeColors.buttonBackground,
                child: Text("Browse Files", style: ThemeTextStyles.button),
                textColor: Colors.white,
                onPressed: () async {
                  await FilePicker.platform.clearTemporaryFiles();
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();
                  if (result != null) {
                    PlatformFile file = result.files.first;

                    print(file.name);
                    print(file.bytes);
                    print(file.size);
                    print(file.extension);
                    print(file.path);

                    RegExp exp = RegExp(r".*/(?<filename>.*?)\.zip");
                    var matches = exp.allMatches(file.path!);
                    var firmwareName = matches.elementAt(0).group(1);

                    widget.dfuFileName = "${firmwareName}.zip";
                    widget.dfuFilePath = file.path!;
                    dfuFilePathStreamController.add(file.path!);
                    dfuEnableStreamController.add(true);
                  } else {
                    // User canceled the picker
                  }
                },
              ),
            ),
            ButtonTheme(
              minWidth: 240.0,
              child: RaisedButton(
                color: ThemeColors.buttonBackground,
                child: Text('Browse Community Firmware',
                    style: ThemeTextStyles.button),
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return BrowseCommunityFirmwareModulesScreen(
                      device: widget.device,
                    );
                  }));
                },
              ),
            ),
            StreamBuilder<String>(
                stream: dfuFilePathStreamController.stream,
                initialData: "Select Firmware Above",
                builder: (c, snapshot) {
                  if (snapshot.data != null) {
                    if (widget.dfuFilePath != "" &&
                        widget.dfuFilePath != null) {
                      RegExp exp = RegExp(r".*/(?<filename>.*?)\.zip");
                      var matches = exp.allMatches(widget.dfuFilePath);
                      var firmwareName = matches.elementAt(0).group(1);

                      return ListTile(
                          title: new Center(
                              child: Text(
                                  "Selected Firmware: ${firmwareName}.zip",
                                  style: ThemeTextStyles.listTitle)));
                    }

                    return ListTile(
                        title: new Center(
                            child: Text("No Firmware Selected",
                                style: ThemeTextStyles.listTitle)));
                  } else
                    return ListTile(
                        title: new Center(
                            child: Text("No Firmware Selected",
                                style: ThemeTextStyles.listTitle)));
                }),
            StreamBuilder<bool>(
                stream: dfuEnableStreamController.stream,
                initialData: widget.dfuEnable,
                builder: (c, snapshot) {
                  if (snapshot.data == true) {
                    return Column(children: <Widget>[
                      ButtonTheme(
                        minWidth: 240.0,
                        child: RaisedButton(
                          color: ThemeColors.buttonBackground,
                          child: Text('Start Device Firmware Update',
                              style: ThemeTextStyles.button),
                          textColor: Colors.white,
                          onPressed: () async {
                            await doDfu(widget.device.id.id);
                          },
                        ),
                      ),
                      StreamBuilder<String>(
                          stream: dfuProgressStatusStreamController.stream,
                          initialData: '',
                          builder: (c, snapshot) {
                            return Text(snapshot.data!,
                                style: ThemeTextStyles.listTitle);
                          }),
                      StreamBuilder<double>(
                          stream: dfuProgressPercentStreamController.stream,
                          initialData: 0.0,
                          builder: (c, snapshot) {
                            print(snapshot.data);
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                LinearProgressIndicator(
                                  color: ThemeColors.progressBar,
                                  backgroundColor: ThemeColors.progressBarBackground,
                                  value: snapshot.data,
                                  semanticsLabel: 'Linear progress indicator',
                                  minHeight: 13,
                                ),
                              ],
                            );
                          })
                    ]);
                  } else {
                    return Text("");
                  }
                }),
          ]),
        ),
      ),
    );
  }
}
