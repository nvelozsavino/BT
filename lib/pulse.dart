import 'package:flutter/material.dart';

class PulseAnimator extends StatefulWidget {
  final IconData icon;

  const PulseAnimator({Key key, this.icon}) : super(key: key);
  @override
  _PulseAnimatorState createState() => _PulseAnimatorState(icon);
}

class _PulseAnimatorState extends State<PulseAnimator>
    with SingleTickerProviderStateMixin {
  final IconData icon;
  AnimationController controller;

  _PulseAnimatorState(this.icon);

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      lowerBound: 0.5,
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  Widget _buildContainer(double radius) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withOpacity(1 - controller.value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            _buildContainer(150 * controller.value),
            _buildContainer(200 * controller.value),
            _buildContainer(250 * controller.value),
            _buildContainer(300 * controller.value),
            _buildContainer(350 * controller.value),
            Align(
                child: Icon(
              icon,
              color: Colors.white,
              size: 50,
            )),
          ],
        );
      },
    );
  }
}
