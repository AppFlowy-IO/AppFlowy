import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';

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
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.all(8),
              child: const Text(
                'Popover',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            Popover(
              triggerActions:
                  PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
              mutex: popOverMutex,
              offset: const Offset(10, 0),
              asBarrier: true,
              debugId: 'First',
              popupBuilder: (BuildContext context) {
                return const PopoverMenu();
              },
              child: TextButton(
                onPressed: () {},
                child: const Text('First'),
              ),
            ),
            Popover(
              triggerActions:
                  PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
              mutex: popOverMutex,
              asBarrier: true,
              debugId: 'Second',
              offset: const Offset(10, 0),
              popupBuilder: (BuildContext context) {
                return const PopoverMenu();
              },
              child: TextButton(
                onPressed: () {},
                child: const Text('Second'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExampleButton extends StatelessWidget {
  const ExampleButton({
    super.key,
    required this.label,
    required this.direction,
    this.offset = Offset.zero,
  });

  final String label;
  final Offset? offset;
  final PopoverDirection direction;

  @override
  Widget build(BuildContext context) {
    return Popover(
      triggerActions: PopoverTriggerFlags.click,
      animationDuration: Durations.medium1,
      offset: offset,
      direction: direction,
      debugId: label,
      child: TextButton(
        child: Text(label),
        onPressed: () {},
      ),
      popupBuilder: (BuildContext context) {
        return const PopoverMenu();
      },
    );
  }
}
