import 'dart:async';
import 'dart:convert';

import 'dart:math';
import 'dart:typed_data';

import 'package:bt_flutter/control_button.dart';
import 'package:bt_flutter/temp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';

enum SnackbarType { SNACKBAR_ERROR, SNACKBAR_SUCCESS }

enum BluetoothState { SEARCHING, CONNECTING, CONNECTED }

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({Key key, this.device}) : super(key: key);
  @override
  _DeviceScreenState createState() => _DeviceScreenState(device);
}

class _DeviceScreenState extends State<DeviceScreen> {
  final BluetoothDevice device;

  bool isConnected;
  bool deviceConnected = false;

  _DeviceScreenState(this.device);

  //Guid serviceGuid = Guid('00001811-0000-1000-8000-00805f9b34fb');
  Guid serviceGuid = Guid('19b10000-e8f2-537e-4f6c-d104768a1214');
  Guid characteristicGuid = Guid('19b10001-e8f2-537e-4f6c-d104768a1214');
  //Guid characteristicGuid = Guid('00002a44-0000-1000-8000-00805f9b34fb');
  var logBuffer = new StringBuffer();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  ScrollController logScroll = new ScrollController();

  String logText = "";

  Widget content() {
    return Column(
      children: <Widget>[
        StreamBuilder<BluetoothDeviceState>(
          stream: device.state,
          initialData: BluetoothDeviceState.connecting,
          builder: (c, snapshot) => ListTile(
            leading: (snapshot.data == BluetoothDeviceState.connected)
                ? Icon(Icons.bluetooth_connected)
                : Icon(Icons.bluetooth_disabled),
            title: Text('Device is ${snapshot.data.toString().split('.')[1]}.'),
            subtitle: Text('${device.id}'),
            trailing: Switch(
              activeColor: Colors.green,
              value: isConnected,
              onChanged: (bool value) {
                value
                    ? device.connect().then((v) {
                        setState(() {
                          isConnected = true;
                        });
                      }).whenComplete(() {
                        writeLog("Se ha conectado a ${device.id.id}");
                        device.discoverServices();
                      })
                    : device.disconnect().then((v) {
                        setState(() {
                          isConnected = false;
                        });
                      }).whenComplete(() {
                        writeLog("Se ha desconectado de ${device.id.id}");
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
                ? StreamBuilder<List<BluetoothService>>(
                    stream: device.services,
                    initialData: [],
                    builder: (c, snapshot) {
                      var cc = snapshot.data
                          .firstWhere((s) => s.uuid == serviceGuid)
                          .characteristics
                          .firstWhere((c) => c.uuid == characteristicGuid);

                      print(cc.uuid.toString());
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                ControlButtons(
                                  upIcon: Icons.arrow_drop_up,
                                  downIcon: Icons.arrow_drop_down,
                                  color: Colors.blueGrey,
                                  onIncrement: () => cc
                                      .write(upStart())
                                      .timeout(Duration(seconds: 1),
                                          onTimeout: () async {
                                    writeLog("Timeout on downStop");
                                    showSnackbar(
                                        message: "Timeout",
                                        type: SnackbarType.SNACKBAR_ERROR);
                                  }),
                                  onDecrement: () => cc
                                      .write(downStart())
                                      .timeout(Duration(seconds: 1),
                                          onTimeout: () async {
                                    writeLog("Timeout on downStart");
                                    showSnackbar(
                                        message: "Timeout",
                                        type: SnackbarType.SNACKBAR_ERROR);
                                  }),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                ControlButtons(
                                  color: Colors.red,
                                  upIcon: Icons.arrow_drop_up,
                                  downIcon: Icons.arrow_drop_down,
                                  onIncrement: () => cc
                                      .write(upStop())
                                      .timeout(Duration(seconds: 1),
                                          onTimeout: () async {
                                    writeLog("Timeout on upStop");
                                    showSnackbar(
                                        message: "Timeout",
                                        type: SnackbarType.SNACKBAR_ERROR);
                                  }),
                                  onDecrement: () => cc
                                      .write(downStop())
                                      .timeout(Duration(seconds: 1),
                                          onTimeout: () async {
                                    writeLog("Timeout on downStop");
                                    showSnackbar(
                                        message: "Timeout",
                                        type: SnackbarType.SNACKBAR_ERROR);
                                  }),
                                )
                              ],
                            ),
                          ),
                        ],
                      );
                    })
                : Container()),
        /*StreamBuilder<List<BluetoothService>>(
                stream: device.services,
                initialData: [],
                builder: (c, snapshot) {
                  return Column(
                    children: _buildServiceTiles(snapshot.data),
                  );
                }),*/
      ],
    );
  }

  void writeLog(String message) {
    var time = new DateTime.now().toString().substring(0, 16);
    logBuffer.writeln("$time: $message");
    setState(() {
      logText = logBuffer.toString();
    });
  }

  void showSnackbar({String message, SnackbarType type}) {
    scaffoldKey.currentState.showSnackBar(SnackBar(
      duration: Duration(seconds: type == SnackbarType.SNACKBAR_ERROR ? 4 : 2),
      backgroundColor:
          type == SnackbarType.SNACKBAR_ERROR ? Colors.red : Colors.green,
      content: ListTile(
        title: Text(message),
        trailing: Icon(
            type == SnackbarType.SNACKBAR_ERROR ? Icons.cancel : Icons.done),
      ),
    ));
  }

  @override
  void initState() {
    setState(() {
      isConnected = false;
    });
    readState();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    device.disconnect();
  }

  void discoverServices() {
    device.discoverServices().then((s) {
      s.forEach((ser) {
        print(ser.uuid.toString());
        if (ser.uuid == serviceGuid) {
          writeLog(
              "Se ha encontrado el servicio ${'0x${ser.uuid.toString().toUpperCase().substring(4, 8)}'}");
          ser.characteristics.forEach((c) async {
            print(c.uuid);
            if (c.uuid == characteristicGuid) {
              writeLog(
                  "Se ha encontrado la caracteristica ${'0x${c.uuid.toString().toUpperCase().substring(4, 8)}'}");
              setState(() {
                isConnected = true;
              });

              await c.setNotifyValue(true).whenComplete(() {
                c.value.timeout(Duration(seconds: 1), onTimeout: (v) {
                  writeLog("Timeout notify value");
                  showSnackbar(
                      message: "Timeout", type: SnackbarType.SNACKBAR_ERROR);
                }).listen((v) {
                  if (v.isNotEmpty) {
                    print(v);
                    writeLog("Se recibió ${v.toString()}");
                    if (v.contains(0)) {
                      showSnackbar(
                          message: '', type: SnackbarType.SNACKBAR_SUCCESS);
                    } else {
                      showSnackbar(
                          message: 'Code error: $v',
                          type: SnackbarType.SNACKBAR_ERROR);
                    }
                  }
                });
                writeLog(
                    "Notificando 0x${c.uuid.toString().toUpperCase().substring(4, 8)}");
              });
            }
          });
        }
      });
    });
  }

  void readState() {
    device.state.listen((state) {
      if (state == BluetoothDeviceState.connected) {
        FlutterBlue.instance.setLogLevel(LogLevel.error);
        setState(() {
          isConnected = true;
        });
        discoverServices();
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

  List<int> upStart() {
    writeLog('${[0x00]}');
    writeLog('upStart write ${[0x53]}');
    return [0x53];
  }

  List<int> downStart() {
    writeLog('downStart write ${[0x54]}');
    return [0x54];
  }

  List<int> upStop() {
    writeLog('upStop write ${[0x90]}');
    return [0x90];
    //  return _getRandomBytes();
  }

  List<int> downStop() {
    writeLog('downStop write ${[0x91]}');
    return [0x91];
    //return _getRandomBytes();
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

  Widget controlArea() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: FractionalOffset.bottomCenter,
          colors: [
            Color(0xff232526),
            Color(0xff414345),
          ],
          tileMode: TileMode.clamp,
        ),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(60),
            topRight: Radius.circular(60),
            bottomLeft: Radius.circular(60),
            bottomRight: Radius.circular(60)),
      ),
      child: StreamBuilder<BluetoothDeviceState>(
          stream: device.state,
          initialData: BluetoothDeviceState.connected,
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                snapshot.data == BluetoothDeviceState.connected) {
              return StreamBuilder<List<BluetoothService>>(
                stream: device.services,
                initialData: [],
                builder: (c, snapshot) {
                  if (snapshot.hasData) {
                    try {
                      var cc = snapshot.data
                          .firstWhere((s) => s.uuid == serviceGuid)
                          .characteristics
                          .firstWhere((c) => c.uuid == characteristicGuid);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                    child: ControlButtons(
                                  color: Color(0xff5bc236),
                                  upIcon: Icons.arrow_drop_up,
                                  downIcon: Icons.arrow_drop_down,
                                  onIncrement: () => cc
                                      .write(upStart())
                                      .timeout(Duration(seconds: 1),
                                          onTimeout: () async {
                                        writeLog("Timeout on upStart");
                                        showSnackbar(
                                            message: "Timeout",
                                            type: SnackbarType.SNACKBAR_ERROR);
                                      })
                                      .then((v) {
                                        writeLog(
                                            "upStart write ${v.toString()}");
                                      })
                                      .whenComplete(
                                          () => writeLog("downStart completed"))
                                      .catchError((Object e) {
                                        writeLog("upStart  ${e.toString()}");
                                        showSnackbar(
                                            message: e.toString(),
                                            type: SnackbarType.SNACKBAR_ERROR);
                                      }),
                                  onDecrement: () => cc
                                      .write(downStop())
                                      .timeout(Duration(seconds: 1),
                                          onTimeout: () async {
                                        writeLog("Timeout on downStart");
                                        showSnackbar(
                                            message: "Timeout",
                                            type: SnackbarType.SNACKBAR_ERROR);
                                      })
                                      .then((v) {
                                        writeLog(
                                            "downStart write ${v.toString()}");
                                      })
                                      .whenComplete(
                                          () => writeLog("downStart completed"))
                                      .catchError((Object e) {
                                        writeLog("downStart  ${e.toString()}");
                                        showSnackbar(
                                            message: e.toString(),
                                            type: SnackbarType.SNACKBAR_ERROR);
                                      }),
                                )),
                              ]),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              ControlButtons(
                                color: Colors.red,
                                upIcon: Icons.arrow_drop_up,
                                downIcon: Icons.arrow_drop_down,
                                onIncrement: () => cc
                                    .write(upStop())
                                    .timeout(Duration(seconds: 1),
                                        onTimeout: () async {
                                      writeLog("Timeout on upStop");
                                      showSnackbar(
                                          message: "Timeout",
                                          type: SnackbarType.SNACKBAR_ERROR);
                                    })
                                    .then((v) {
                                      writeLog("upStop write ${v.toString()}");
                                    })
                                    .whenComplete(
                                        () => writeLog("upStop completed"))
                                    .catchError((Object e) {
                                      writeLog("upStop  ${e.toString()}");
                                      showSnackbar(
                                          message: e.toString(),
                                          type: SnackbarType.SNACKBAR_ERROR);
                                    }),
                                onDecrement: () => cc
                                    .write(downStop())
                                    .timeout(Duration(seconds: 1),
                                        onTimeout: () async {
                                      writeLog("Timeout on downStop");
                                      showSnackbar(
                                          message: "Timeout",
                                          type: SnackbarType.SNACKBAR_ERROR);
                                    })
                                    .then((v) {
                                      writeLog(
                                          "downStop write ${v.toString()}");
                                    })
                                    .whenComplete(
                                        () => writeLog("downStop completed"))
                                    .catchError((Object e) {
                                      writeLog("downStop  ${e.toString()}");
                                      showSnackbar(
                                          message: e.toString(),
                                          type: SnackbarType.SNACKBAR_ERROR);
                                    }),
                              )
                            ],
                          ),
                        ],
                      );
                    } catch (e) {
                      return Center(child: Text('Service or characteristic not found', style: TextStyle(color: Colors.white),),);
                    }
                  } else {
                    return Container();
                  }
                },
              );
            } else
              return Container();
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Container(),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () => scaffoldKey.currentState.showBottomSheet(
              (context) => GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.black,
                  height: 200,
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      children: [
                        Text(logText, style: TextStyle(color: Colors.green))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                device.disconnect().whenComplete(() => SystemChannels.platform
                    .invokeMethod('SystemNavigator.pop'));
              }),
        ],
      ),
      body: WillPopScope(
        onWillPop: () => Future.value(false),
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    StreamBuilder<BluetoothDeviceState>(
                      stream: device.state,
                      initialData: BluetoothDeviceState.disconnected,
                      builder: (c, snapshot) {
                        if (snapshot.hasData) {
                          return Row(children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  '${device.name} is ${snapshot.data.toString().split('.')[1]}.\n${device.id}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: snapshot.data ==
                                          BluetoothDeviceState.connected
                                      ? Icon(Icons.bluetooth_connected,
                                          size: 150, color: Colors.white12)
                                      : Icon(Icons.bluetooth_disabled,
                                          size: 150, color: Colors.white),
                                ),
                              ],
                            ),
                          ]);
                        } else {
                          return Container();
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
            Expanded(flex: 4, child: isConnected ? controlArea() : Container())
          ],
        ),
      ),
    );
  }
}
