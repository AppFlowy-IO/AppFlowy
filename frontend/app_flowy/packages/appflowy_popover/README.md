<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# AppFlowy Popover

A Popover can be used to display some content on top of another.

## Features

> A popover is a transient view that appears above other content onscreen when you tap a control or in an area. Typically, a popover includes an arrow pointing to the location from which it emerged. Popovers can be nonmodal or modal. A nonmodal popover is dismissed by tapping another part of the screen or a button on the popover. A modal popover is dismissed by tapping a Cancel or other button on the popover.

Source: [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/views/popovers/).

- Basic popover style
- Nested popover support
- Exclusive popover API

## Example

```dart
Popover(
  triggerActions: PopoverTriggerActionFlags.click,
  child: TextButton(child: Text("Popover"), onPressed: () {}),
  popupBuilder(BuildContext context) {
    return PopoverMenu();
  },
);
```
