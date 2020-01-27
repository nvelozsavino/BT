import 'dart:math';

import 'package:bt_flutter/device_screen.dart';
import 'package:bt_flutter/pulse.dart';
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
        /* Expanded(
          flex: 3,
          child: Container(
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(),
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBlue.instance.scanResults,
              initialData: [],
              builder: (context, snapshot) =>
                  snapshot.hasData && snapshot.data.length > 0
                      ? snapshot.data
                          .map((d) => ListTile(
                              title: Text(
                                'Scanning',
                                textAlign: TextAlign.center,
                              ),
                              subtitle: Text(
                                d.device.id.id,
                                textAlign: TextAlign.center,
                              )))
                          .last
                      : Container(),
            ),
          ),
        ),*/
      ]),

      /*Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black, Colors.black])),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: StreamBuilder<bool>(
                stream: FlutterBlue.instance.isScanning,
                initialData: false,
                builder: (context, snapshot) => snapshot.data
                    ? Container(
                        child: Column(children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                              constraints: BoxConstraints.expand(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5),
                              child: PulseAnimator(
                                  icon: Icons.bluetooth_searching)),
                        ),
                        StreamBuilder<List<ScanResult>>(
                          stream: FlutterBlue.instance.scanResults,
                          initialData: [],
                          builder: (context, snapshot) =>
                              snapshot.hasData && snapshot.data.length > 0
                                  ? snapshot.data
                                      .map((d) => ListTile(
                                          title: Text(
                                            'Escaneando',
                                            textAlign: TextAlign.center,
                                          ),
                                          subtitle: Text(
                                            d.device.id.id,
                                            textAlign: TextAlign.center,
                                          )))
                                      .last
                                  : Container(),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: MaterialButton(
                              color: Colors.blue,
                              onPressed: () {
                                stopScan();
                              },
                              child: Text('Stop')),
                        ),

                        /*  Positioned(
                        bottom: 1.0,
                        child: MaterialButton(
                            color: Colors.blue,
                            onPressed: () {
                              stopScan();
                            },
                            child: Text('Stop')),
                      ),*/
                      ]))
                    : MaterialButton(
                        color: Colors.blue,
                        onPressed: () => scanDevices(),
                        child: Text('Rescan')),
              ),
            ),
            /* StreamBuilder<List<BluetoothDevice>>(
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
            ),*/
            /* device != null
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
                : Container(),*/
          ],
        ),
      ),*/
    );
  }

  void scanDevices() {
    setState(() {
      _pulseColor = Colors.blue;
      _pulseIcon = Icons.bluetooth_searching;
    });
    _startAnimation();
    FlutterBlue.instance
        .startScan(timeout: Duration(seconds: 10))
        .then((value) {
      final List<ScanResult> list = value;

      list.forEach((d) {
        print(d.device.id.id);
        if (d.device.name.toLowerCase() == 'led') {
          //if (d.device.id.id == 'CE:D6:7D:19:4D:D5') {
          setState(() {
            device = d.device;
            device
                .connect()
                .then((v) => setState(() {
                      connected = true;
                      _pulseColor = Colors.greenAccent;
                      _pulseIcon = Icons.bluetooth_connected;
                    }))
                .whenComplete(() {
              Future.delayed(const Duration(seconds: 5), () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => DeviceScreen(device: device)));
              });
            });
          });
        }
      });
    }).whenComplete(() => !connected
            ? setState(() {
                _pulseColor = Colors.red;
                _pulseIcon = Icons.bluetooth_disabled;
              })
            : null);

    // .whenComplete(() => FlutterBlue.instance.stopScan());
  }

  void stopScan() async {
    await FlutterBlue.instance
        .stopScan()
        .then((v) => setState(() {
              _pulseColor = Colors.red;
              _pulseIcon = Icons.not_interested;
            }))
        .whenComplete(() {
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
