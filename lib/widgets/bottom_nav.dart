import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Bottom navigation bar widget
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: l10n.calendar,
        ),
        NavigationDestination(
          icon: const Icon(Icons.timeline_outlined),
          selectedIcon: const Icon(Icons.timeline),
          label: l10n.moment,
        ),
        const NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: '',
        ),
        NavigationDestination(
          icon: const Icon(Icons.checklist_outlined),
          selectedIcon: const Icon(Icons.checklist),
          label: l10n.routine,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.settings,
        ),
      ],
    );
  }
}

/// Alternative bottom nav with labels for add button
class BottomNavBarWithFAB extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onAddPressed;

  const BottomNavBarWithFAB({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.calendar_month_outlined, Icons.calendar_month, l10n.calendar),
          _buildNavItem(1, Icons.timeline_outlined, Icons.timeline, l10n.moment),
          const SizedBox(width: 48), // Space for FAB
          _buildNavItem(3, Icons.checklist_outlined, Icons.checklist, l10n.routine),
          _buildNavItem(4, Icons.settings_outlined, Icons.settings, l10n.settings),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating action button for adding new entries
class AddEntryFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const AddEntryFAB({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}

/// FAB positioned in the center of bottom nav
class CenteredFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const CenteredFAB({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}