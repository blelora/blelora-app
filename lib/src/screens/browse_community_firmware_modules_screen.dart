import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/utils/textStyles.dart';

import 'browse_community_firmware_version_screen.dart';

class BrowseCommunityFirmwareModulesScreen extends StatefulWidget {
  const BrowseCommunityFirmwareModulesScreen({Key? key, required this.device})
      : super(key: key);
  final BluetoothDevice device;

  _BrowseCommunityFirmwareModulesScreenState createState() =>
      _BrowseCommunityFirmwareModulesScreenState();
}

class _BrowseCommunityFirmwareModulesScreenState
    extends State<BrowseCommunityFirmwareModulesScreen> {
  StreamController<Map> firmwareMapStreamController = StreamController<Map>();

  @override
  void dispose() {
    super.dispose();
    firmwareMapStreamController.close();
  }

  @protected
  @mustCallSuper
  void initState() {
    super.initState();
    firmwareMapStreamController.add({});
    var moduleList = {};

    var url = Uri.parse(
        "https://api.github.com/repos/blelora/community-firmware/git/trees/master?recursive=1");

    // hotspot info http
    http.get(url).then((value) {
      var parsed = json.decode(value.body);
      var gitTree = parsed["tree"];
      // print(gitTree);
      // RegExp exp = RegExp(r"^firmware/(\w+)$"); //firmware top level names
      RegExp exp = RegExp(r"^firmware/(.+)/(.+).json$");
      var tempList = <Map>[];
      gitTree.forEach((item) {
        if (item["path"].contains(exp) == true) {
          var matches = exp.allMatches(item["path"]);
          var tempMap = {};
          tempMap["module"] = matches.elementAt(0).group(1);
          tempMap["firmware_name"] = matches.elementAt(0).group(2);
          var url = item["url"];
          tempMap["firmware_description"] = url;
          tempList.add(tempMap);
        }
      });
      // firmwareListStreamController.add(tempList);
      var newMap = groupBy(tempList, (Map obj) => obj['module']);
      print(newMap);
      var testList = [newMap];
      firmwareMapStreamController.add(newMap);
      print(testList[0]);
    }).catchError((e) {
      print("GitHub API Error: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ThemeColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: ThemeColors.appBarBackground,
          title: Text("Select Hardware Model"),
          actions: <Widget>[],
        ),
        body: SingleChildScrollView(
            child: StreamBuilder<Map>(
                stream: firmwareMapStreamController.stream,
                initialData: {},
                builder: (c, snapshot) {
                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      String key = snapshot.data!.keys.elementAt(index);
                      var firmware_list = snapshot.data![key];
                      return ListTile(
                          title: Text("$key", style: ThemeTextStyles.listTitle),
                          trailing: Icon(Icons.keyboard_arrow_right, color: ThemeColors.listTileTrailingIcon),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) {
                              return BrowseCommunityFirmwareVersionScreen(
                                  device: widget.device,
                                  moduleList: snapshot.data![key]);
                            }));
                          });
                    },
                  );
                })));
  }
}
