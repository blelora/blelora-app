import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:blelora_app/src/screens/devices_screen.dart';
import 'package:blelora_app/src/screens/more_screen.dart';
import 'package:blelora_app/src/utils/colors.dart';
import 'package:blelora_app/src/utils/textStyles.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mappers App',
      theme: ThemeData(
        // primarySwatch: Colors.blue,
        primaryColor: Colors.red,
        accentColor: Colors.redAccent,
      ),
      home: const ParentWidget(),
    );
  }
}

class ParentWidget extends StatefulWidget {
  const ParentWidget({Key? key, this.existingDevice}) : super(key: key);
  final BluetoothDevice? existingDevice;

  @override
  _ParentWidgetState createState() => _ParentWidgetState();
}

class _ParentWidgetState extends State<ParentWidget> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  List<Widget> _widgetOptions () => <Widget>[DevicesScreen(existingDevice: widget.existingDevice), MoreScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = _widgetOptions();
    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBackground,
      body: Center(
        child: widgetOptions[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: ThemeColors.bottomNavigationBarBackground,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.bluetooth, color: ThemeColors.bottomNavigationActiveIcon),
            icon: Icon(Icons.bluetooth, color: ThemeColors.bottomNavigationIcon),
            title: Text('Devices', style: ThemeTextStyles.bottomNavBar),
            backgroundColor: ThemeColors.bottomNavigationBarItemBackground,
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.menu, color: ThemeColors.bottomNavigationActiveIcon),
            icon: Icon(Icons.menu, color: ThemeColors.bottomNavigationIcon),
            title: Text('More', style: ThemeTextStyles.bottomNavBar),
            backgroundColor: ThemeColors.bottomNavigationBarItemBackground,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
