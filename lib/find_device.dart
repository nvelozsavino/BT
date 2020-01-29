import 'dart:async';
import 'dart:math';

import 'package:bt_flutter/device_screen.dart';
import 'package:bt_flutter/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';

class FindDeviceScreen extends StatefulWidget {
  FindDeviceScreen({Key key}) : super(key: key);

  @override
  _FindDeviceScreenState createState() => _FindDeviceScreenState();
}

class _FindDeviceScreenState extends State<FindDeviceScreen>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  BluetoothDevice device;
  Color _pulseColor;
  IconData _pulseIcon;
  bool connected;
  StreamSubscription scanSubscription;

  @override
  void initState() {
    _pulseColor = Colors.blue;
    connected = false;
    _pulseIcon = Icons.bluetooth_searching;
    _controller = new AnimationController(
      vsync: this,
    );

    scanDevices();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    scanSubscription.cancel();
    super.dispose();
  }

  void _startAnimation() {
    if (_controller != null) {
      _controller.stop();
      _controller.reset();
      _controller.repeat(
        period: Duration(seconds: 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xff232526),
        elevation: 0,
      ),
      body: Column(children: <Widget>[
        Expanded(
          flex: 7,
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: FractionalOffset.bottomCenter,
                colors: [Color(0xff232526), Color(0xff414345)],
                tileMode: TileMode.clamp,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 8,
                  child: CustomPaint(
                    painter: SpritePainter(_controller, _pulseColor),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.width * 0.9,
                      child: Icon(
                        _pulseIcon,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.1,
                      ),
                    ),
                  ),
                ),
                connected
                    ? Column(children: [
                        Text(
                          'Connecting',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        LinearProgressIndicator(
                          backgroundColor: Colors.white24,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                        )
                      ])
                    : StreamBuilder<bool>(
                        stream: FlutterBlue.instance.isScanning,
                        initialData: false,
                        builder: (context, snapshot) => snapshot.data
                            ? FlatButton(
                                shape: StadiumBorder(
                                  side: BorderSide(
                                      color: Colors.grey.withAlpha(400)),
                                ),
                                textColor: Colors.white,
                                onPressed: () {
                                  stopScan();
                                },
                                child: Text('Stop'))
                            : Column(
                                children: [
                                  Text(
                                    'Device not found',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  FlatButton(
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                          color: Colors.grey.withAlpha(400)),
                                    ),
                                    textColor: Colors.white,
                                    onPressed: () => scanDevices(),
                                    child: Text('Retry'),
                                  ),
                                ],
                              ),
                      ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void scanDevices() {
    setState(() {
      _pulseColor = Colors.blue;
      _pulseIcon = Icons.bluetooth_searching;
    });
    _startAnimation();
    FlutterBlue flutterBlue = FlutterBlue.instance;

    flutterBlue.startScan(timeout: Duration(seconds: 10)).whenComplete(
      () {
        scanSubscription.cancel();
        if (!connected) {
          Log.instance.writeLog("Device not found");
          setState(() {
            _pulseColor = Colors.red;
            _pulseIcon = Icons.bluetooth_disabled;
          });
        }
      },
    );
    scanSubscription = flutterBlue.scanResults.listen((scanResult) {
      final List<ScanResult> list = scanResult;

      list.forEach((d) {
        if (d.device.name.toLowerCase() == 'led') {
          Log.instance.writeLog("${d.device.name} founded ");
          setState(() {
            device = d.device;
            flutterBlue.stopScan();

            device.connect().then((v) {
              Log.instance.writeLog("${d.device.name} connecting");
              setState(() {
                connected = true;
                _pulseColor = Colors.greenAccent;
                _pulseIcon = Icons.bluetooth_connected;
              });
            }).whenComplete(() {
              Log.instance.writeLog("${d.device.name} connected");
              Future.delayed(const Duration(seconds: 2), () {
                Log.instance.writeLog("Redirect to device screen");
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => DeviceScreen(device: device)));
              });
            });
            return;
          });
        }
      });
    });
  }

  void stopScan() async {
    await FlutterBlue.instance.stopScan().then((v) {
      Log.instance.writeLog("Stopping scan");
      setState(() {
        _pulseColor = Colors.red;
        _pulseIcon = Icons.not_interested;
      });
    }).whenComplete(() {
      Log.instance.writeLog("Scan stopped");
      _controller.stop();
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    });
  }
}

class SpritePainter extends CustomPainter {
  final Animation<double> _animation;
  final Color _color;

  SpritePainter(this._animation, this._color) : super(repaint: _animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 4.0)).clamp(0.0, 1.0);
    Color color = _color.withOpacity(opacity);

    double size = rect.width / 2;
    double area = size * size;
    double radius = sqrt(area * value / 4);

    final Paint paint = new Paint()..color = color;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = new Rect.fromLTRB(0.0, 0.0, size.width, size.height);

    for (int wave = 3; wave >= 0; wave--) {
      circle(canvas, rect, wave + _animation.value);
    }
  }

  @override
  bool shouldRepaint(SpritePainter oldDelegate) {
    return true;
  }
}
