import 'package:flutter/material.dart';
import 'package:appflowy_popover/popover.dart';

class PopoverMenu extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PopoverMenuState();
}

class _PopoverMenuState extends State<PopoverMenu> {
  final PopoverExclusive exclusive = PopoverExclusive();
  late PopoverController firstPopover;
  late PopoverController secondPopover;

  @override
  void initState() {
    firstPopover = PopoverController(exclusive: exclusive);
    secondPopover = PopoverController(exclusive: exclusive);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: const BoxDecoration(color: Colors.yellow),
      child: ListView(children: [
        const Text("App"),
        Popover(
          controller: firstPopover,
          offset: const Offset(10, 0),
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topLeft,
          popupBuilder: (BuildContext context) {
            return PopoverMenu();
          },
          child: TextButton(
            onPressed: () {
              firstPopover.show();
            },
            onHover: (value) {
              if (value) {
                firstPopover.show();
              }
            },
            child: const Text("First"),
          ),
        ),
        Popover(
          controller: secondPopover,
          offset: const Offset(10, 0),
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topLeft,
          popupBuilder: (BuildContext context) {
            return PopoverMenu();
          },
          child: TextButton(
            onPressed: () {
              secondPopover.show();
            },
            onHover: (value) {
              if (value) {
                secondPopover.show();
              }
            },
            child: const Text("Second"),
          ),
        ),
      ]),
    );
  }
}

class ExampleButton extends StatelessWidget {
  final PopoverController _popover = PopoverController();

  final String label;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset? offset;

  ExampleButton({
    Key? key,
    required this.label,
    this.targetAnchor = Alignment.topLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = Offset.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Popover(
      controller: _popover,
      targetAnchor: targetAnchor,
      followerAnchor: followerAnchor,
      offset: offset,
      child: TextButton(
        onPressed: (() {
          _popover.show();
        }),
        child: Text(label),
      ),
      popupBuilder: (BuildContext context) {
        return PopoverMenu();
      },
    );
  }
}
