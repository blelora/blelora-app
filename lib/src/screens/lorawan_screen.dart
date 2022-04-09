import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/utils/textStyles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:convert/convert.dart';

class LorawanScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic controlChar;
  final BluetoothCharacteristic credentialDataChar;
  final BluetoothCharacteristic credentialStatusChar;
  final BluetoothCharacteristic settingsDataChar;
  final BluetoothCharacteristic settingsStatusChar;
  final devEuiTextController = TextEditingController();
  final appEuiTextController = TextEditingController();
  final appKeyTextController = TextEditingController();
  final transmitRepeatTextController = TextEditingController();
  final joinTrialsTextController = TextEditingController();
  final txPowerTextController = TextEditingController();
  final dataRateTextController = TextEditingController();
  final subbandChannelsTextController = TextEditingController();
  final appPortTextController = TextEditingController();

  LorawanScreen(
      {Key? key,
      required this.device,
      required this.controlChar,
      required this.credentialDataChar,
      required this.credentialStatusChar,
      required this.settingsDataChar,
      required this.settingsStatusChar})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LorawanScreenState();
}

class _LorawanScreenState extends State<LorawanScreen> {
  StreamController<List<String>> uartTxStreamController =
      StreamController<List<String>>();
  StreamController<String> devEuiStreamController = StreamController<String>();
  StreamController<String> controlStreamController = StreamController<String>();
  StreamController<String> credentialsStatusStreamController =
      StreamController<String>();
  StreamController<String> settingsStatusStreamController =
      StreamController<String>();
  StreamController<bool> adrEnabledStreamController = StreamController<bool>();
  StreamController<bool> confirmedMessageStreamController =
      StreamController<bool>();
  StreamController<bool> transmitButtonStreamController =
      StreamController<bool>();
  StreamController<String> loraRegionStreamController =
      StreamController<String>();

  bool adrEnabledSwitch = false;
  bool confirmedMessageSwitch = false;
  bool transmitButton = false;

  String selectedLoraRegion = "0";

  List<DropdownMenuItem<String>> get dropdownItems {
    List<DropdownMenuItem<String>> menuItems = [
      DropdownMenuItem(child: Text("AS923"), value: "0"),
      DropdownMenuItem(child: Text("AU915"), value: "1"),
      DropdownMenuItem(child: Text("CN470"), value: "2"),
      DropdownMenuItem(child: Text("CN779"), value: "3"),
      DropdownMenuItem(child: Text("EU433"), value: "4"),
      DropdownMenuItem(child: Text("EU868"), value: "5"),
      DropdownMenuItem(child: Text("KR920"), value: "6"),
      DropdownMenuItem(child: Text("IN865"), value: "7"),
      DropdownMenuItem(child: Text("US915"), value: "8"),
      DropdownMenuItem(child: Text("AS923-2"), value: "9"),
      DropdownMenuItem(child: Text("AS923-3"), value: "10"),
      DropdownMenuItem(child: Text("AS923-4"), value: "11"),
      DropdownMenuItem(child: Text("RU864"), value: "12"),
    ];
    return menuItems;
  }

  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    // Crential Data Read
    widget.credentialDataChar.read().then((value) {
      print("credential Data Char Read Result " + value.toString());
      List<int> creds = value;
      print(creds);

      widget.devEuiTextController.text =
          hex.encode(creds.getRange(0, 8).toList()).toUpperCase();
      widget.appEuiTextController.text =
          hex.encode(creds.getRange(8, 16).toList()).toUpperCase();
      widget.appKeyTextController.text =
          hex.encode(creds.getRange(16, 32).toList()).toUpperCase();
      // Credential Status Read
      widget.credentialStatusChar.read().then((value) {
        print("credential Status Char Read Result " + value.toString());
        // Settings Data Read
        widget.settingsDataChar.read().then((value) {
          print("settings Data Char Read Result " + value.toString());
          List<int> settings = value;
          print(settings);

          print(ByteData.view(
                  Uint8List.fromList(settings.getRange(0, 4).toList()).buffer)
              .getUint32(0, Endian.little)); // Transmit Repeat Interval
          print(settings[4]); // ADR Enabled true/false, toggle switch
          print(settings[5]); // Join Trials 1- 100
          print(settings[6]); // TX Power 0 - 15
          print(settings[7]); // Data Rate 0 - 15
          print(settings[8]); // Sub band channels 1 - 9
          print(settings[9]); // App Port 1 - 223
          print(settings[10]); // Confirmed Message true/false, toggle switch
          print(settings[11]); // LoRa Region 0 - 12, dropdown

          widget.transmitRepeatTextController.text = ByteData.view(
                  Uint8List.fromList(settings.getRange(0, 4).toList()).buffer)
              .getUint32(0, Endian.little)
              .toString();
          adrEnabledStreamController.add(settings[4] > 0);
          adrEnabledSwitch = settings[4] > 0;
          widget.joinTrialsTextController.text = settings[5].toString();
          widget.txPowerTextController.text = settings[6].toString();
          widget.dataRateTextController.text = settings[7].toString();
          widget.subbandChannelsTextController.text = settings[8].toString();
          widget.appPortTextController.text = settings[9].toString();
          confirmedMessageStreamController.add(settings[10] > 0);
          confirmedMessageSwitch = settings[10] > 0;
          loraRegionStreamController.add(settings[11].toString());

          // Settings Status Read
          widget.settingsStatusChar.read().then((value) {
            print("settings Status Char Read Result " + value.toString());
            // Control Read
            widget.controlChar.read().then((value) {
              print("Control Char Read Result " + value.toString());
              if (value[0] == 0) {
                transmitButtonStreamController.add(false);
                transmitButton = false;
                controlStreamController.add("Not Transmitting");
              } else if (value[0] == 1) {
                transmitButtonStreamController.add(true);
                transmitButton = true;
                controlStreamController.add("Transmitting");
              }
            });
          });
        });
      });
    });

