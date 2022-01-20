import 'package:flutter/material.dart';
import 'package:blelora_app/src/utils/colors.dart';

class ThemeTextStyles {
  static const appBarTitle = TextStyle(
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.normal,
    fontSize: 18.0,
    color: ThemeColors.textColor1,
    letterSpacing: 1,
  );

  static const title = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 20.0,
    color: ThemeColors.textColor1,
  );

  static const valueStyle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 16.0,
    color: ThemeColors.textColor1,
  );

  static const valueStyleUnit = TextStyle(
    height: 1.3,
    fontWeight: FontWeight.w400,
    fontSize: 14.0,
    color: ThemeColors.textColor1,
  );

  static const listTitle = TextStyle(
    color: ThemeColors.textColor2,
    fontSize: 16.0,
  );

  static const listTitleSubtitle = TextStyle(
    color: ThemeColors.textColor2,
    fontSize: 16.0,
  );

  static const listTitleTrailing = TextStyle(
    color: ThemeColors.textColor2,
    fontSize: 16.0,
  );

  static const resultUnit = TextStyle(
    color:  ThemeColors.textColor1,
    height: 1,
    decoration: TextDecoration.none,
    fontSize: 12.0,
  );

  static const button = TextStyle(
    color: ThemeColors.textColor1,
    fontSize: 16.0,
  );

  static const bottomNavBar = TextStyle(
    color: ThemeColors.textColor1,
    fontSize: 16.0,
  );
}
