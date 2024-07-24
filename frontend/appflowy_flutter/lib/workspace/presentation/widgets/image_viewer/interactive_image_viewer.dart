import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_toolbar.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:provider/provider.dart';

const double _minScaleFactor = .5;
const double _maxScaleFactor = 5;

class InteractiveImageViewer extends StatefulWidget {
  const InteractiveImageViewer({
    super.key,
    this.userProfile,
    required this.imageProvider,
  });

  final UserProfilePB? userProfile;
  final AFImageProvider imageProvider;

  @override
  State<InteractiveImageViewer> createState() => _InteractiveImageViewerState();
}

class _InteractiveImageViewerState extends State<InteractiveImageViewer> {
  final TransformationController controller = TransformationController();
  final focusNode = FocusNode();

  int currentScale = 100;
  late int currentIndex = widget.imageProvider.initialIndex;

  bool get isLastIndex => currentIndex == widget.imageProvider.imageCount - 1;
  bool get isFirstIndex => currentIndex == 0;

  late ImageBlockData currentImage;

  UserProfilePB? userProfile;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    currentImage = widget.imageProvider.getImage(currentIndex);
    userProfile =
        widget.userProfile ?? context.read<DocumentBloc>().state.userProfilePB;
  }

  void _onControllerChanged() {
    final scale = controller.value.getMaxScaleOnAxis();
    final percentage = (scale * 100).toInt();
    setState(() => currentScale = percentage);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) {
          return;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _move(-1);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _move(1);
        } else if ([
          LogicalKeyboardKey.add,
          LogicalKeyboardKey.numpadAdd,
        ].contains(event.logicalKey)) {
          _zoom(1.1, size);
        } else if ([
          LogicalKeyboardKey.minus,
          LogicalKeyboardKey.numpadSubtract,
        ].contains(event.logicalKey)) {
          _zoom(.9, size);
        } else if ([
          LogicalKeyboardKey.numpad0,
          LogicalKeyboardKey.digit0,
        ].contains(event.logicalKey)) {
          controller.value = Matrix4.identity();
          _onControllerChanged();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox.expand(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(double.infinity),
              transformationController: controller,
              constrained: false,
              minScale: _minScaleFactor,
              maxScale: _maxScaleFactor,
              scaleFactor: 500,
              child: SizedBox(
                height: size.height,
                width: size.width,
                child: widget.imageProvider.renderImage(
                  context,
                  currentIndex,
                  userProfile,
                ),
              ),
            ),
          ),
          InteractiveImageToolbar(
            currentImage: currentImage,
            imageCount: widget.imageProvider.imageCount,
            isFirstIndex: isFirstIndex,
            isLastIndex: isLastIndex,
            currentScale: currentScale,
            userProfile: userProfile,
            onPrevious: () => _move(-1),
            onNext: () => _move(1),
            onZoomIn: () => _zoom(1.1, size),
            onZoomOut: () => _zoom(.9, size),
          ),
        ],
      ),
    );
  }

  void _move(int steps) {
    setState(() {
      final index = currentIndex + steps;
      currentIndex = index.clamp(0, widget.imageProvider.imageCount - 1);
      currentImage = widget.imageProvider.getImage(currentIndex);
    });
  }

  void _zoom(double scaleStep, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scenePointBefore = controller.toScene(center);
    final currentScale = controller.value.getMaxScaleOnAxis();
    final newScale = (currentScale * scaleStep).clamp(
      _minScaleFactor,
      _maxScaleFactor,
    );

    // Create a new transformation
    final newMatrix = Matrix4.identity()
      ..translate(scenePointBefore.dx, scenePointBefore.dy)
      ..scale(newScale / currentScale)
      ..translate(-scenePointBefore.dx, -scenePointBefore.dy);

    // Apply the new transformation
    controller.value = newMatrix * controller.value;

    // Convert the center point to scene coordinates after scaling
    final scenePointAfter = controller.toScene(center);

    // Compute difference to keep the same center point
    final dx = scenePointAfter.dx - scenePointBefore.dx;
    final dy = scenePointAfter.dy - scenePointBefore.dy;

    // Apply the translation
    controller.value = Matrix4.identity()
      ..translate(-dx, -dy)
      ..multiply(controller.value);

    _onControllerChanged();
  }
}
