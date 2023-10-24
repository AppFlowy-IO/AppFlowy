import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const rainbowColors = <Color>[
  Color(0xFFFF0064),
  Color(0xFFFF7600),
  Color(0xFFFFD500),
  Color(0xFF8CFE00),
  Color(0xFF00E86C),
  Color(0xFF00F4F2),
  Color(0xFF00CCFF),
  Color(0xFF70A2FF),
  Color(0xFFA96CFF),
];

class MobileHomePageRecentFilesWidget extends StatelessWidget {
  const MobileHomePageRecentFilesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement the details later.
    return SizedBox(
      height: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: FlowyText.semibold(
              'Recent',
              fontSize: 20.0,
            ),
          ),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => const HSpace(20),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: rainbowColors.length,
              itemBuilder: (context, index) {
                return Container(
                  alignment: Alignment.center,
                  width: 144,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: rainbowColors[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
