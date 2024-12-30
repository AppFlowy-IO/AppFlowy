import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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

class OverlayDemoConfiguration extends ChangeNotifier {
  OverlayDemoConfiguration(this._anchorDirection, this._overlapBehaviour);

  AnchorDirection _anchorDirection;

  AnchorDirection get anchorDirection => _anchorDirection;

  set anchorDirection(AnchorDirection value) {
    _anchorDirection = value;
    notifyListeners();
  }

  OverlapBehaviour _overlapBehaviour;

  OverlapBehaviour get overlapBehaviour => _overlapBehaviour;

  set overlapBehaviour(OverlapBehaviour value) {
    _overlapBehaviour = value;
    notifyListeners();
  }
}

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overlay Demo'),
      ),
      body: ChangeNotifierProvider(
        create: (context) => OverlayDemoConfiguration(
            AnchorDirection.rightWithTopAligned, OverlapBehaviour.stretch),
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
                                child:
                                    const Center(child: FlutterLogo(size: 100)),
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
                    value: providerContext
                        .watch<OverlayDemoConfiguration>()
                        .anchorDirection,
                    onChanged: (AnchorDirection? newValue) {
                      if (newValue != null) {
                        providerContext
                            .read<OverlayDemoConfiguration>()
                            .anchorDirection = newValue;
                      }
                    },
                    items:
                        AnchorDirection.values.map((AnchorDirection classType) {
                      return DropdownMenuItem<AnchorDirection>(
                          value: classType, child: Text(classType.toString()));
                    }).toList(),
                  ),
                  const SizedBox(height: 24.0),
                  DropdownButton<OverlapBehaviour>(
                    value: providerContext
                        .watch<OverlayDemoConfiguration>()
                        .overlapBehaviour,
                    onChanged: (OverlapBehaviour? newValue) {
                      if (newValue != null) {
                        providerContext
                            .read<OverlayDemoConfiguration>()
                            .overlapBehaviour = newValue;
                      }
                    },
                    items: OverlapBehaviour.values
                        .map((OverlapBehaviour classType) {
                      return DropdownMenuItem<OverlapBehaviour>(
                          value: classType, child: Text(classType.toString()));
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
                              width: 300,
                              height: 50,
                              child: Card(
                                color: Colors.grey[200],
                                child: GestureDetector(
                                  // ignore: avoid_print
                                  onTapDown: (_) => print('Hello Flutter'),
                                  child: const Center(
                                      child: FlutterLogo(size: 50)),
                                ),
                              ),
                            ),
                            identifier: 'overlay_anchored_card',
                            delegate: null,
                            anchorContext: buttonContext,
                            anchorDirection: providerContext
                                .read<OverlayDemoConfiguration>()
                                .anchorDirection,
                            overlapBehaviour: providerContext
                                .read<OverlayDemoConfiguration>()
                                .overlapBehaviour,
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
                              onTapDown: (_) => debugPrint('Hello Flutter'),
                              child:
                                  const Center(child: FlutterLogo(size: 100)),
                            ),
                          ),
                        ),
                        identifier: 'overlay_positioned_card',
                        delegate: null,
                        anchorPosition: Offset(0, windowSize.height - 200),
                        anchorSize: Size.zero,
                        anchorDirection: providerContext
                            .read<OverlayDemoConfiguration>()
                            .anchorDirection,
                        overlapBehaviour: providerContext
                            .read<OverlayDemoConfiguration>()
                            .overlapBehaviour,
                      );
                    },
                    child: const Text('Show Positioned Overlay'),
                  ),
                  const SizedBox(height: 24.0),
                  Builder(builder: (buttonContext) {
                    return ElevatedButton(
                      onPressed: () {
                        ListOverlay.showWithAnchor(
                          context,
                          itemBuilder: (_, index) => Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 12.0),
                            elevation: 0,
                            child: Text(
                              'Option $index',
                              style: const TextStyle(
                                  fontSize: 20.0, color: Colors.black),
                            ),
                          ),
                          itemCount: 10,
                          identifier: 'overlay_list_menu',
                          anchorContext: buttonContext,
                          anchorDirection: providerContext
                              .read<OverlayDemoConfiguration>()
                              .anchorDirection,
                          overlapBehaviour: providerContext
                              .read<OverlayDemoConfiguration>()
                              .overlapBehaviour,
                          constraints:
                              BoxConstraints.tight(const Size(200, 200)),
                        );
                      },
                      child: const Text('Show List Overlay'),
                    );
                  }),
                  const SizedBox(height: 24.0),
                  Builder(builder: (buttonContext) {
                    return ElevatedButton(
                      onPressed: () {
                        OptionOverlay.showWithAnchor(
                          context,
                          items: <String>[
                            'Alpha',
                            'Beta',
                            'Charlie',
                            'Delta',
                            'Echo',
                            'Foxtrot',
                            'Golf',
                            'Hotel'
                          ],
                          onHover: (value, index) => debugPrint(
                              'Did hover option $index, value $value'),
                          onTap: (value, index) =>
                              debugPrint('Did tap option $index, value $value'),
                          identifier: 'overlay_options',
                          anchorContext: buttonContext,
                          anchorDirection: providerContext
                              .read<OverlayDemoConfiguration>()
                              .anchorDirection,
                          overlapBehaviour: providerContext
                              .read<OverlayDemoConfiguration>()
                              .overlapBehaviour,
                        );
                      },
                      child: const Text('Show Options Overlay'),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
