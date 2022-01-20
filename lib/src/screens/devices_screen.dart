import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/utils/textStyles.dart';
import 'package:blelora_app/src/widgets/bluetooth_device_widgets.dart';
import 'package:blelora_app/src/screens/device_screen.dart';

final List<Guid> scanFilterServiceUuids = [
  Guid('00001530-1212-EFDE-1523-785FEABCD123')
];

class DevicesScreen extends StatelessWidget {
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  final BluetoothDevice? existingDevice;

  const DevicesScreen({Key? key, this.existingDevice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (c, snapshot) {
          return FindDevicesScreen(existingDevice: existingDevice);
        });
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, required this.state}) : super(key: key);
  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state.toString().substring(15)}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1!
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatefulWidget {
  final BluetoothDevice? existingDevice;

  const FindDevicesScreen({Key? key, this.existingDevice}) : super(key: key);

  _FindDevicesScreenState createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  StreamController<bool> showTipCardStreamController = StreamController<bool>();
  bool scanned = false;
  late BluetoothDevice currentDevice;
  bool connectedDevice = false;

  @override
  void dispose() {
    super.dispose();
    showTipCardStreamController.close();
  }

  @protected
  @mustCallSuper
  void initState() {
    super.initState();
    showTipCardStreamController.add(true);

    print("INIT STATE RUNNING");

    if (widget.existingDevice != null) {
      widget.existingDevice!.state.listen((connectionState) {
        if (connectionState == BluetoothDeviceState.connected) {
          currentDevice = widget.existingDevice!;
          connectedDevice = true;
        } else {
          connectedDevice = false;
        }
      });
    } else {
      FlutterBlue.instance.connectedDevices.then((value) => print(value));
    }

    FlutterBlue.instance.startScan(
        timeout: Duration(seconds: 3), withServices: scanFilterServiceUuids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: ThemeColors.appBarBackground,
        title: Text('Find Devices', style: ThemeTextStyles.appBarTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () => FlutterBlue.instance.startScan(
            timeout: Duration(seconds: 3),
            withServices: scanFilterServiceUuids),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              if (connectedDevice)
                ListTile(
                  title: Text(currentDevice.name, style: ThemeTextStyles.listTitle),
                  subtitle: Text("Connected", style: ThemeTextStyles.listTitleSubtitle),
                  trailing: RaisedButton(
                    color: ThemeColors.buttonBackground,
                    child: Text('OPEN', style: ThemeTextStyles.button),
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => DeviceScreen(
                                  device: currentDevice,
                                ))),
                  ),
                ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map(
                        (r) => ScanResultTile(
                          result: r,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            r.device.connect();
                            currentDevice = r.device;
                            return DeviceScreen(device: r.device);
                          })),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () {
                  showTipCardStreamController.add(false);
                  scanned = true;
                  FlutterBlue.instance.startScan(
                      timeout: Duration(seconds: 3),
                      withServices: scanFilterServiceUuids);
                  if (widget.existingDevice != null) {
                    widget.existingDevice!.state.listen((connectionState) {
                      if (connectionState == BluetoothDeviceState.connected) {
                        currentDevice = widget.existingDevice!;
                        setState(() {
                          connectedDevice = true;
                        });
                      } else {
                        setState(() {
                          connectedDevice = false;
                        });
                      }
                    });
                  }
                });
          }
        },
      ),
    );
  }
}
