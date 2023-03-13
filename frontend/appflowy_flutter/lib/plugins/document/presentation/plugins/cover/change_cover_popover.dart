import 'dart:io';
import 'dart:ui';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/plugins/cover/cover_node_widget.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/file_picker/file_picker_service.dart';
import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart' show FileType;
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as Path;

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
  final void Function(String color) onSubmittedbackgroundColorHex;
  final List<ColorOption> backgroundColorOptions;
  const CoverColorPicker({
    super.key,
    this.selectedBackgroundColorHex,
    required this.pickerBackgroundColor,
    required this.backgroundColorOptions,
    required this.pickerItemHoverColor,
    required this.onSubmittedbackgroundColorHex,
  });

  @override
  State<CoverColorPicker> createState() => _CoverColorPickerState();
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
            FlowyText.semibold(LocaleKeys.document_plugins_cover_colors.tr()),
            const SizedBox(height: 10),
            _buildColorPickerList(),
            const SizedBox(height: 10),
            FlowyText.semibold(LocaleKeys.document_plugins_cover_images.tr()),
            const SizedBox(height: 10),
            _buildFileImagePicker(),
            const SizedBox(height: 10),
            FlowyText.semibold(LocaleKeys.document_plugins_cover_abstract.tr()),
            const SizedBox(height: 10),
            _buildAbstractImagePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildAbstractImagePicker() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1 / 0.65,
          crossAxisSpacing: 7,
          mainAxisSpacing: 7),
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

  Widget _buildFileImagePicker() {
    return FutureBuilder<List<String>>(
        future: _getPreviouslyPickedImagePaths(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<String> images = snapshot.data!;
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
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
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
                      width: 20,
                      onPressed: () {
                        _pickImages();
                      },
                    ),
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
                        fit: BoxFit.cover,
                      ),
                      borderRadius: Corners.s8Border,
                    ),
                  ),
                );
              },
            );
          } else {
            return Container();
          }
        });
  }

  List<ColorOption> _generateBackgroundColorOptions(EditorState editorState) {
    return FlowyTint.values
        .map((t) => ColorOption(
              colorHex: t.color(context).toHex(),
              name: t.tintName(AppFlowyEditorLocalizations.current),
            ))
        .toList();
  }

  Future<List<String>> _getPreviouslyPickedImagePaths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final imageNames = prefs.getStringList(kLocalImagesKey) ?? [];
    final removeNames = [];
    for (final name in imageNames) {
      if (!File(name).existsSync()) {
        removeNames.add(name);
      }
    }
    imageNames.removeWhere((element) => removeNames.contains(element));
    prefs.setStringList(kLocalImagesKey, imageNames);
    return imageNames;
  }

  Future<void> _pickImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> imageNames = prefs.getStringList(kLocalImagesKey) ?? [];
    FilePickerResult? result = await getIt<FilePickerService>().pickFiles(
      dialogTitle: LocaleKeys.document_plugins_cover_addLocalImage.tr(),
      allowMultiple: false,
      type: FileType.image,
      allowedExtensions: ['jpg', 'png', 'jpeg'],
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        final directory = await _coverPath();
        final newPath = await File(path).copy(
          '$directory/${Path.split(path).last}}',
        );
        imageNames.add(newPath.path);
      }
    }
    await prefs.setStringList(kLocalImagesKey, imageNames);
    setState(() {});
  }

  Future<String> _coverPath() async {
    final directory = await getIt<SettingsLocationCubit>().fetchLocation();
    return Directory(Path.join(directory, 'covers'))
        .create(recursive: true)
        .then((value) => value.path);
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
            return _buildColorItems(
              widget.backgroundColorOptions,
              widget.selectedBackgroundColorHex,
            );
          },
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

extension on Color {
  String toHex() {
    return '0x${value.toRadixString(16)}';
  }
}
