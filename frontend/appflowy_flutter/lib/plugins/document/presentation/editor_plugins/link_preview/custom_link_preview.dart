import 'package:cached_network_image/cached_network_image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CustomLinkPreviewWidget extends StatelessWidget {
  const CustomLinkPreviewWidget({
    super.key,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });

  final String? title;
  final String? description;
  final String? imageUrl;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrlString(url),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          borderRadius: BorderRadius.circular(
            6.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6.0),
                  bottomLeft: Radius.circular(6.0),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 180,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: FlowyText.medium(
                          title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          fontSize: 16.0,
                        ),
                      ),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: FlowyText(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    FlowyText(
                      url.toString(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      color: Theme.of(context).hintColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
