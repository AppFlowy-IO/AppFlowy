import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';

/// A showcase page for the AFMenu, AFMenuSection, and AFTextMenuItem components.
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final popoverController = AFPopoverController();

  @override
  void dispose() {
    popoverController.dispose();

    super.dispose();
  }

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
    final animationDuration = const Duration(milliseconds: 120);

    return Center(
      child: SingleChildScrollView(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          runAlignment: WrapAlignment.start,
          runSpacing: 16,
          spacing: 16,
          children: [
            AFMenu(
              width: 240,
              children: [
                AFMenuSection(
                  title: 'Section 1',
                  children: [
                    AFTextMenuItem(
                      leading: leading,
                      title: 'Menu Item 1',
                      selected: true,
                      onTap: () {},
                    ),
                    AFPopover(
                      controller: popoverController,
                      shadows: theme.shadow.medium,
                      anchor: const AFAnchor(
                        offset: Offset(0, -20),
                        overlayAlignment: Alignment.centerRight,
                      ),
                      effects: [
                        FadeEffect(duration: animationDuration),
                        ScaleEffect(
                          duration: animationDuration,
                          begin: Offset(.95, .95),
                          end: Offset(1, 1),
                        ),
                        MoveEffect(
                          duration: animationDuration,
                          begin: Offset(-10, 0),
                          end: Offset(0, 0),
                        ),
                      ],
                      popover: (context) {
                        return AFMenu(
                          children: [
                            AFTextMenuItem(
                              leading: leading,
                              title: 'Menu Item 2-1',
                              onTap: () {},
                            ),
                            AFTextMenuItem(
                              leading: leading,
                              title: 'Menu Item 2-2',
                              onTap: () {},
                            ),
                            AFTextMenuItem(
                              leading: leading,
                              title: 'Menu Item 2-3',
                              onTap: () {},
                            ),
                          ],
                        );
                      },
                      child: AFTextMenuItem(
                        leading: leading,
                        title: 'Menu Item 2',
                        onTap: () {
                          popoverController.toggle();
                        },
                      ),
                    ),
                    AFTextMenuItem(
                      leading: leading,
                      title: 'Menu Item 3',
                      onTap: () {},
                    ),
                  ],
                ),
                AFMenuSection(
                  title: 'Section 2',
                  children: [
                    AFTextMenuItem(
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
                    AFTextMenuItem(
                      leading: logo,
                      title: 'Menu Item 5',
                      subtitle: 'Menu Item',
                      onTap: () {},
                    ),
                    AFTextMenuItem(
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
                    AFTextMenuItem(
                      leading: leading,
                      title: 'Menu Item 7',
                      trailing: arrowRight,
                      onTap: () {},
                    ),
                    AFTextMenuItem(
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
              width: 240,
              children: [
                AFTextMenuItem(
                  leading: leading,
                  title: 'Menu Item 1',
                  onTap: () {},
                ),
                AFTextMenuItem(
                  leading: leading,
                  title: 'Menu Item 2',
                  onTap: () {},
                ),
                AFTextMenuItem(
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
