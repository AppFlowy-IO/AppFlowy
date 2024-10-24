import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/domain/domain_more_action.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class DomainItem extends StatelessWidget {
  const DomainItem({
    super.key,
    required this.namespace,
    required this.homepage,
  });

  final String namespace;
  final String homepage;

  @override
  Widget build(BuildContext context) {
    final namespaceUrl = ShareConstants.buildNamespaceUrl(
      nameSpace: namespace,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Domain
        Expanded(
          child: FlowyText(
            namespaceUrl,
            fontSize: 14.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Published Name

        // Homepage
        Expanded(
          child: FlowyText(
            homepage,
            fontSize: 14.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        DomainMoreAction(namespace: namespace),
      ],
    );
  }
}
