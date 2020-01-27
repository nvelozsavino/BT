import 'package:bt_flutter/bluetooth_off.dart';
import 'package:bt_flutter/find_device.dart';
import 'package:bt_flutter/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              Log.instance.writeLog("Bluetooth ${state.toString()}");
              return FindDeviceScreen();
            }
            Log.instance.writeLog("Bluetooth ${state.toString()}");
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}
