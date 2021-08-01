import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/demo_item.dart';

class OverlayItem extends DemoItem {
  @override
  String buildTitle() => 'Overlay';

  @override
  void handleTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const OverlayScreen();
        },
      ),
    );
  }
}

class OverlayDemoAnchorDirection extends ChangeNotifier {
  OverlayDemoAnchorDirection(this._anchorDirection);

  AnchorDirection _anchorDirection;

  AnchorDirection get anchorDirection => _anchorDirection;

  set anchorDirection(AnchorDirection value) {
    _anchorDirection = value;
    notifyListeners();
  }
}

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Overlay Demo'),
        ),
        body: ChangeNotifierProvider(
          create: (context) => OverlayDemoAnchorDirection(AnchorDirection.rightWithTopAligned),
          child: Builder(builder: (providerContext) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48.0),
                    ElevatedButton(
                      onPressed: () {
                        final windowSize = MediaQuery.of(context).size;
                        FlowyOverlay.of(context).insertCustom(
                          widget: Positioned(
                            left: windowSize.width / 2.0 - 100,
                            top: 200,
                            child: SizedBox(
                              width: 200,
                              height: 100,
                              child: Card(
                                color: Colors.green[200],
                                child: GestureDetector(
                                  // ignore: avoid_print
                                  onTapDown: (_) => print('Hello Flutter'),
                                  child: const Center(child: FlutterLogo(size: 100)),
                                ),
                              ),
                            ),
                          ),
                          identifier: 'overlay_flutter_logo',
                          delegate: null,
                        );
                      },
                      child: const Text('Show Overlay'),
                    ),
                    const SizedBox(height: 24.0),
                    DropdownButton<AnchorDirection>(
                      value: providerContext.watch<OverlayDemoAnchorDirection>().anchorDirection,
                      onChanged: (AnchorDirection? newValue) {
                        if (newValue != null) {
                          providerContext.read<OverlayDemoAnchorDirection>().anchorDirection = newValue;
                        }
                      },
                      items: AnchorDirection.values.map((AnchorDirection classType) {
                        return DropdownMenuItem<AnchorDirection>(value: classType, child: Text(classType.toString()));
                      }).toList(),
                    ),
                    const SizedBox(height: 24.0),
                    Builder(builder: (buttonContext) {
                      return SizedBox(
                        height: 100,
                        child: ElevatedButton(
                          onPressed: () {
                            FlowyOverlay.of(context).insertWithAnchor(
                              widget: SizedBox(
                                width: 100,
                                height: 50,
                                child: Card(
                                  color: Colors.grey[200],
                                  child: GestureDetector(
                                    // ignore: avoid_print
                                    onTapDown: (_) => print('Hello Flutter'),
                                    child: const Center(child: FlutterLogo(size: 50)),
                                  ),
                                ),
                              ),
                              identifier: 'overlay_anchored_card',
                              delegate: null,
                              anchorContext: buttonContext,
                              anchorDirection: providerContext.read<OverlayDemoAnchorDirection>().anchorDirection,
                            );
                          },
                          child: const Text('Show Anchored Overlay'),
                        ),
                      );
                    }),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: () {
                        final windowSize = MediaQuery.of(context).size;
                        FlowyOverlay.of(context).insertWithRect(
                          widget: SizedBox(
                            width: 200,
                            height: 100,
                            child: Card(
                              color: Colors.orange[200],
                              child: GestureDetector(
                                // ignore: avoid_print
                                onTapDown: (_) => print('Hello Flutter'),
                                child: const Center(child: FlutterLogo(size: 100)),
                              ),
                            ),
                          ),
                          identifier: 'overlay_positioned_card',
                          delegate: null,
                          anchorPosition: Offset(0, windowSize.height - 200),
                          anchorSize: Size.zero,
                          anchorDirection: providerContext.read<OverlayDemoAnchorDirection>().anchorDirection,
                        );
                      },
                      child: const Text('Show Positioned Overlay'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ));
  }
}
