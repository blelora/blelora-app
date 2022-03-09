import 'dart:async';

import 'package:flutter/material.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/utils/textStyles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:convert/convert.dart';

class LorawanScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic credentialDataChar;
  final BluetoothCharacteristic credentialStatusChar;
  final devEuiTextController = TextEditingController();
  final appEuiTextController = TextEditingController();
  final appKeyTextController = TextEditingController();

  LorawanScreen(
      {Key? key,
      required this.device,
      required this.credentialDataChar,
      required this.credentialStatusChar})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LorawanScreenState();
}

class _LorawanScreenState extends State<LorawanScreen> {
  StreamController<List<String>> uartTxStreamController =
      StreamController<List<String>>();
  StreamController<String> devEuiStreamController = StreamController<String>();
  StreamController<String> credentialsStatusStreamController =
      StreamController<String>();

  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    // Data Read
    widget.credentialDataChar.read().then((value) {
      print("credential Data Char Read Result " + value.toString());
      List<int> creds = value;
      print(creds);

      widget.devEuiTextController.text =
          hex.encode(creds.getRange(0, 8).toList());
      widget.appEuiTextController.text =
          hex.encode(creds.getRange(8, 16).toList());
      widget.appKeyTextController.text =
          hex.encode(creds.getRange(16, 32).toList());
      // Status Read
      widget.credentialStatusChar.read().then((value) {
        print("credential Status Char Read Result " + value.toString());
      });
    });

    credentialsStatusStreamController.add("");
  }

  _writeDataCredentials() async {
    var creds = getCredentialList();
    if (!creds.isEmpty) {
      widget.credentialDataChar.write(getCredentialList()).then((value) {
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
        body: Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                      // width: double.infinity,
                      // height: MediaQuery.of(context).size.height,
                      alignment: Alignment.bottomCenter,
                      margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // First child is enter comment text input
                            Expanded(
                                child: TextFormField(
                              inputFormatters: [
                                new LengthLimitingTextInputFormatter(16),
                              ],
                              decoration: InputDecoration(
                                labelText: 'DevEUI',
                              ),
                              controller: widget.devEuiTextController,
                            ))
                          ])),
                  Container(
                      // width: double.infinity,
                      // height: MediaQuery.of(context).size.height,
                      alignment: Alignment.bottomCenter,
                      margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // First child is enter comment text input
                            Expanded(
                                child: TextFormField(
                              inputFormatters: [
                                new LengthLimitingTextInputFormatter(16),
                              ],
                              decoration: InputDecoration(
                                labelText: 'AppEUI',
                              ),
                              controller: widget.appEuiTextController,
                            ))
                          ])),
                  Container(
                      // width: double.infinity,
                      // height: MediaQuery.of(context).size.height,
                      alignment: Alignment.bottomCenter,
                      margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // First child is enter comment text input
                            Expanded(
                                child: TextFormField(
                              inputFormatters: [
                                new LengthLimitingTextInputFormatter(32),
                              ],
                              decoration: InputDecoration(
                                labelText: 'AppKey',
                              ),
                              controller: widget.appKeyTextController,
                            ))
                          ])),
                  ButtonTheme(
                    minWidth: 240.0,
                    child: RaisedButton(
                      color: ThemeColors.buttonBackground,
                      child: Text('Save Credentials',
                          style: ThemeTextStyles.button),
                      textColor: Colors.white,
                      onPressed: () => {
                        // widget.credentialDataChar.write(getCredentialList())
                        _writeDataCredentials()
                      },
                    ),
                  ),
                  StreamBuilder<String>(
                      stream: credentialsStatusStreamController.stream,
                      initialData: '',
                      builder: (c, snapshot) {
                        return Column(children: <Widget>[
                          ListTile(
                            title: Text(snapshot.data.toString()),
                          )
                        ]);
                      })
                ])));
  }
}
