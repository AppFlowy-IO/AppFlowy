import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_share_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PublishTab extends StatelessWidget {
  const PublishTab({super.key});

  @override
  Widget build(BuildContext context) {
    return context.watch<DocumentShareBloc>().state.isPublished
        ? _PublishedWidget(
            onUnPublish: () {
              context
                  .read<DocumentShareBloc>()
                  .add(const DocumentShareEvent.unPublish());
            },
            onVisitSite: () {},
          )
        : _UnPublishWidget(
            onPublish: () => context
                .read<DocumentShareBloc>()
                .add(const DocumentShareEvent.publish('')),
          );
  }
}

class _PublishedWidget extends StatefulWidget {
  const _PublishedWidget({
    required this.onVisitSite,
    required this.onUnPublish,
  });

  final VoidCallback onVisitSite;
  final VoidCallback onUnPublish;

  @override
  State<_PublishedWidget> createState() => _PublishedWidgetState();
}

class _PublishedWidgetState extends State<_PublishedWidget> {
  final controller = TextEditingController();

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
          onCopy: (url) {},
          onSubmitted: (url) {},
        ),
        const VSpace(16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              context,
              name: LocaleKeys.shareAction_unPublish.tr(),
              borderColor: const Color(0x1E14171B),
              onTap: widget.onUnPublish,
            ),
            const Spacer(),
            _buildButton(
              context,
              name: LocaleKeys.shareAction_visitSite.tr(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              textColor: Colors.white,
              onTap: () {},
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
      width: 189,
      child: FlowyButton(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
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
        autoFocus: false,
        controller: controller,
        text: 'http:/appflowy.com/vinh/open-positions',
        suffixIcon: _buildCopyLinkIcon(),
      ),
    );
  }

  Widget _buildCopyLinkIcon() {
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
