import 'package:flutter/material.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

class PopoverMenu extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PopoverMenuState();
}

class _PopoverMenuState extends State<PopoverMenu> {
  final AppFlowyPopoverController popover = AppFlowyPopoverController();
  final AppFlowyPopoverController hoverPopover = AppFlowyPopoverController();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: const BoxDecoration(color: Colors.yellow),
      child: ListView(children: [
        const Text("App"),
        AppFlowyPopover(
          controller: popover,
          offset: const Offset(10, 0),
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topLeft,
          popupBuilder: (BuildContext context) {
            return PopoverMenu();
          },
          child: TextButton(
            onPressed: () {
              popover.show();
            },
            onHover: (value) {
              if (value) {
                popover.show();
              } else {
                popover.close();
              }
            },
            child: const Text("First"),
          ),
        ),
        AppFlowyPopover(
          controller: hoverPopover,
          offset: const Offset(10, 0),
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topLeft,
          popupBuilder: (BuildContext context) {
            return PopoverMenu();
          },
          child: TextButton(
            onPressed: () {
              hoverPopover.show();
            },
            onHover: (value) {
              if (value) {
                hoverPopover.show();
              } else {
                hoverPopover.close();
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
  final AppFlowyPopoverController _popover = AppFlowyPopoverController();

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
    return AppFlowyPopover(
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
