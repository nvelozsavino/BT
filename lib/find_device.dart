import 'package:bt_flutter/device_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class FindDeviceScreen extends StatefulWidget {
  FindDeviceScreen({Key key}) : super(key: key);

  @override
  _FindDeviceScreenState createState() => _FindDeviceScreenState();
}

class _FindDeviceScreenState extends State<FindDeviceScreen> {
  BluetoothDevice device;

  @override
  void initState() {
    scanDevices();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            device != null
                ? StreamBuilder<BluetoothDeviceState>(
                    stream: device.state,
                    initialData: BluetoothDeviceState.connecting,
                    builder: (c, snapshot) => ListTile(
                      leading: (snapshot.data == BluetoothDeviceState.connected)
                          ? Icon(Icons.bluetooth_connected)
                          : Icon(Icons.bluetooth_disabled),
                      title: Text(
                          'Device is ${snapshot.data.toString().split('.')[1]}.'),
                      subtitle: Text('${device.id}'),
                      trailing: StreamBuilder<bool>(
                        stream: device.isDiscoveringServices,
                        initialData: false,
                        builder: (c, snapshot) => IndexedStack(
                          index: snapshot.data ? 1 : 0,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.refresh),
                              onPressed: () => device.discoverServices(),
                            ),
                            IconButton(
                              icon: SizedBox(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.grey),
                                ),
                                width: 18.0,
                                height: 18.0,
                              ),
                              onPressed: null,
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(),
            StreamBuilder<bool>(
              stream: FlutterBlue.instance.isScanning,
              initialData: false,
              builder: (context, snapshot) => snapshot.data
                  ? Column(children: [
                      CircularProgressIndicator(),
                      MaterialButton(
                          color: Colors.blue,
                          onPressed: () {
                            stopScan();
                          },
                          child: Text('Stop')),
                    ])
                  : MaterialButton(
                      color: Colors.blue,
                      onPressed: () => scanDevices(),
                      child: Text('Rescan')),
            ),
            StreamBuilder<List<ScanResult>>(
              stream: FlutterBlue.instance.scanResults,
              initialData: [],
              builder: (context, snapshot) =>
                  snapshot.hasData && snapshot.data.length > 0
                      ? snapshot.data
                          .map((d) => ListTile(
                              title: Text(
                                'Se encontró',
                                textAlign: TextAlign.center,
                              ),
                              subtitle: Text(
                                d.device.id.id,
                                textAlign: TextAlign.center,
                              )))
                          .last
                      : Container(),
            ),
            StreamBuilder<List<BluetoothDevice>>(
              stream: Stream.periodic(Duration(seconds: 1))
                  .asyncMap((_) => FlutterBlue.instance.connectedDevices),
              initialData: [],
              builder: (context, snapshot) =>
                  snapshot.hasData && snapshot.data.length > 0
                      ? snapshot.data
                          .map((d) => ListTile(
                              onTap: () => d.disconnect(),
                              title: Text(
                                'Se conectó a',
                                textAlign: TextAlign.center,
                              ),
                              subtitle: Text(
                                d.id.id,
                                textAlign: TextAlign.center,
                              )))
                          .last
                      : Text('No se ha conectado'),
            ),
          ],
        ),
      ),
    );
  }

  void scanDevices() {
    FlutterBlue.instance
        .startScan(timeout: Duration(seconds: 10))
        .then((value) {
      final List<ScanResult> list = value;

      list.forEach((d) {
        print(d.device.id.id);
        if (d.device.id.id == 'CE:D6:7D:19:4D:D5') {
          setState(() {
            device = d.device;
            device.connect();
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => DeviceScreen(device: device)));
          });
        }
      });
    });

    // .whenComplete(() => FlutterBlue.instance.stopScan());
  }

  void stopScan() async {
    await FlutterBlue.instance.stopScan();
  }
}
