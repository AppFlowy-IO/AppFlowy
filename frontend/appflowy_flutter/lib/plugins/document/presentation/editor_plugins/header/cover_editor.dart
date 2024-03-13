import 'dart:io';
import 'dart:ui';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String kLocalImagesKey = 'local_images';

List<String> get builtInAssetImages => [
      "assets/images/app_flowy_abstract_cover_1.jpg",
      "assets/images/app_flowy_abstract_cover_2.jpg",
    ];

class ChangeCoverPopover extends StatefulWidget {
  const ChangeCoverPopover({
    super.key,
    required this.editorState,
    required this.node,
    required this.onCoverChanged,
  });

  final EditorState editorState;
  final Node node;
  final Function(
    CoverType selectionType,
    String selection,
  ) onCoverChanged;

  @override
  State<ChangeCoverPopover> createState() => _ChangeCoverPopoverState();
}

class _ChangeCoverPopoverState extends State<ChangeCoverPopover> {
  bool isAddingImage = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChangeCoverPopoverBloc(
        editorState: widget.editorState,
        node: widget.node,
      )..add(const ChangeCoverPopoverEvent.fetchPickedImagePaths()),
      child: BlocConsumer<ChangeCoverPopoverBloc, ChangeCoverPopoverState>(
        listener: (context, state) {
          if (state is Loaded && state.selectLatestImage) {
            widget.onCoverChanged(
              CoverType.file,
              state.imageNames.last,
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: isAddingImage
                  ? CoverImagePicker(
                      onBackPressed: () => setState(() {
                        isAddingImage = false;
                      }),
                      onFileSubmit: (_) {
                        context.read<ChangeCoverPopoverBloc>().add(
                              const ChangeCoverPopoverEvent
                                  .fetchPickedImagePaths(
                                selectLatestImage: true,
                              ),
                            );

                        setState(() => isAddingImage = false);
                      },
                    )
                  : _buildCoverSelection(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoverSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.semibold(
          LocaleKeys.document_plugins_cover_colors.tr(),
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const VSpace(10),
        _buildColorPickerList(),
        const VSpace(10),
        _buildImageHeader(),
        const VSpace(10),
        _buildFileImagePicker(),
        const VSpace(10),
        FlowyText.semibold(
          LocaleKeys.document_plugins_cover_abstract.tr(),
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const VSpace(10),
        _buildAbstractImagePicker(),
      ],
    );
  }

  Widget _buildImageHeader() {
    return BlocBuilder<ChangeCoverPopoverBloc, ChangeCoverPopoverState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FlowyText.semibold(
              LocaleKeys.document_plugins_cover_images.tr(),
              color: Theme.of(context).colorScheme.tertiary,
            ),
            FlowyTextButton(
              fillColor: Theme.of(context).cardColor,
              hoverColor: Theme.of(context).colorScheme.secondaryContainer,
              LocaleKeys.document_plugins_cover_clearAll.tr(),
              fontColor: Theme.of(context).colorScheme.tertiary,
              onPressed: () async {
                final hasFileImageCover = CoverType.fromString(
                      widget.node.attributes[DocumentHeaderBlockKeys.coverType],
                    ) ==
                    CoverType.file;
                final changeCoverBloc = context.read<ChangeCoverPopoverBloc>();
                if (hasFileImageCover) {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return DeleteImageAlertDialog(
                        onSubmit: () {
                          changeCoverBloc.add(
                            const ChangeCoverPopoverEvent.clearAllImages(),
                          );
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                } else {
                  context
                      .read<ChangeCoverPopoverBloc>()
                      .add(const ChangeCoverPopoverEvent.clearAllImages());
                }
              },
              mainAxisAlignment: MainAxisAlignment.end,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAbstractImagePicker() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1 / 0.65,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
      ),
      itemCount: builtInAssetImages.length,
      itemBuilder: (BuildContext ctx, index) {
        return InkWell(
          onTap: () {
            widget.onCoverChanged(
              CoverType.asset,
              builtInAssetImages[index],
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(builtInAssetImages[index]),
                fit: BoxFit.cover,
              ),
              borderRadius: Corners.s8Border,
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorPickerList() {
    final theme = Theme.of(context);
    return CoverColorPicker(
      pickerBackgroundColor: theme.cardColor,
      pickerItemHoverColor: theme.hoverColor,
      selectedBackgroundColorHex:
          widget.node.attributes[DocumentHeaderBlockKeys.coverType] ==
                  CoverType.color.toString()
              ? widget.node.attributes[DocumentHeaderBlockKeys.coverDetails]
              : 'ffffff',
      backgroundColorOptions:
          _generateBackgroundColorOptions(widget.editorState),
      onSubmittedBackgroundColorHex: (color) {
        widget.onCoverChanged(CoverType.color, color);
        setState(() {});
      },
    );
  }

  Widget _buildFileImagePicker() {
    return BlocBuilder<ChangeCoverPopoverBloc, ChangeCoverPopoverState>(
      builder: (context, state) {
        if (state is Loaded) {
          final List<String> images = state.imageNames;
          return GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1 / 0.65,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            itemCount: images.length + 1,
            itemBuilder: (BuildContext ctx, index) {
              if (index == 0) {
                return NewCustomCoverButton(
                  onPressed: () => setState(
                    () => isAddingImage = true,
                  ),
                );
              }
              return ImageGridItem(
                onImageSelect: () {
                  widget.onCoverChanged(
                    CoverType.file,
                    images[index - 1],
                  );
                },
                onImageDelete: () async {
                  final changeCoverBloc =
                      context.read<ChangeCoverPopoverBloc>();
                  final deletingCurrentCover = widget.node
                          .attributes[DocumentHeaderBlockKeys.coverDetails] ==
                      images[index - 1];
                  if (deletingCurrentCover) {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return DeleteImageAlertDialog(
                          onSubmit: () {
                            changeCoverBloc.add(
                              ChangeCoverPopoverEvent.deleteImage(
                                images[index - 1],
                              ),
                            );
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  } else {
                    changeCoverBloc.add(DeleteImage(images[index - 1]));
                  }
                },
                imagePath: images[index - 1],
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  List<ColorOption> _generateBackgroundColorOptions(EditorState editorState) {
    return FlowyTint.values
        .map(
          (t) => ColorOption(
            colorHex: t.color(context).toHex(),
            name: t.tintName(AppFlowyEditorL10n.current),
          ),
        )
        .toList();
  }
}

@visibleForTesting
class NewCustomCoverButton extends StatelessWidget {
  const NewCustomCoverButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
        ),
        borderRadius: Corners.s8Border,
      ),
      child: FlowyIconButton(
        icon: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.primary,
        ),
        hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        onPressed: onPressed,
      ),
    );
  }
}

class ColorOption {
  const ColorOption({
    required this.colorHex,
    required this.name,
  });

  final String colorHex;
  final String name;
}

class CoverColorPicker extends StatefulWidget {
  const CoverColorPicker({
    super.key,
    this.selectedBackgroundColorHex,
    required this.pickerBackgroundColor,
    required this.backgroundColorOptions,
    required this.pickerItemHoverColor,
    required this.onSubmittedBackgroundColorHex,
  });

  final String? selectedBackgroundColorHex;
  final Color pickerBackgroundColor;
  final List<ColorOption> backgroundColorOptions;
  final Color pickerItemHoverColor;
  final void Function(String color) onSubmittedBackgroundColorHex;

  @override
  State<CoverColorPicker> createState() => _CoverColorPickerState();
}

class _CoverColorPickerState extends State<CoverColorPicker> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
          platform: TargetPlatform.windows,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildColorItems(
            widget.backgroundColorOptions,
            widget.selectedBackgroundColorHex,
          ),
        ),
      ),
    );
  }

  Widget _buildColorItems(List<ColorOption> options, String? selectedColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options
          .map(
            (e) => ColorItem(
              option: e,
              isChecked: e.colorHex == selectedColor,
              hoverColor: widget.pickerItemHoverColor,
              onTap: widget.onSubmittedBackgroundColorHex,
            ),
          )
          .toList(),
    );
  }
}

class DeleteImageAlertDialog extends StatelessWidget {
  const DeleteImageAlertDialog({
    super.key,
    required this.onSubmit,
  });

  final Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: FlowyText.semibold(
        "Image is used in cover",
        fontSize: 20,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      content: Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.symmetric(
          vertical: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(LocaleKeys.document_plugins_cover_coverRemoveAlert).tr(),
            const SizedBox(
              height: 4,
            ),
            const Text(
              LocaleKeys.document_plugins_cover_alertDialogConfirmation,
            ).tr(),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 10.0,
        horizontal: 20.0,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(LocaleKeys.button_cancel).tr(),
        ),
        TextButton(
          onPressed: onSubmit,
          child: const Text(LocaleKeys.button_ok).tr(),
        ),
      ],
    );
  }
}

class ImageGridItem extends StatefulWidget {
  const ImageGridItem({
    super.key,
    required this.onImageSelect,
    required this.onImageDelete,
    required this.imagePath,
  });

  final Function() onImageSelect;
  final Function() onImageDelete;
  final String imagePath;

  @override
  State<ImageGridItem> createState() => _ImageGridItemState();
}

class _ImageGridItemState extends State<ImageGridItem> {
  bool showDeleteButton = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          showDeleteButton = true;
        });
      },
      onExit: (_) {
        setState(() {
          showDeleteButton = false;
        });
      },
      child: Stack(
        children: [
          InkWell(
            onTap: widget.onImageSelect,
            child: ClipRRect(
              borderRadius: Corners.s8Border,
              child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),
          ),
          if (showDeleteButton)
            Positioned(
              right: 2,
              top: 2,
              child: FlowyIconButton(
                fillColor:
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                hoverColor:
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                iconPadding: const EdgeInsets.all(5),
                width: 28,
                icon: FlowySvg(
                  FlowySvgs.delete_s,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                onPressed: widget.onImageDelete,
              ),
            ),
        ],
      ),
    );
  }
}

@visibleForTesting
class ColorItem extends StatelessWidget {
  const ColorItem({
    super.key,
    required this.option,
    required this.isChecked,
    required this.hoverColor,
    required this.onTap,
  });

  final ColorOption option;
  final bool isChecked;
  final Color hoverColor;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: InkWell(
        customBorder: const CircleBorder(),
        hoverColor: hoverColor,
        onTap: () => onTap(option.colorHex),
        child: SizedBox.square(
          dimension: 25,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: option.colorHex.tryToColor(),
              shape: BoxShape.circle,
            ),
            child: isChecked
                ? SizedBox.square(
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 3.0,
                        ),
                        color: option.colorHex.tryToColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
