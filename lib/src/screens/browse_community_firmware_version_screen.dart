import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/material.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/utils/textStyles.dart';

import 'browse_community_firmware_summary_screen.dart';

class BrowseCommunityFirmwareVersionScreen extends StatefulWidget {
  const BrowseCommunityFirmwareVersionScreen(
      {Key? key, required this.device, required this.moduleList})
      : super(key: key);
  final moduleList;
  final BluetoothDevice device;

  _BrowseCommunityFirmwareVersionScreenState createState() =>
      _BrowseCommunityFirmwareVersionScreenState();
}

class _BrowseCommunityFirmwareVersionScreenState
    extends State<BrowseCommunityFirmwareVersionScreen> {
  var decoded_json;
  var firmware_zip_path = "";

  StreamController<List> dfuFirmwareInfoMapStream =
      StreamController<List>.broadcast();

  @override
  void dispose() {
    super.dispose();
    dfuFirmwareInfoMapStream.close();
  }

  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    dfuFirmwareInfoMapStream.add([]);
    dfuFirmwareInfoMapStream.add(widget.moduleList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ThemeColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: ThemeColors.appBarBackground,
          title: Text("Firmware"),
          actions: <Widget>[],
        ),
        body: Column(children: <Widget>[
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: widget.moduleList.length,
            itemBuilder: (context, index) {
              print(widget.moduleList[index]);
              return ListTile(
                  title: Text(widget.moduleList[index]["firmware_name"],  style: ThemeTextStyles.listTitle),
                  trailing: Icon(Icons.keyboard_arrow_right, color: ThemeColors.listTileTrailingIcon),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return BrowseCommunityFirmwareSummaryScreen(
                          device: widget.device,
                          firmareInfo: widget.moduleList[index]);
                    }));
                    print("pressed");
                  });
            },
          ),
        ]));
  }
}
