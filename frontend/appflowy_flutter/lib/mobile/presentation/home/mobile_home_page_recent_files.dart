import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

// TODO(yijing): replace by real data later
class MockRecentFile {
  MockRecentFile({
    required this.title,
  });
  final String title;
  final String icon = '🐼';

  final image = Image.asset(
    'assets/images/app_flowy_abstract_cover_1.jpg',
    fit: BoxFit.cover,
  );
}

final recentFilesList = <MockRecentFile>[
  MockRecentFile(title: 'Work out plan'),
  MockRecentFile(title: 'Travel plan'),
  MockRecentFile(title: 'Meeting notes'),
  MockRecentFile(title: 'Recipes'),
  MockRecentFile(title: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
];

class MobileHomePageRecentFilesWidget extends StatelessWidget {
  const MobileHomePageRecentFilesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement the details later.
    return SizedBox(
      height: 168,
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
              separatorBuilder: (context, index) => const HSpace(8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: recentFilesList.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.5),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: 60,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                            child: recentFilesList[index].image,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 32,
                          width: 32,
                          margin: const EdgeInsets.only(left: 8),
                          child: Text(
                            recentFilesList[index].icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 32,
                          width: double.infinity,
                          margin: const EdgeInsets.only(
                            left: 8,
                            right: 8,
                            bottom: 8,
                          ),
                          child: Text(
                            recentFilesList[index].title,
                            softWrap: true,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                ),
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ],
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
