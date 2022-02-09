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

  UartScreen(
      {Key? key,
      required this.device,
      required this.uartRxChar,
      required this.uartTxChar})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _UartScreenState();
}

class _UartScreenState extends State<UartScreen> {
  StreamController<List<String>> uartTxStreamController =
      StreamController<List<String>>();
  StreamController<String> uartRxStreamController = StreamController<String>();

  var uartTxCharList = <String>[];

  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    uartTxStreamController.add(['']);

    widget.uartTxChar.setNotifyValue(true).then((value) {
      print("uartTxChar Notification Enabled Result " + value.toString());
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
        body: Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: StreamBuilder<List<String>>(
                          stream: uartTxStreamController.stream,
                          initialData: [''],
                          builder: (c, snapshot) {
                            // print("in stream building: ${snapshot.data}");
                            return RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                text: uartTxCharList.join().toString(),
                                style: ThemeTextStyles.listTitle,
                              ),
                            );
                          }),
                    ),
                  ),
                  // ),
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
                              decoration: InputDecoration(
                                  labelText: 'Transmit Text',
                                  suffixIcon: RaisedButton(
                                      onPressed: () => uartRxStreamController
                                          .add(widget.sendTextController.text),
                                      color: ThemeColors.buttonBackground,
                                      child: Text('SEND',
                                          style: ThemeTextStyles.button))),
                              controller: widget.sendTextController,
                            ))
                          ]))
                ])));
  }
}
