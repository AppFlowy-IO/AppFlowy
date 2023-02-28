import 'dart:io';
import 'dart:ui';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/plugins/cover/cover_node_widget.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeCoverPopover extends StatefulWidget {
  final EditorState editorState;
  final Node node;
  final Function(CoverSelectionType selectionType, String selection)
      onCoverChanged;

  const ChangeCoverPopover(
      {super.key,
      required this.editorState,
      required this.onCoverChanged,
      required this.node});

  @override
  State<ChangeCoverPopover> createState() => _ChangeCoverPopoverState();
}

class _ChangeCoverPopoverState extends State<ChangeCoverPopover> {
  late Future<List<String>>? fileImages;
  @override
  void initState() {
    super.initState();
    fileImages = _getPreviouslyPickedImagePaths();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlowyText.semibold(LocaleKeys.cover_colors.tr()),
              const SizedBox(
                height: 10,
              ),
              _buildColorPickerList(),
              const SizedBox(
                height: 10,
              ),
              FlowyText.semibold(LocaleKeys.cover_images.tr()),
              const SizedBox(
                height: 10,
              ),
              _buildFileImagePicker(),
              const SizedBox(
                height: 10,
              ),
              FlowyText.semibold(LocaleKeys.cover_abstract.tr()),
              const SizedBox(
                height: 10,
              ),
              _buildAbstractImagePicker(),
            ],
          ),
        ));
  }

  _buildFileImagePicker() {
    return FutureBuilder<List<String>>(
        future: _getPreviouslyPickedImagePaths(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<String>? images = snapshot.data as List<String>;
            return GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1 / 0.65,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7),
              itemCount: images.length + 1,
              itemBuilder: (BuildContext ctx, index) {
                if (index == 0) {
                  return Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.primary),
                        borderRadius: Corners.s8Border),
                    child: FlowyIconButton(
                        iconPadding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        width: 20,
                        onPressed: () {
                          _pickImages();
                        }),
                  );
                }
                return InkWell(
                  onTap: () {
                    widget.onCoverChanged(
                      CoverSelectionType.file,
                      images[index - 1],
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: FileImage(File(images[index - 1])),
                            fit: BoxFit.cover),
                        borderRadius: Corners.s8Border),
                  ),
                );
              },
            );
          } else {
            return Container();
          }
        });
  }

  _buildAbstractImagePicker() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1 / 0.65,
          crossAxisSpacing: 7,
          mainAxisSpacing: 7),
      itemCount: _assetImages.length,
      itemBuilder: (BuildContext ctx, index) {
        return InkWell(
          onTap: () {
            widget.onCoverChanged(
              CoverSelectionType.asset,
              _assetImages[index],
            );
          },
          child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(_assetImages[index]), fit: BoxFit.cover),
                borderRadius: Corners.s8Border),
          ),
        );
      },
    );
  }

  Future<List<String>> _getPreviouslyPickedImagePaths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? paths = prefs.getStringList('cover_images');

    return paths ?? [];
  }

  void _pickImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? imagePathList = prefs.getStringList("cover_images");
    imagePathList == null ? imagePathList = [] : null;
    FilePickerResult? filePickerResults = await getIt<FilePickerService>()
        .pickFiles(
            dialogTitle: "Add cover images",
            allowMultiple: true,
            allowedExtensions: ['jpg', 'png']);
    if (filePickerResults != null) {
      for (var file in filePickerResults.files) {
        if (file.path!.endsWith("png") || file.path!.endsWith("jpg")) {
          imagePathList.add(file.path!);
        }
      }
    }

    await prefs.setStringList("cover_images", imagePathList);
    setState(() {});
  }

  _buildColorPickerList() {
    return CoverColorPicker(
      pickerBackgroundColor:
          widget.editorState.editorStyle.selectionMenuBackgroundColor ??
              Colors.white,
      pickerItemHoverColor:
          widget.editorState.editorStyle.selectionMenuItemSelectedColor ??
              Colors.blue.withOpacity(0.3),
      selectedBackgroundColorHex:
          widget.node.attributes[kCoverSelectionTypeAttribute] ==
                  CoverSelectionType.color.toString()
              ? widget.node.attributes[kCoverSelectionAttribute]
              : "ffffff",
      backgroundColorOptions:
          _generateBackgroundColorOptions(widget.editorState),
      onSubmittedbackgroundColorHex: (color) {
        widget.onCoverChanged(CoverSelectionType.color, color);
        setState(() {});
      },
    );
  }

  List<ColorOption> _generateBackgroundColorOptions(EditorState editorState) {
    final defaultBackgroundColorHex =
        editorState.editorStyle.highlightColorHex ?? '0x6000BCF0';
    return [
      ColorOption(
        colorHex: defaultBackgroundColorHex,
        name: AppFlowyEditorLocalizations.current.backgroundColorDefault,
      ),
      ColorOption(
        colorHex: Colors.grey.withOpacity(0.3).toHex(),
        name: AppFlowyEditorLocalizations.current.backgroundColorGray,
      ),
      ColorOption(
        colorHex: Colors.brown.withOpacity(0.3).toHex(),
        name: AppFlowyEditorLocalizations.current.backgroundColorBrown,
      ),
      ColorOption(
        colorHex: Colors.yellow.withOpacity(0.3).toHex(),
        name: AppFlowyEditorLocalizations.current.backgroundColorYellow,
      ),
      ColorOption(
        colorHex: Colors.green.withOpacity(0.3).toHex(),
        name: AppFlowyEditorLocalizations.current.backgroundColorGreen,
      ),
      ColorOption(
        colorHex: Colors.blue.withOpacity(0.3).toHex(),
        name: AppFlowyEditorLocalizations.current.backgroundColorBlue,
      ),
      ColorOption(
        colorHex: Colors.purple.withOpacity(0.3).toHex(),
        name: AppFlowyEditorLocalizations.current.backgroundColorPurple,
      ),
      ColorOption(
        colorHex: Colors.pink.withOpacity(0.3).toHex(),
        name: AppFlowyEditorLocalizations.current.backgroundColorPink,
      ),
      ColorOption(
        colorHex: Colors.red.withOpacity(0.3).toHex(),
        name: AppFlowyEditorLocalizations.current.backgroundColorRed,
      ),
    ];
  }
}

