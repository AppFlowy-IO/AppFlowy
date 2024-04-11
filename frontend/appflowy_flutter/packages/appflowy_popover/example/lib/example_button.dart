import 'package:flutter/material.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

class PopoverMenu extends StatefulWidget {
  const PopoverMenu({super.key});

  @override
  State<StatefulWidget> createState() => _PopoverMenuState();
}

class _PopoverMenuState extends State<PopoverMenu> {
  final PopoverMutex popOverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return Material(
        type: MaterialType.transparency,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: ListView(children: [
            Container(
              margin: const EdgeInsets.all(8),
              child: const Text("Popover",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontStyle: null,
                      decoration: null)),
            ),
            Popover(
              triggerActions:
                  PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
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
                  PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
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
        ));
  }
}

class ExampleButton extends StatelessWidget {
  final String label;
  final Offset? offset;
  final PopoverDirection? direction;

  const ExampleButton({
    super.key,
    required this.label,
    this.direction,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Popover(
      triggerActions: PopoverTriggerFlags.click,
      offset: offset,
      direction: direction ?? PopoverDirection.rightWithTopAligned,
      child: TextButton(child: Text(label), onPressed: () {}),
      popupBuilder: (BuildContext context) {
        return const PopoverMenu();
      },
    );
  }
}
