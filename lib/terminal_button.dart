import 'package:flutter/material.dart';

class TerminalButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  TerminalButton({this.onPressed, this.icon, this.color});

  @override
  _TerminalButtonState createState() => _TerminalButtonState();
}

class _TerminalButtonState extends State<TerminalButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onPressed,
      borderRadius: BorderRadius.circular(10.0),
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
    widget.onPressed();
  }
}