    credentialsStatusStreamController.add("");
  }

  _writeControl(bool ctrl) async {
    widget.controlChar.write([ctrl ? 1 : 0]).then((value) {
      widget.controlChar.setNotifyValue(true).then((value) {
        print("control Char Notification Enabled Result " + value.toString());
        widget.controlChar.value.listen((value) {
          print("control Char notification Result " + value.toString());
          if (value[0] == 0) {
            transmitButtonStreamController.add(false);
            transmitButton = false;
            controlStreamController.add("Not Transmitting");
          } else if (value[0] == 1) {
            transmitButtonStreamController.add(true);
            transmitButton = true;
            controlStreamController.add("Transmitting");
          }
        });
      });
    });
  }

  _writeDataCredentials() async {
    var creds = getCredentialList();
    if (!creds.isEmpty) {
      widget.credentialDataChar.write(creds).then((value) {
        widget.credentialStatusChar.setNotifyValue(true).then((value) {
          print("credential Status Char Notification Enabled Result " +
              value.toString());
          widget.credentialStatusChar.value.listen((value) {
            print("credential Status Char notification Result " +
                value.toString());
            if (value[0] == 0) {
              credentialsStatusStreamController.add("");
            } else if (value[0] == 1) {
              credentialsStatusStreamController.add("New Credentials Accepted");
            } else if (value[0] == 2) {
              credentialsStatusStreamController
                  .add("Invalid Credential Lengths");
            }
          });
        });
      });
    }
  }

  _writeDataSettings() async {
    var settings = getSettingsList();
    if (!settings.isEmpty) {
      widget.settingsDataChar.write(settings).then((value) {
        widget.settingsStatusChar.setNotifyValue(true).then((value) {
          print("settings Status Char Notification Enabled Result " +
              value.toString());
          widget.settingsStatusChar.value.listen((value) {
            print("credential Status Char notification Result " +
                value.toString());
            if (value[0] == 0) {
              settingsStatusStreamController.add("");
            } else if (value[0] == 1) {
              settingsStatusStreamController.add("New Settings Accepted");
            } else if (value[0] == 2) {
              settingsStatusStreamController.add("Invalid Settings Lengths");
            }
          });
        });
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.credentialStatusChar.setNotifyValue(false).then((value) {
      print("credential Status Char Notification disable Result " +
          value.toString());
      widget.credentialDataChar.setNotifyValue(false).then((value) {
        print("credential Data Char Notification disable Result " +
            value.toString());
      });
    });
  }

  List<int> getCredentialList() {
    List<int> creds = [];
    try {
      print(hex.decode(widget.devEuiTextController.text));
      creds.addAll(hex.decode(widget.devEuiTextController.text));
      creds.addAll(hex.decode(widget.appEuiTextController.text));
      creds.addAll(hex.decode(widget.appKeyTextController.text));
    } on FormatException catch (e) {
      print(e);
      creds = [];
      credentialsStatusStreamController.add(e.message.toString());
      return creds;
    }
    return creds;
  }

  List<int> getSettingsList() {
    List<int> settings = [];
    try {
      settings.addAll(Uint8List(4)
        ..buffer.asByteData().setInt32(
            0,
            int.parse(widget.transmitRepeatTextController.text),
            Endian.little)); // Transmit Repeat Interval
      settings.addAll([adrEnabledSwitch ? 1 : 0]);
      settings.addAll([int.parse(widget.joinTrialsTextController.text)]);
      settings.addAll([int.parse(widget.txPowerTextController.text)]);
      settings.addAll([int.parse(widget.dataRateTextController.text)]);
      settings.addAll([int.parse(widget.subbandChannelsTextController.text)]);
      settings.addAll([int.parse(widget.appPortTextController.text)]);
      settings.addAll([confirmedMessageSwitch ? 1 : 0]);
      settings.addAll([int.parse(selectedLoraRegion)]);
      print(settings);
    } on FormatException catch (e) {
      print(e);
      settings = [];
      settingsStatusStreamController.add(e.message.toString());
      return settings;
    }
    return settings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ThemeColors.scaffoldBackground,
        appBar: AppBar(
          title: Text('LoRaWAN'),
          titleTextStyle: ThemeTextStyles.appBarTitle,
          backgroundColor: ThemeColors.appBarBackground,
          actions: <Widget>[],
        ),
        body: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            scrollDirection: Axis.vertical,
            child: Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // First child is enter comment text input
                      TextFormField(
                        inputFormatters: [
                          new LengthLimitingTextInputFormatter(16),
                        ],
                        decoration: InputDecoration(
                          labelText: 'DevEUI',
                        ),
                        controller: widget.devEuiTextController,
                      ),
                      TextFormField(
                        inputFormatters: [
                          new LengthLimitingTextInputFormatter(16),
                        ],
                        decoration: InputDecoration(
                          labelText: 'AppEUI',
                        ),
                        controller: widget.appEuiTextController,
                      ),
                      TextFormField(
                        inputFormatters: [
                          new LengthLimitingTextInputFormatter(32),
                        ],
                        decoration: InputDecoration(
                          labelText: 'AppKey',
                        ),
                        controller: widget.appKeyTextController,
                      ),
                      ButtonTheme(
                        minWidth: 240.0,
                        child: RaisedButton(
                          color: ThemeColors.buttonBackground,
                          child: Text('Save Credentials',
                              style: ThemeTextStyles.button),
                          textColor: Colors.white,
                          onPressed: () => {_writeDataCredentials()},
                        ),
                      ),
                      StreamBuilder<String>(
                          stream: credentialsStatusStreamController.stream,
                          initialData: '',
                          builder: (c, snapshot) {
                            return Text(
                              snapshot.data.toString(),
                              textAlign: TextAlign.center,
                            );
                          }),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                                width: 160.0,
                                child: TextFormField(
                                  inputFormatters: [
                                    new LengthLimitingTextInputFormatter(32),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Transmit Repeat Interval (s)',
                                  ),
                                  controller:
                                      widget.transmitRepeatTextController,
                                  enabled: true,
                                )),
                            Expanded(
                                child: TextFormField(
                              inputFormatters: [
                                new LengthLimitingTextInputFormatter(32),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Join Trials',
                              ),
                              controller: widget.joinTrialsTextController,
                              enabled: true,
                            )),

                            // First child is enter comment text input
                            Expanded(
                                child: TextFormField(
                              inputFormatters: [
                                new LengthLimitingTextInputFormatter(32),
                              ],
                              decoration: InputDecoration(
                                labelText: 'TX Power',
                              ),
                              controller: widget.txPowerTextController,
                              enabled: true,
                            )),

                            Expanded(
                                child: TextFormField(
                              inputFormatters: [
                                new LengthLimitingTextInputFormatter(32),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Data Rate',
                              ),
                              controller: widget.dataRateTextController,
                              enabled: true,
                            ))
                          ]),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                                child: TextFormField(
                              inputFormatters: [
                                new LengthLimitingTextInputFormatter(32),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Subband Channels',
                              ),
                              controller: widget.subbandChannelsTextController,
                              enabled: true,
                            )),
                            Expanded(
                                child: TextFormField(
                              inputFormatters: [
                                new LengthLimitingTextInputFormatter(32),
                              ],
                              decoration: InputDecoration(
                                labelText: 'App Port',
                              ),
                              controller: widget.appPortTextController,
                              enabled: true,
                            )),
                            StreamBuilder<String>(
                                stream: loraRegionStreamController.stream,
                                initialData: "0",
                                builder: (c, snapshot) {
                                  return Expanded(
                                      child: DropdownButton(
                                          value: snapshot.data,
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectedLoraRegion = newValue!;
                                              loraRegionStreamController
                                                  .add(newValue!);
                                            });
                                          },
                                          items: dropdownItems));
                                }),
                          ]),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // First child is enter comment text input
                            Expanded(child: Text('ADR Enabled')),
                            Expanded(
                              child: StreamBuilder<bool>(
                                  stream: adrEnabledStreamController.stream,
                                  initialData: false,
                                  builder: (c, snapshot) {
                                    return Switch(
                                      value: snapshot.data!,
                                      onChanged: (value) {
                                        setState(() {
                                          adrEnabledStreamController.add(value);
                                          adrEnabledSwitch = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    );
                                  }),
                            ),
                            Expanded(child: Text('Confirmed Message')),
                            Expanded(
                              child: StreamBuilder<bool>(
                                  stream:
                                      confirmedMessageStreamController.stream,
                                  initialData: false,
                                  builder: (c, snapshot) {
                                    return Switch(
                                      value: snapshot.data!,
                                      onChanged: (value) {
                                        setState(() {
                                          confirmedMessageStreamController
                                              .add(value);
                                          confirmedMessageSwitch = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    );
                                  }),
                            )
                          ]),

                      ButtonTheme(
                        minWidth: 240.0,
                        child: RaisedButton(
                          color: ThemeColors.buttonBackground,
                          child: Text('Save Settings',
                              style: ThemeTextStyles.button),
                          textColor: Colors.white,
                          onPressed: () => {_writeDataSettings()},
                        ),
                      ),
                      StreamBuilder<String>(
                          stream: settingsStatusStreamController.stream,
                          initialData: '',
                          builder: (c, snapshot) {
                            return Text(
                              snapshot.data.toString(),
                              textAlign: TextAlign.center,
                            );
                          }),

                      StreamBuilder<bool>(
                          stream: transmitButtonStreamController.stream,
                          initialData: false,
                          builder: (c, snapshot) {
                            return ButtonTheme(
                              minWidth: 240.0,
                              child: RaisedButton(
                                color: !snapshot.data!
                                    ? ThemeColors.buttonBackground
                                    : ThemeColors.buttonBackground,
                                child: !snapshot.data!
                                    ? Text('Start Transmitting',
                                        style: ThemeTextStyles.button)
                                    : Text('Stop Transmitting',
                                        style: ThemeTextStyles.button),
                                textColor: Colors.white,
                                onPressed: () => {
                                  _writeControl(!transmitButton),
                                  transmitButton = !transmitButton,
                                },
                              ),
                            );
                          }),
                      StreamBuilder<String>(
                          stream: controlStreamController.stream,
                          initialData: '',
                          builder: (c, snapshot) {
                            return Text(
                              snapshot.data.toString(),
                              textAlign: TextAlign.center,
                            );
                          }),
                    ]))));
  }
}
