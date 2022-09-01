import 'package:flutter/material.dart';
import 'package:appflowy_popover/popover.dart';

class PopoverMenu extends StatefulWidget {
  const PopoverMenu({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PopoverMenuState();
}

class _PopoverMenuState extends State<PopoverMenu> {
  final PopoverMutex popOverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: const BoxDecoration(color: Colors.yellow),
      child: ListView(children: [
        const Text("App"),
        Popover(
          triggerActions:
              PopoverTriggerActionFlags.hover | PopoverTriggerActionFlags.click,
          mutex: popOverMutex,
          offset: const Offset(10, 0),
          popupBuilder: (BuildContext context) {
            return const PopoverMenu();
          },
          child: TextButton(
            onPressed: () {},
            child: const Text("First"),
          ),
        ),
        Popover(
          triggerActions:
              PopoverTriggerActionFlags.hover | PopoverTriggerActionFlags.click,
          mutex: popOverMutex,
          offset: const Offset(10, 0),
          popupBuilder: (BuildContext context) {
            return const PopoverMenu();
          },
          child: TextButton(
            onPressed: () {},
            child: const Text("Second"),
          ),
        ),
      ]),
    );
  }
}

class ExampleButton extends StatelessWidget {
  final String label;
  final Offset? offset;
  final PopoverDirection? direction;

  const ExampleButton({
    Key? key,
    required this.label,
    this.direction,
    this.offset = Offset.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Popover(
      triggerActions: PopoverTriggerActionFlags.click,
      offset: offset,
      direction: direction ?? PopoverDirection.rightWithTopAligned,
      child: TextButton(child: Text(label), onPressed: () {}),
      popupBuilder: (BuildContext context) {
        return const PopoverMenu();
      },
    );
  }
}