class CoverColorPicker extends StatefulWidget {
  const CoverColorPicker({
    super.key,
    this.selectedBackgroundColorHex,
    required this.pickerBackgroundColor,
    required this.backgroundColorOptions,
    required this.pickerItemHoverColor,
    required this.onSubmittedbackgroundColorHex,
  });

  final String? selectedBackgroundColorHex;
  final Color pickerBackgroundColor;
  final Color pickerItemHoverColor;
  final void Function(String color) onSubmittedbackgroundColorHex;
  final List<ColorOption> backgroundColorOptions;

  @override
  State<CoverColorPicker> createState() => _CoverColorPickerState();
}

class _CoverColorPickerState extends State<CoverColorPicker> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 30,
        alignment: Alignment.center,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          }, platform: TargetPlatform.windows),
          child: ListView.builder(
              controller: scrollController,
              shrinkWrap: true,
              itemCount: widget.backgroundColorOptions.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return _buildColorItems(widget.backgroundColorOptions,
                    widget.selectedBackgroundColorHex);
              }),
        ));
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

  Widget _buildColorItem(ColorOption option, bool isChecked) {
    return InkWell(
      customBorder: const RoundedRectangleBorder(
        borderRadius: Corners.s6Border,
      ),
      hoverColor: widget.pickerItemHoverColor,
      onTap: () {
        widget.onSubmittedbackgroundColorHex(option.colorHex);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: SizedBox.square(
          dimension: 25,
          child: Container(
            decoration: BoxDecoration(
              color: isChecked
                  ? Colors.transparent
                  : Color(int.tryParse(option.colorHex) ?? 0xFFFFFFFF),
              border: isChecked
                  ? Border.all(
                      color: Color(int.tryParse(option.colorHex) ?? 0xFFFFFF))
                  : null,
              shape: BoxShape.circle,
            ),
            child: isChecked
                ? SizedBox.square(
                    dimension: 25,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            Color(int.tryParse(option.colorHex) ?? 0xFFFFFFFF),
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

List<String> get _assetImages => [
      "assets/images/app_flowy_abstract_cover_1.jpg",
      "assets/images/app_flowy_abstract_cover_2.jpg"
    ];

extension on Color {
  String toHex() {
    return '0x${value.toRadixString(16)}';
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
