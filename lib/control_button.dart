import 'package:bt_flutter/terminal_button.dart';
import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final IconData upIcon;
  final IconData downIcon;
  final Color color;

  ControlButtons(
      {this.onIncrement,
      this.onDecrement,
      this.upIcon = Icons.add,
      this.downIcon = Icons.remove,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width * 0.4,
          height: MediaQuery.of(context).size.width * 0.4,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0, // has the effect of softening the shadow
                spreadRadius: 5,
                //offset: Offset(0, 0), // has the effect of extending the shadow
              )
            ],
            color: color,
            shape: BoxShape.circle,
            border: new Border.all(
              color: Colors.white12,
              width: 10,
            ),
          ),
          child: TerminalButton(
              color: color, icon: upIcon, onPressed: onIncrement),
        ),
        SizedBox(
          height: 100,
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.4,
          height: MediaQuery.of(context).size.width * 0.4,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0, // has the effect of softening the shadow
                spreadRadius: 5,
                offset: Offset(0, 0), // has the effect of extending the shadow
              )
            ],
            color: color,
            shape: BoxShape.circle,
            border: new Border.all(
              color: Colors.white12,
              width: 10,
            ),
          ),
          child: TerminalButton(
              color: color, icon: downIcon, onPressed: onDecrement),
        ),
      ],
    );
  }
}
