import 'package:flutter/material.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/utils/textStyles.dart';
import 'package:url_launcher/url_launcher.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ThemeColors.scaffoldBackground,
        appBar: AppBar(
        title: Text('More'),
          titleTextStyle: ThemeTextStyles.appBarTitle,
          backgroundColor: ThemeColors.appBarBackground,
          actions: <Widget>[],
        ),
        body: ListView(
          children: ListTile.divideTiles(context: context, tiles: [
            ListTile(
                title: Text('Version', style: ThemeTextStyles.listTitle),
                trailing: Text("1.0.0", style: ThemeTextStyles.listTitleTrailing)),
            ListTile(
              title: Text('Source Code - Git Hub', style: ThemeTextStyles.listTitle),
              onTap: () {
                launch('https://github.com/blelora/blelora-app');
              },
            ),
          ]).toList(),
        ));
  }
}
