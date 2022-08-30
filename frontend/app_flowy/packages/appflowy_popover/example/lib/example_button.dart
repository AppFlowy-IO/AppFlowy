import 'package:flutter/material.dart';
import 'package:appflowy_popover/popover.dart';

class PopoverMenu extends StatefulWidget {
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
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topLeft,
          popupBuilder: (BuildContext context) {
            return PopoverMenu();
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
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topLeft,
          popupBuilder: (BuildContext context) {
            return PopoverMenu();
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
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset? offset;

  const ExampleButton({
    Key? key,
    required this.label,
    this.targetAnchor = Alignment.topLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = Offset.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Popover(
      targetAnchor: targetAnchor,
      followerAnchor: followerAnchor,
      triggerActions: PopoverTriggerActionFlags.click,
      offset: offset,
      child: TextButton(child: Text(label), onPressed: () {}),
      popupBuilder: (BuildContext context) {
        return PopoverMenu();
      },
    );
  }
}
