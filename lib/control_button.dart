import 'package:bt_flutter/terminal_button.dart';
import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final IconData upIcon;
  final IconData downIcon;

  ControlButtons(
      {this.onIncrement,
      this.onDecrement,
      this.upIcon = Icons.add,
      this.downIcon = Icons.remove});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ClipOval(
          child: Container(
            width: 80,
            height: 80,
            child: TerminalButton(
              icon: upIcon,
              onPressed: onDecrement,
            ),
          ),
        ),
        SizedBox(
          width: 16,
        ),
        ClipOval(
          child: Container(
            width: 100,
            height: 100,
            child: TerminalButton(
              icon: downIcon,
              onPressed: onDecrement,
            ),
          ),
        ),
      ],
    );
  }
}
