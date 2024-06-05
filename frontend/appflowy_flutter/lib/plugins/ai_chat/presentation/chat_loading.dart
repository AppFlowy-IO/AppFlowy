import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatAILoading extends StatelessWidget {
  const ChatAILoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AFThemeExtension.of(context).lightGreyHover,
      highlightColor:
          AFThemeExtension.of(context).lightGreyHover.withOpacity(0.5),
      period: const Duration(seconds: 3),
      child: const ContentPlaceholder(),
    );
  }
}

class ContentPlaceholder extends StatelessWidget {
  const ContentPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 16.0,
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: AFThemeExtension.of(context).lightGreyHover,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const HSpace(10),
              Container(
                width: 100,
                height: 16.0,
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: AFThemeExtension.of(context).lightGreyHover,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ],
          ),
          Container(
            width: 140,
            height: 16.0,
            margin: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              color: AFThemeExtension.of(context).lightGreyHover,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ],
      ),
    );
  }
}
