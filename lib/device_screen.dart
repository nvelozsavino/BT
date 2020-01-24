import 'dart:math';

import 'package:bt_flutter/temp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/subjects.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({Key key, this.device}) : super(key: key);
  @override
  _DeviceScreenState createState() => _DeviceScreenState(device);
}

class _DeviceScreenState extends State<DeviceScreen> {
  final BluetoothDevice device;

  bool isConnected;

  _DeviceScreenState(this.device);

  Guid serviceGuid = Guid('0000180d-0000-1000-8000-00805f9b34fb');
  Guid characteristicGuid = Guid('00002a37-0000-1000-8000-00805f9b34fb');

  BehaviorSubject<BluetoothCharacteristic> characteristic = BehaviorSubject();

  Stream<BluetoothCharacteristic> get btchar => characteristic.stream;

  @override
  void initState() {
    readState();

    super.initState();
  }

  @override
  void dispose() {
    device.disconnect();
    characteristic.close();
    super.dispose();
  }

  void discoverServices() {
    device.discoverServices().then((s) {
      s.forEach((ser) {
        if (ser.uuid == serviceGuid) {
          ser.characteristics.forEach((c) async {
            if (c.uuid == characteristicGuid) {
              await c.setNotifyValue(true);
              //   characteristic.sink.add(c);
              return;
            }
          });
        }
      });
    });
  }

  void readState() {
    device.state.listen((state) {
      if (state == BluetoothDeviceState.connected) {
        setState(() {
          isConnected = true;
          discoverServices();
        });
      }

      if (state == BluetoothDeviceState.disconnected) {
        setState(() {
          isConnected = false;
        });
      }
    });
  }

  List<int> _getRandomBytes() {
    final math = Random();
    return [
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255)
    ];
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () => c.read(),
                    onWritePressed: () => c.write(_getRandomBytes()),
                    onNotificationPressed: () =>
                        c.setNotifyValue(!c.isNotifying),
                    descriptorTiles: c.descriptors
                        .map(
                          (d) => DescriptorTile(
                            descriptor: d,
                            onReadPressed: () => d.read(),
                            onWritePressed: () => d.write(_getRandomBytes()),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothDeviceState.connected)
                    ? Icon(Icons.bluetooth_connected)
                    : Icon(Icons.bluetooth_disabled),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${device.id}'),
                trailing: Switch(
                  activeColor: Colors.green,
                  value: isConnected,
                  onChanged: (bool value) {
                    value
                        ? device.connect().then((v) {
                            setState(() {
                              isConnected = value;
                            });
                          }).whenComplete(() {
                            device.discoverServices();
                          })
                        : device.disconnect().whenComplete(() {
                            setState(() {
                              isConnected = value;
                            });
                          });
                  },
                ),
              ),
            ),
            StreamBuilder<int>(
              stream: device.mtu,
              initialData: 0,
              builder: (c, snapshot) => ListTile(
                title: Text('MTU Size'),
                subtitle: Text('${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => device.requestMtu(223),
                ),
              ),
            ),
            StreamBuilder<BluetoothDeviceState>(
                stream: device.state,
                initialData: BluetoothDeviceState.disconnected,
                builder: (context, snapshot) => snapshot.hasData &&
                        snapshot.data == BluetoothDeviceState.connected
                    ? /* StreamBuilder<BluetoothCharacteristic>(
                        stream: btchar,
                        initialData: null,
                        builder: (c, snapshot) {
                          return Text(snapshot.data.uuid.toString());
                        })

                    */
                    StreamBuilder<List<BluetoothService>>(
                        stream: device.services,
                        initialData: [],
                        builder: (c, snapshot) {
                          return Column(
                            children: _buildServiceTiles(snapshot.data),
                          );
                        },
                      )
                    : Container()),
          ],
        ),
      ),
    );
  }
}
