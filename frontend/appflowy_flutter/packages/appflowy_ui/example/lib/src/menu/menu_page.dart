import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// A showcase page for the AFMenu, AFMenuSection, and AFMenuItem components.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      leading: const Icon(Icons.image),
                      title: 'Menu Item 1',
                      selected: true,
                      onTap: () {},
                    ),
                    AFMenuItem(
                      leading: const Icon(Icons.image),
                      title: 'Menu Item 2',
                      onTap: () {},
                    ),
                    AFMenuItem(
                      leading: const Icon(Icons.image),
                      title: 'Menu Item 3',
                      onTap: () {},
                    ),
                  ],
                ),
                AFMenuSection(
                  title: 'Section 2',
                  children: [
                    AFMenuItem(
                      leading: const FlutterLogo(size: 24),
                      title: 'Menu Item 4',
                      subtitle: 'Menu Item',
                      selected: true,
                      trailing: const Icon(Icons.check, size: 18),
                      onTap: () {},
                    ),
                    AFMenuItem(
                      leading: const FlutterLogo(size: 24),
                      title: 'Menu Item 5',
                      subtitle: 'Menu Item',
                      onTap: () {},
                    ),
                    AFMenuItem(
                      leading: const FlutterLogo(size: 24),
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
                      leading: const Icon(Icons.image),
                      title: 'Menu Item 7',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    AFMenuItem(
                      leading: const Icon(Icons.image),
                      title: 'Menu Item 8',
                      trailing: const Icon(Icons.chevron_right),
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
                  leading: const Icon(Icons.image),
                  title: 'Menu Item 1',
                  onTap: () {},
                ),
                AFMenuItem(
                  leading: const Icon(Icons.image),
                  title: 'Menu Item 2',
                  onTap: () {},
                ),
                AFMenuItem(
                  leading: const Icon(Icons.image),
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
