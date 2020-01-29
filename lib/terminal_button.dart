import 'package:flutter/material.dart';

class TerminalButton extends StatefulWidget {
  final GestureTapDownCallback onTapDown;
  final GestureTapUpCallback onTapUp;
  final IconData icon;
  final Color color;

  TerminalButton({this.onTapDown, this.onTapUp, this.icon, this.color});

  @override
  _TerminalButtonState createState() => _TerminalButtonState();
}

class _TerminalButtonState extends State<TerminalButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTapDown,
      onTapUp: widget.onTapUp,
//      borderRadius: BorderRadius.circular(10.0),
      child: Center(
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: 80,
        ),
      ),
    );
  }

  void pressed() {
//    widget.onTapDown();
  }
}
