import 'package:flutter/material.dart';
import 'package:repeat_after_me/l10n/generated/app_localizations.dart';

enum AppDestination { main }

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    required this.selectedDestination,
    this.onDestinationSelected,
  });

  final AppDestination selectedDestination;
  final ValueChanged<AppDestination>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  l10n.appTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(l10n.mainPage),
              selected: selectedDestination == AppDestination.main,
              onTap: () {
                Navigator.of(context).pop();
                onDestinationSelected?.call(AppDestination.main);
              },
            ),
          ],
        ),
      ),
    );
  }
}
