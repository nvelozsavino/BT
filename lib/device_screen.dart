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
  Guid serviceGuid = Guid('0000FFF0-4265-2055-6e6c-696d69746564');
  Guid characteristicGuid = Guid('0000FFF1-4265-2055-6e6c-696d69746564');

  bool upPressed;
  bool downPressed;
  Timer timer;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void writeLog(String message) {
    Log.instance.writeLog("Device Screen : $message");
    print(message);
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
      upPressed = false;
      downPressed = false;
      timer = null;
    });
    readState();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    device.disconnect();
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
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
              const oneSec = const Duration(milliseconds:100);
              timer = new Timer.periodic(oneSec, (Timer t) {
                if (upPressed) {
                  c.write(upStart()).then((v) {
                    writeLog("upStart write ${v.toString()}");
                  });
                }
                print('hi!');
                if (downPressed) {
                  c.write(downStart()).then((v) {
                    writeLog("upDown write ${v.toString()}");
                  });
                }
              });
              await c.setNotifyValue(true).whenComplete(() {
                c.value.listen((v) {
                  if (v.isNotEmpty) {
                    writeLog("Se recibió ${v.toString()}");
//                    if (v.contains(0)) {
//                      showSnackbar(
//                          message: 'Success',
//                          type: SnackbarType.SNACKBAR_SUCCESS);
//                    } else {
//                      showSnackbar(
//                          message: 'Code error: $v',
//                          type: SnackbarType.SNACKBAR_ERROR);
//                    }
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
    return [0x90];
  }

  List<int> upStop() {
    writeLog('upStop write ${[0x90]}');
    return [0xff];
  }

  List<int> downStop() {
    writeLog('downStop write ${[0x91]}');
    return [0xff];
  }

  void upPress(BluetoothCharacteristic cc) {
    print(515454);
    while (upPressed) {
      cc
          .write(upStart())
          .timeout(Duration(seconds: 1), onTimeout: () async {
            showSnackbar(message: "Timeout", type: SnackbarType.SNACKBAR_ERROR);
          })
          .then((v) {
            writeLog("upStart write ${v.toString()}");
          })
          .whenComplete(() => writeLog("downStart completed"))
          .catchError((Object e) {
            writeLog("upStart  ${e.toString()}");
            showSnackbar(
                message: e.toString(), type: SnackbarType.SNACKBAR_ERROR);
          });
    }
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
                                        onUpPress: (_) {
                                          setState(() {
                                            upPressed = true;
                                          });
                                        },
                                        onUpRelease: (_) {
                                          setState(() {
                                            upPressed = false;
                                          });
                                        },
                                        onDownPress: (_) {
                                          setState(() {
                                            downPressed = true;
                                          });
                                        },
                                        onDownRelease: (_) {
                                          setState(() {
                                            downPressed = false;
                                          });
                                        })),
                              ],
                            ),
                          ]);
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
