import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flutter/material.dart';

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

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Overlay Demo'),
        ),
        body: Column(
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 300.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    color: Colors.grey[200],
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                FlowyOverlay.of(context).insertCustom(
                  widget: const FlutterLogo(
                    size: 200,
                  ),
                  identifier: 'overlay_flutter_logo',
                  delegate: null,
                );
              },
              child: const Text('Show Overlay'),
            ),
            const SizedBox(height: 12.0),
            Builder(builder: (buttonContext) {
              return ElevatedButton(
                onPressed: () {
                  FlowyOverlay.of(context).insertWithAnchor(
                    widget: SizedBox(
                      width: 200,
                      height: 100,
                      child: Card(
                        color: Colors.grey[200],
                        child: GestureDetector(
                          onTapDown: (_) => print('Hello Flutter'),
                          child: const Center(child: FlutterLogo(size: 100)),
                        ),
                      ),
                    ),
                    identifier: 'overlay_card',
                    delegate: null,
                    anchorContext: buttonContext,
                    anchorDirection: AnchorDirection.topLeft,
                  );
                },
                child: const Text('Show Anchored Overlay'),
              );
            }),
            const SizedBox(height: 12.0),
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
                        onTapDown: (_) => print('Hello Flutter'),
                        child: const Center(child: FlutterLogo(size: 100)),
                      ),
                    ),
                  ),
                  identifier: 'overlay_card',
                  delegate: null,
                  anchorPosition: Offset(0, windowSize.height - 200),
                  anchorSize: Size.zero,
                  anchorDirection: AnchorDirection.topLeft,
                );
              },
              child: const Text('Show Positioned Overlay'),
            ),
          ],
        ));
  }
}
