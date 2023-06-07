import 'dart:io';
import 'dart:ui';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String kLocalImagesKey = 'local_images';

List<String> get builtInAssetImages => [
      "assets/images/app_flowy_abstract_cover_1.jpg",
      "assets/images/app_flowy_abstract_cover_2.jpg"
    ];

class ChangeCoverPopover extends StatefulWidget {
  final EditorState editorState;
  final Node node;
  final Function(
    CoverSelectionType selectionType,
    String selection,
  ) onCoverChanged;

  const ChangeCoverPopover({
    super.key,
    required this.editorState,
    required this.onCoverChanged,
    required this.node,
  });

  @override
  State<ChangeCoverPopover> createState() => _ChangeCoverPopoverState();
}

class ColorOption {
  final String colorHex;

  final String name;
  const ColorOption({
    required this.colorHex,
    required this.name,
  });
}

class CoverColorPicker extends StatefulWidget {
  final String? selectedBackgroundColorHex;

  final Color pickerBackgroundColor;
  final Color pickerItemHoverColor;
  final void Function(String color) onSubmittedBackgroundColorHex;
  final List<ColorOption> backgroundColorOptions;
  const CoverColorPicker({
    super.key,
    this.selectedBackgroundColorHex,
    required this.pickerBackgroundColor,
    required this.backgroundColorOptions,
    required this.pickerItemHoverColor,
    required this.onSubmittedBackgroundColorHex,
  });

  @override
  State<CoverColorPicker> createState() => _CoverColorPickerState();
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
      child: BlocBuilder<ChangeCoverPopoverBloc, ChangeCoverPopoverState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(15),
            child: SingleChildScrollView(
              child: isAddingImage
                  ? CoverImagePicker(
                      onBackPressed: () => setState(() {
                        isAddingImage = false;
                      }),
                      onFileSubmit: (List<String> path) {
                        context.read<ChangeCoverPopoverBloc>().add(
                              const ChangeCoverPopoverEvent
                                  .fetchPickedImagePaths(),
                            );
                        setState(() {
                          isAddingImage = false;
                        });
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
        const SizedBox(height: 10),
        _buildColorPickerList(),
        const SizedBox(height: 10),
        _buildImageHeader(),
        const SizedBox(height: 10),
        _buildFileImagePicker(),
        const SizedBox(height: 10),
        FlowyText.semibold(
          LocaleKeys.document_plugins_cover_abstract.tr(),
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(height: 10),
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
                final hasFileImageCover = CoverSelectionType.fromString(
                      widget.node.attributes[CoverBlockKeys.selectionType],
                    ) ==
                    CoverSelectionType.file;
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
              CoverSelectionType.asset,
              builtInAssetImages[index],
            );
          },
          child: Container(
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
          widget.node.attributes[CoverBlockKeys.selectionType] ==
                  CoverSelectionType.color.toString()
              ? widget.node.attributes[CoverBlockKeys.selection]
              : 'ffffff',
      backgroundColorOptions:
          _generateBackgroundColorOptions(widget.editorState),
      onSubmittedBackgroundColorHex: (color) {
        widget.onCoverChanged(CoverSelectionType.color, color);
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
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: Corners.s8Border,
                  ),
                  child: FlowyIconButton(
                    iconPadding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    hoverColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    width: 20,
                    onPressed: () {
                      setState(() {
                        isAddingImage = true;
                      });
                    },
                  ),
                );
              }
              return ImageGridItem(
                onImageSelect: () {
                  widget.onCoverChanged(
                    CoverSelectionType.file,
                    images[index - 1],
                  );
                },
                onImageDelete: () async {
                  final changeCoverBloc =
                      context.read<ChangeCoverPopoverBloc>();
                  final deletingCurrentCover =
                      widget.node.attributes[CoverBlockKeys.selection] ==
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
        return Container();
      },
    );
  }

  List<ColorOption> _generateBackgroundColorOptions(EditorState editorState) {
    return FlowyTint.values
        .map(
          (t) => ColorOption(
            colorHex: t.color(context).toHex(),
            name: t.tintName(AppFlowyEditorLocalizations.current),
          ),
        )
        .toList();
  }
}

class DeleteImageAlertDialog extends StatelessWidget {
  const DeleteImageAlertDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

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
          child: const Text(LocaleKeys.button_Cancel).tr(),
        ),
        TextButton(
          onPressed: onSubmit,
          child: const Text(LocaleKeys.button_OK).tr(),
        ),
      ],
    );
  }
}

class ImageGridItem extends StatefulWidget {
  const ImageGridItem({
    Key? key,
    required this.onImageSelect,
    required this.onImageDelete,
    required this.imagePath,
  }) : super(key: key);

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
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(widget.imagePath)),
                  fit: BoxFit.cover,
                ),
                borderRadius: Corners.s8Border,
              ),
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
                icon: svgWidget(
                  'editor/delete',
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

class _CoverColorPickerState extends State<CoverColorPicker> {
  final scrollController = ScrollController();

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
          child: _buildColorItems(
            widget.backgroundColorOptions,
            widget.selectedBackgroundColorHex,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  Widget _buildColorItem(ColorOption option, bool isChecked) {
    return InkWell(
      customBorder: const RoundedRectangleBorder(
        borderRadius: Corners.s6Border,
      ),
      hoverColor: widget.pickerItemHoverColor,
      onTap: () {
        widget.onSubmittedBackgroundColorHex(option.colorHex);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: SizedBox.square(
          dimension: isChecked ? 24 : 25,
          child: Container(
            decoration: BoxDecoration(
              color: option.colorHex.toColor(),
              border: isChecked
                  ? Border.all(
                      color: const Color(0xFFFFFFFF),
                      width: 2.0,
                    )
                  : null,
              shape: BoxShape.circle,
            ),
            child: isChecked
                ? SizedBox.square(
                    dimension: 24,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: option.colorHex.toColor(),
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

  Widget _buildColorItems(List<ColorOption> options, String? selectedColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: options
          .map((e) => _buildColorItem(e, e.colorHex == selectedColor))
          .toList(),
    );
  }
}
