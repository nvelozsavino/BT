import 'dart:async';
import 'package:bt_flutter/terminal.dart';
import 'package:bt_flutter/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

enum SnackbarType { SNACKBAR_ERROR, SNACKBAR_SUCCESS }

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({Key key, this.device}) : super(key: key);
  @override
  _DeviceScreenState createState() => _DeviceScreenState(device);
}

class _DeviceScreenState extends State<DeviceScreen> {
  final BluetoothDevice device;
  _DeviceScreenState(this.device);

  bool isConnected;
  Guid serviceGuid = Guid('19b10000-e8f2-537e-4f6c-d104768a1214');
  Guid characteristicGuid = Guid('19b10001-e8f2-537e-4f6c-d104768a1214');

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void writeLog(String message) {
    Log.instance.writeLog("Device Screen : $message");
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
        writeLog("Scan service ${ser.uuid.toString()}");
        if (ser.uuid == serviceGuid) {
          writeLog(
              "Service founded ${'0x${ser.uuid.toString().toUpperCase().substring(4, 8)}'}");
          ser.characteristics.forEach((c) async {
            writeLog("Scan characteristic ${c.uuid.toString()}");
            if (c.uuid == characteristicGuid) {
              writeLog(
                  "Characteristic founded ${'0x${c.uuid.toString().toUpperCase().substring(4, 8)}'}");
              setState(() {
                isConnected = true;
              });

              await c.setNotifyValue(true).whenComplete(() {
                c.value.listen((v) {
                  if (v.isNotEmpty) {
                    writeLog("Se recibió ${v.toString()}");
                    if (v.contains(0)) {
                      showSnackbar(
                          message: 'Success',
                          type: SnackbarType.SNACKBAR_SUCCESS);
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

  List<int> upStart() {
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
  }

  List<int> downStop() {
    writeLog('downStop write ${[0x91]}');
    return [0x91];
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
                                      .write(downStart())
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
                                    .catchError(
                                      (Object e) {
                                        writeLog("downStop  ${e.toString()}");
                                        showSnackbar(
                                            message: e.toString(),
                                            type: SnackbarType.SNACKBAR_ERROR);
                                      },
                                    ),
                              )
                            ],
                          ),
                        ],
                      );
                    } catch (e) {
                      writeLog("Catch error ${e.toString()}");
                      return Center(
                        child: Text(
                          'Service or characteristic not found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
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
              onPressed: () async => await FlutterEmailSender.send(
                    Email(
                      body: Log.instance.getLogs(),
                      subject: 'BT Log',
                      recipients: ['eduardoasolanog@gmail.com'],
                      isHTML: false,
                    ),
                  )),
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
