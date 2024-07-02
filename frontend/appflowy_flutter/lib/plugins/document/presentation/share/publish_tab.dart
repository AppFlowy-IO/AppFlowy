import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_share_bloc.dart';
import 'package:appflowy/plugins/document/presentation/share/pubish_color_extension.dart';
import 'package:appflowy/plugins/document/presentation/share/publish_name_generator.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PublishTab extends StatelessWidget {
  const PublishTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentShareBloc, DocumentShareState>(
      listener: (context, state) {
        if (state.publishResult != null) {
          state.publishResult!.fold(
            (value) => showSnackBarMessage(context, 'Published successfully'),
            (error) =>
                showSnackBarMessage(context, 'Failed to publish: $error'),
          );
        }
      },
      builder: (context, state) {
        return state.isPublished
            ? _PublishedWidget(
                url: state.url,
                onVisitSite: () {},
                onUnPublish: () {
                  context
                      .read<DocumentShareBloc>()
                      .add(const DocumentShareEvent.unPublish());
                },
              )
            : _UnPublishWidget(
                onPublish: () async {
                  final id = context.read<DocumentShareBloc>().view.id;
                  final publishName = await generatePublishName(
                    id,
                    state.viewName,
                  );
                  if (context.mounted) {
                    context.read<DocumentShareBloc>().add(
                          DocumentShareEvent.publish('', publishName),
                        );
                  }
                },
              );
      },
    );
  }
}

class _PublishedWidget extends StatefulWidget {
  const _PublishedWidget({
    required this.url,
    required this.onVisitSite,
    required this.onUnPublish,
  });

  final String url;
  final VoidCallback onVisitSite;
  final VoidCallback onUnPublish;

  @override
  State<_PublishedWidget> createState() => _PublishedWidgetState();
}

class _PublishedWidgetState extends State<_PublishedWidget> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = widget.url;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VSpace(16),
        const _PublishTabHeader(),
        const VSpace(16),
        _PublishUrl(
          controller: controller,
          onCopy: (url) {
            AppFlowyClipboard.setData(text: url);
          },
          onSubmitted: (url) {},
        ),
        const VSpace(16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              context,
              name: LocaleKeys.shareAction_unPublish.tr(),
              borderColor: ShareMenuColors.borderColor(context),
              onTap: widget.onUnPublish,
            ),
            const Spacer(),
            _buildButton(
              context,
              name: LocaleKeys.shareAction_visitSite.tr(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              textColor:
                  Theme.of(context).isLightMode ? Colors.white : Colors.black,
              onTap: () {
                safeLaunchUrl(controller.text);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String name,
    Color? backgroundColor,
    Color borderColor = Colors.transparent,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 36,
      width: 184,
      child: FlowyButton(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        radius: BorderRadius.circular(10),
        text: FlowyText.regular(
          name,
          textAlign: TextAlign.center,
          color: textColor,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _UnPublishWidget extends StatelessWidget {
  const _UnPublishWidget({
    required this.onPublish,
  });

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VSpace(16),
        const _PublishTabHeader(),
        const VSpace(16),
        RoundedTextButton(
          height: 36,
          title: LocaleKeys.shareAction_publish.tr(),
          padding: const EdgeInsets.symmetric(vertical: 9.0),
          fontSize: 14.0,
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: onPublish,
        ),
      ],
    );
  }
}

class _PublishTabHeader extends StatelessWidget {
  const _PublishTabHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FlowySvg(FlowySvgs.share_publish_s),
            const HSpace(6),
            FlowyText(LocaleKeys.shareAction_publishToTheWeb.tr()),
          ],
        ),
        const VSpace(4),
        FlowyText.regular(
          LocaleKeys.shareAction_publishToTheWebHint.tr(),
          fontSize: 12,
          maxLines: 3,
          color: Theme.of(context).hintColor,
        ),
      ],
    );
  }
}

class _PublishUrl extends StatelessWidget {
  const _PublishUrl({
    required this.controller,
    required this.onCopy,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final void Function(String url) onCopy;
  final void Function(String url) onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FlowyTextField(
        readOnly: true,
        autoFocus: false,
        controller: controller,
        enableBorderColor: ShareMenuColors.borderColor(context),
        suffixIcon: _buildCopyLinkIcon(context),
      ),
    );
  }

  Widget _buildCopyLinkIcon(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onCopy(controller.text),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Color(0x141F2329))),
          ),
          child: const FlowySvg(
            FlowySvgs.m_toolbar_link_m,
          ),
        ),
      ),
    );
  }
}
