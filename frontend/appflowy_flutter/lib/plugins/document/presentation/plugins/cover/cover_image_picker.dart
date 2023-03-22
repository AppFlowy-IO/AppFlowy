
import 'dart:io';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/plugins/cover/cover_image_picker_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';

class CoverImagePicker extends StatefulWidget {
  final VoidCallback onBackPressed;
  final Function(List<String> paths) onFileSubmit;

  const CoverImagePicker(
      {super.key, required this.onBackPressed, required this.onFileSubmit});

  @override
  State<CoverImagePicker> createState() => _CoverImagePickerState();
}

class _CoverImagePickerState extends State<CoverImagePicker> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CoverImagePickerBloc()
        ..add(const CoverImagePickerEvent.initialEvent()),
      child: BlocListener<CoverImagePickerBloc, CoverImagePickerState>(
        listener: (context, state) {
          if (state is NetworkImagePicked) {
            state.successOrFail.isRight()
                ? showSnapBar(context,
                    LocaleKeys.document_plugins_cover_invalidImageUrl.tr())
                : null;
          }
          if (state is Done) {
            state.successOrFail.fold(
                (l) => widget.onFileSubmit(l),
                (r) => showSnapBar(
                    context,
                    LocaleKeys.document_plugins_cover_failedToAddImageToGallery
                        .tr()));
          }
        },
        child: BlocBuilder<CoverImagePickerBloc, CoverImagePickerState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                state is Loading
                    ? const SizedBox(
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : CoverImagePreviewWidget(state: state),
                const SizedBox(
                  height: 10,
                ),
                NetworkImageUrlInput(
                  onAdd: (url) {
                    context.read<CoverImagePickerBloc>().add(UrlSubmit(url));
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                ImagePickerActionButtons(
                  onBackPressed: () {
                    widget.onBackPressed();
                  },
                  onSave: () {
                    context.read<CoverImagePickerBloc>().add(
                          SaveToGallery(state),
                        );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class NetworkImageUrlInput extends StatefulWidget {
  final void Function(String color) onAdd;

  const NetworkImageUrlInput({
    super.key,
    required this.onAdd,
  });

  @override
  State<NetworkImageUrlInput> createState() => _NetworkImageUrlInputState();
}

class _NetworkImageUrlInputState extends State<NetworkImageUrlInput> {
  TextEditingController urlController = TextEditingController();
  bool get buttonDisabled => urlController.text.isEmpty;

  @override
  void initState() {
    super.initState();
    urlController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: FlowyTextField(
            controller: urlController,
            hintText: LocaleKeys.document_plugins_cover_enterImageUrl.tr(),
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        Expanded(
          flex: 1,
          child: RoundedTextButton(
            onPressed: () {
              urlController.text.isNotEmpty
                  ? widget.onAdd(urlController.text)
                  : null;
            },
            hoverColor: Colors.transparent,
            fillColor: buttonDisabled
                ? Colors.grey
                : Theme.of(context).colorScheme.primary,
            height: 36,
            title: LocaleKeys.document_plugins_cover_add.tr(),
            borderRadius: Corners.s8Border,
          ),
        )
      ],
    );
  }
}

class ImagePickerActionButtons extends StatelessWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onSave;

  const ImagePickerActionButtons(
      {super.key, required this.onBackPressed, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FlowyTextButton(
          LocaleKeys.document_plugins_cover_back.tr(),
          hoverColor: Colors.transparent,
          fillColor: Colors.transparent,
          mainAxisAlignment: MainAxisAlignment.end,
          onPressed: () => onBackPressed(),
        ),
        FlowyTextButton(
          LocaleKeys.document_plugins_cover_saveToGallery.tr(),
          onPressed: () => onSave(),
          hoverColor: Colors.transparent,
          fillColor: Colors.transparent,
          mainAxisAlignment: MainAxisAlignment.end,
          fontColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

class CoverImagePreviewWidget extends StatefulWidget {
  final dynamic state;

  const CoverImagePreviewWidget({super.key, required this.state});

  @override
  State<CoverImagePreviewWidget> createState() =>
      _CoverImagePreviewWidgetState();
}

class _CoverImagePreviewWidgetState extends State<CoverImagePreviewWidget> {
  _buildFilePickerWidget(BuildContext ctx) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            svgWidget(
              "editor/add",
              size: const Size(20, 20),
            ),
            const SizedBox(
              width: 3,
            ),
            FlowyText(
              LocaleKeys.document_plugins_cover_pasteImageUrl.tr(),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        FlowyText(
          LocaleKeys.document_plugins_cover_or.tr(),
          color: Colors.grey,
        ),
        const SizedBox(
          height: 10,
        ),
        FlowyButton(
          onTap: () {
            ctx.read<CoverImagePickerBloc>().add(const PickFileImage());
          },
          useIntrinsicWidth: true,
          leftIcon: svgWidget(
            "file_icon",
            size: const Size(25, 25),
          ),
          text: FlowyText(
            LocaleKeys.document_plugins_cover_pickFromFiles.tr(),
          ),
        ),
      ],
    );
  }

  _buildImageDeleteButton(BuildContext ctx) {
    return Positioned(
      right: 10,
      top: 10,
      child: InkWell(
        onTap: () {
          ctx.read<CoverImagePickerBloc>().add(const DeleteImage());
        },
        child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.onPrimary),
          child: svgWidget(
            "editor/close",
            size: const Size(20, 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: Corners.s6Border,
                image: widget.state is Initial
                    ? null
                    : widget.state is NetworkImagePicked
                        ? widget.state.successOrFail.fold(
                            (path) => DecorationImage(
                                image: NetworkImage(path), fit: BoxFit.cover),
                            (r) => null)
                        : widget.state is FileImagePicked
                            ? DecorationImage(
                                image: FileImage(File(widget.state.path)),
                                fit: BoxFit.cover)
                            : null),
            child: (widget.state is Initial)
                ? _buildFilePickerWidget(context)
                : (widget.state is NetworkImagePicked)
                    ? widget.state.successOrFail.fold(
                        (l) => null,
                        (r) => _buildFilePickerWidget(
                          context,
                        ),
                      )
                    : null),
        (widget.state is FileImagePicked)
            ? _buildImageDeleteButton(context)
            : (widget.state is NetworkImagePicked)
                ? widget.state.successOrFail.fold(
                    (l) => _buildImageDeleteButton(context), (r) => Container())
                : Container()
      ],
    );
  }
}
