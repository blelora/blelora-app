import 'dart:async';
import 'package:blelora_app/src/screens/uart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_nordic_dfu/flutter_nordic_dfu.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/screens/dfu_screen.dart';
import 'package:blelora_app/src/utils/textStyles.dart';

import '../app.dart';
import 'lorawan_screen.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);
  final BluetoothDevice device;

  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late BluetoothService dfuService;
  late BluetoothService uartService;
  late BluetoothService lorawanCredentialService;
  late BluetoothService lorawanControlService;
  late BluetoothCharacteristic uartTxChar;
  late BluetoothCharacteristic uartRxChar;
  late BluetoothCharacteristic controlChar;
  late BluetoothCharacteristic credentialDataChar;
  late BluetoothCharacteristic credentialStatusChar;

  bool foundChars = true;
  bool dfuRunning = false;
  late String? dfuFilePath;
  late int dfuRunningInx;

  StreamController<double> dfuProgressPercentStreamController =
      StreamController<double>.broadcast();

  StreamController<String> dfuProgressStatusStreamController =
      StreamController<String>.broadcast();

  StreamController<bool> charReadStatusStreamController =
      StreamController<bool>.broadcast();

  StreamController<bool> dfuCharStatusStreamController =
      StreamController<bool>.broadcast();
  StreamController<bool> uartCharStatusStreamController =
      StreamController<bool>.broadcast();
  StreamController<bool> lorawanCharStatusStreamController =
      StreamController<bool>.broadcast();

  @override
  void dispose() {
    super.dispose();
    dfuProgressPercentStreamController.close();
    dfuProgressStatusStreamController.close();
    charReadStatusStreamController.close();
  }

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    dfuProgressPercentStreamController.add(0.0);
    dfuProgressStatusStreamController.add("");
    charReadStatusStreamController.add(false);
    dfuCharStatusStreamController.add(false);
    uartCharStatusStreamController.add(false);
    lorawanCharStatusStreamController.add(false);

    widget.device.state.listen((connectionState) {
      if (connectionState == BluetoothDeviceState.connected) {
        widget.device.discoverServices().then((services) {
          // print(services);
          _findDfuChars(services);
          _findUartChars(services);
          _findLorawanChars(services);
          // public key
          charReadStatusStreamController.add(true);
        });
      } else {
        charReadStatusStreamController.add(false);
      }
    });
  }

  Future<void> doDfu(String deviceId) async {
    dfuRunning = true;
    try {
      var s = await FlutterNordicDfu.startDfu(
        deviceId,
        dfuFilePath!,
        fileInAsset: false,
        numberOfPackets: 6,
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
      dfuProgressStatusStreamController.add("Starting DFU");
      dfuRunning = false;
    } catch (e) {
      dfuRunning = false;
      print(e.toString());
    }
  }

  void _findDfuChars(List<BluetoothService> services) {
    try {
      dfuService = services.singleWhere((s) =>
          s.uuid.toString() ==
          "00001530-1212-efde-1523-785feabcd123"); // Nordic DFU Service

      dfuCharStatusStreamController.add(true);
    } catch (e) {
      print("No DFU Service Found");
    }
  }

  void _findUartChars(List<BluetoothService> services) {
    try {
      if (services != null) {
        uartService = services.singleWhere((s) =>
            s.uuid.toString() ==
            "6e400001-b5a3-f393-e0a9-e50e24dcca9e"); // Nordic UART Service
        if (uartService != null) {
          uartRxChar = uartService.characteristics.singleWhere((s) =>
              s.uuid.toString() ==
              "6e400002-b5a3-f393-e0a9-e50e24dcca9e"); // Nordic UART Service
          uartTxChar = uartService.characteristics.singleWhere((s) =>
              s.uuid.toString() ==
              "6e400003-b5a3-f393-e0a9-e50e24dcca9e"); // Nordic UART Service
        }
      }
      uartCharStatusStreamController.add(true);
    } catch (e) {
      print("No UART Service Found");
    }
  }

  void _findLorawanChars(List<BluetoothService> services) {
    try {
      if (services != null) {
        lorawanControlService = services.singleWhere(
            (s) => s.uuid.toString() == "aaa00000-0000-0000-0000-123456789abc");
        lorawanCredentialService = services.singleWhere(
            (s) => s.uuid.toString() == "bbb00000-0000-0000-0000-123456789abc");
        if (lorawanControlService != null) {
          controlChar = lorawanControlService.characteristics.singleWhere((s) =>
              s.uuid.toString() ==
              "aaa10000-0000-0000-0000-123456789abc"); // LoRaWAN Credential Char
        }
        if (lorawanCredentialService != null) {
          credentialDataChar = lorawanCredentialService.characteristics
              .singleWhere((s) =>
                  s.uuid.toString() ==
                  "bbb10000-0000-0000-0000-123456789abc"); // LoRaWAN Credential Char
          credentialStatusChar = lorawanCredentialService.characteristics
              .singleWhere((s) =>
                  s.uuid.toString() ==
                  "bbb20000-0000-0000-0000-123456789abc"); // LoRaWAN Credential Char
        }
      }
      lorawanCharStatusStreamController.add(true);
    } catch (e) {
      print("No LoRaWAN Service Found ");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ParentWidget(existingDevice: widget.device)),
          (Route<dynamic> route) => false,
        );
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: ThemeColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: ThemeColors.appBarBackground,
          title: Text('Device Services', style: ThemeTextStyles.appBarTitle),
          actions: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: widget.device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) {
                VoidCallback? onPressed;
                String text;
                switch (snapshot.data) {
                  case BluetoothDeviceState.connected:
                    onPressed = () => widget.device.disconnect();
                    text = 'DISCONNECT';
                    break;
                  case BluetoothDeviceState.disconnected:
                    onPressed = () => widget.device.connect();
                    text = 'CONNECT';
                    break;
                  default:
                    onPressed = null;
                    text = snapshot.data.toString().substring(21).toUpperCase();
                    break;
                }
                return FlatButton(
                    onPressed: onPressed,
                    child: Text(text, style: ThemeTextStyles.button));
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: widget.device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                  leading: (snapshot.data == BluetoothDeviceState.connected)
                      ? Icon(Icons.bluetooth_connected, color: Colors.blue)
                      : Icon(Icons.bluetooth_disabled),
                  title: (snapshot.data == BluetoothDeviceState.connected)
                      ? Text('Connected to Device Bluetooth',
                          style: ThemeTextStyles.listTitle)
                      : Text('Disconnected from Device Bluetooth',
                          style: ThemeTextStyles.listTitle),
                  trailing: StreamBuilder<bool>(
                      stream: charReadStatusStreamController.stream,
                      initialData: false,
                      builder: (c, snapshot) {
                        if (snapshot.data == false) {
                          return CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          );
                        } else {
                          return Icon(null);
                        }
                      })),
            ),
            ListTile(
              title: Text('Device Firmware Update',
                  style: ThemeTextStyles.listTitle),
              trailing: StreamBuilder<bool>(
                  stream: dfuCharStatusStreamController.stream,
                  initialData: false,
                  builder: (c, snapshot) {
                    if (snapshot.data == true) {
                      return RaisedButton(
                        child: Text('RUN', style: ThemeTextStyles.button),
                        color: ThemeColors.buttonBackground,
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            return DFUScreen(
                              device: widget.device,
                            );
                          }));
                        },
                      );
                    } else {
                      return Icon(null);
                    }
                  }),
            ),
            ListTile(
              title: Text('UART', style: ThemeTextStyles.listTitle),
              trailing: StreamBuilder<bool>(
                  stream: uartCharStatusStreamController.stream,
                  initialData: false,
                  builder: (c, snapshot) {
                    if (snapshot.data == true) {
                      return RaisedButton(
                        child: Text('OPEN', style: ThemeTextStyles.button),
                        color: ThemeColors.buttonBackground,
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            return UartScreen(
                              device: widget.device,
                              uartRxChar: uartRxChar,
                              uartTxChar: uartTxChar,
                            );
                          }));
                        },
                      );
                    } else {
                      return Icon(null);
                    }
                  }),
            ),
            ListTile(
              title: Text('LoRaWAN', style: ThemeTextStyles.listTitle),
              trailing: StreamBuilder<bool>(
                  stream: lorawanCharStatusStreamController.stream,
                  initialData: false,
                  builder: (c, snapshot) {
                    if (snapshot.data == true) {
                      return RaisedButton(
                        child: Text('OPEN', style: ThemeTextStyles.button),
                        color: ThemeColors.buttonBackground,
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            return LorawanScreen(
                              device: widget.device,
                              controlChar: controlChar,
                              credentialDataChar: credentialDataChar,
                              credentialStatusChar: credentialStatusChar,
                            );
                          }));
                        },
                      );
                    } else {
                      return Icon(null);
                    }
                  }),
            ),
          ]),
        ),
      ),
    );
  }
}
