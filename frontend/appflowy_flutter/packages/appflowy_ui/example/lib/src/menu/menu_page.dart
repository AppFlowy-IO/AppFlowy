import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// A showcase page for the AFMenu, AFMenuSection, and AFMenuItem components.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final leading = SvgPicture.asset(
      'assets/images/vector.svg',
      colorFilter: ColorFilter.mode(
        theme.textColorScheme.primary,
        BlendMode.srcIn,
      ),
    );
    final logo = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.borderRadius.m),
        border: Border.all(
          color: theme.borderColorScheme.primary,
        ),
      ),
      padding: EdgeInsets.all(theme.spacing.xs),
      child: const FlutterLogo(size: 18),
    );
    final arrowRight = SvgPicture.asset(
      'assets/images/arrow_right.svg',
      width: 20,
      height: 20,
    );

    return Center(
      child: SingleChildScrollView(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          runAlignment: WrapAlignment.start,
          runSpacing: 16,
          spacing: 16,
          children: [
            AFMenu(
              children: [
                AFMenuSection(
                  title: 'Section 1',
                  children: [
                    AFMenuItem(
                      leading: leading,
                      title: 'Menu Item 1',
                      selected: true,
                      onTap: () {},
                    ),
                    AFMenuItem(
                      leading: leading,
                      title: 'Menu Item 2',
                      onTap: () {},
                    ),
                    AFMenuItem(
                      leading: leading,
                      title: 'Menu Item 3',
                      onTap: () {},
                    ),
                  ],
                ),
                AFMenuSection(
                  title: 'Section 2',
                  children: [
                    AFMenuItem(
                      leading: logo,
                      title: 'Menu Item 4',
                      subtitle: 'Menu Item',
                      trailing: const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.blueAccent,
                      ),
                      onTap: () {},
                    ),
                    AFMenuItem(
                      leading: logo,
                      title: 'Menu Item 5',
                      subtitle: 'Menu Item',
                      onTap: () {},
                    ),
                    AFMenuItem(
                      leading: logo,
                      title: 'Menu Item 6',
                      subtitle: 'Menu Item',
                      onTap: () {},
                    ),
                  ],
                ),
                AFMenuSection(
                  title: 'Section 3',
                  children: [
                    AFMenuItem(
                      leading: leading,
                      title: 'Menu Item 7',
                      trailing: arrowRight,
                      onTap: () {},
                    ),
                    AFMenuItem(
                      leading: leading,
                      title: 'Menu Item 8',
                      trailing: arrowRight,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Example: Menu with search bar
            AFMenu(
              children: [
                AFMenuItem(
                  leading: leading,
                  title: 'Menu Item 1',
                  onTap: () {},
                ),
                AFMenuItem(
                  leading: leading,
                  title: 'Menu Item 2',
                  onTap: () {},
                ),
                AFMenuItem(
                  leading: leading,
                  title: 'Menu Item 3',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
