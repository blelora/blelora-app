import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:blelora_app/src/http.dart';
import 'package:blelora_app/src/screens/dfu_screen.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/utils/textStyles.dart';
import 'package:path_provider/path_provider.dart';

class BrowseCommunityFirmwareSummaryScreen extends StatefulWidget {
  const BrowseCommunityFirmwareSummaryScreen(
      {Key? key, required this.device, required this.firmareInfo})
      : super(key: key);
  final Map firmareInfo;
  final BluetoothDevice device;

  _BrowseCommunityFirmwareSummaryScreenState createState() =>
      _BrowseCommunityFirmwareSummaryScreenState();
}

class _BrowseCommunityFirmwareSummaryScreenState
    extends State<BrowseCommunityFirmwareSummaryScreen> {
  var decoded_json;
  var firmware_zip_path = "";

  StreamController<Map> dfuFirmwareInfoMapStream =
      StreamController<Map>.broadcast();

  @override
  void dispose() {
    super.dispose();
    dfuFirmwareInfoMapStream.close();
  }

  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    print(widget.firmareInfo);

    dfuFirmwareInfoMapStream.add({"description": " ", "version": " "});

    var url = Uri.parse(widget.firmareInfo["firmware_description"]);

    // RegExp exp = RegExp(r".*/(?<filename>.*?)\.zip");
    // var matches = exp.allMatches(item["path"]);
    // var firmwareName =  matches.elementAt(0).group(1);

    // hotspot info http
    http.get(url).then((value) {
      var parsed = json.decode(value.body);
      var content = parsed["content"];
      String replaced_string = content.replaceAll("\n", "");
      var decoded_base64 = base64.decode(base64.normalize(replaced_string));
      decoded_json = json.decode(utf8.decode(decoded_base64));
      print(decoded_json);
      getTemporaryDirectory().then((tempDir) {
        RegExp exp = RegExp(r".*/(?<filename>.*?)\.zip");
        var matches = exp.allMatches(decoded_json["dfuzip"]["url"]);
        var firmwareName =  matches.elementAt(0).group(1);
        String fullPath = tempDir.path + "/${firmwareName}.zip";
        print(fullPath);
        firmware_zip_path = fullPath;
        dfuFirmwareInfoMapStream.add(decoded_json);
        dio.download(decoded_json["dfuzip"]["url"], fullPath).then((value) {
          print(value);
        });
      });
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
        title: Text("Firmware Description"),
        actions: <Widget>[],
      ),
      body: StreamBuilder<Map>(
          stream: dfuFirmwareInfoMapStream.stream,
          initialData: {"description": " ", "homepage": "", "version": " "},
          builder: (c, snapshot) {
            if (snapshot.data != null) {
              return ListView(
                padding: const EdgeInsets.all(8),
                children: <Widget>[
                  Container(
                    height: 50,
                    child: Center(child: Text(snapshot.data!["description"], style: ThemeTextStyles.listTitle)),
                  ),
                  Container(
                    height: 50,
                    child: Center(child: Text(snapshot.data!["homepage"], style: ThemeTextStyles.listTitle)),
                  ),
                  Container(
                    height: 50,
                    child: Center(
                        child: Text("Version: ${snapshot.data!["version"]}", style: ThemeTextStyles.listTitle)),
                  ),
                  RaisedButton(

                      child: Text('Select Firmware', style: ThemeTextStyles.button),
                      color: ThemeColors.buttonBackground,
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) {
                          return DFUScreen(
                            device: widget.device,
                            dfuFilePath: firmware_zip_path,
                            dfuEnable: true,
                          );
                        }));
                      }),
                ],
              );
            } else
              return Text("Error");
          }),
    );
  }
}
