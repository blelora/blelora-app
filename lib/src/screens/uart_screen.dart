import 'dart:async';

import 'package:flutter/material.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/utils/textStyles.dart';
import 'package:flutter_blue/flutter_blue.dart';

class UartScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic uartRxChar;
  final BluetoothCharacteristic uartTxChar;
  final sendTextController = TextEditingController();

  UartScreen({
    Key? key,
    required this.device,
    required this.uartRxChar,
    required this.uartTxChar
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UartScreenState();
}

class _UartScreenState extends State<UartScreen> {
  StreamController<List<String>> uartTxStreamController =
  StreamController<List<String>>();
  StreamController<String> uartRxStreamController =
  StreamController<String>();

  var uartTxCharList = <String>[];

  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    uartTxStreamController.add(['']);

    widget.uartTxChar.setNotifyValue(true).then((value) {
      print("uartTxChar Notification Enabled Result " +
          value.toString());
      widget.uartTxChar.value.listen((value) {
        if (!uartTxStreamController.isClosed) {
          uartTxCharList.add(String.fromCharCodes(value));
          uartTxStreamController.add(uartTxCharList);
        }
      });
      uartRxStreamController.stream.listen((value) {
        widget.uartRxChar.write(value.codeUnits);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    uartTxStreamController.close();
    uartRxStreamController.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ThemeColors.scaffoldBackground,
        appBar: AppBar(
          title: Text('UART'),
          titleTextStyle: ThemeTextStyles.appBarTitle,
          backgroundColor: ThemeColors.appBarBackground,
          actions: <Widget>[],
        ),
        body: Column(children: <Widget>[
          StreamBuilder<List<String>>(
              stream: uartTxStreamController.stream,
              initialData:[''],
              builder: (c, snapshot) {
                // print("in stream building: ${snapshot.data}");
                return RichText(
                  text: TextSpan(
                    text: uartTxCharList.toString(),
                    style: ThemeTextStyles.listTitle,
                  ),
                );
              }),
          Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10.0, left: 30.0, right: 30.0),
              child: RichText(
                text: TextSpan(
                  text: 'Hello ',
                  style: ThemeTextStyles.listTitle,
                ),
              )),
          Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10.0, left: 40.0, right: 40.0),
              child: TextFormField(
                decoration: InputDecoration(
                    labelText: 'Transmit Text',
                    suffixIcon: RaisedButton(
                        onPressed: () => uartRxStreamController.add(widget.sendTextController.text),
                        child: Text("Send"))),
                controller: widget.sendTextController,
              ))
        ]));
  }
}
