import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_mode_provider.dart';

const _kBannerBlue = Color(0xFF4A62AD);
const _kInk = Color(0xFF1C2333);
const _kSecondaryText = Color(0xFF6B7280);

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserModeProvider>();
    final isCitizen = provider.isCitizenMode;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings & Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.swap_horiz, color: _kBannerBlue),
                title: const Text('Switch Mode (Citizen / Official)'),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: _kSecondaryText,
                ),
                onTap: () {
                  Navigator.pop(context);
                  showModeToggleSheet(context);
                },
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language, color: _kBannerBlue),
                title: const Text('Language Selection'),
                subtitle: const Text('English • Hindi • Regional'),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: _kSecondaryText,
                ),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  var notificationsEnabled = true;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.notifications_outlined,
                      color: _kBannerBlue,
                    ),
                    title: const Text('Notification Preferences'),
                    trailing: Switch(
                      value: notificationsEnabled,
                      onChanged: (value) {
                        setState(() => notificationsEnabled = value);
                      },
                    ),
                  );
                },
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined, color: _kBannerBlue),
                title: Text(
                  isCitizen
                      ? 'Account / Citizen Profile'
                      : 'Account / Officer Profile',
                ),
                subtitle: Text(
                  isCitizen ? 'Registered Citizen' : 'Officer ID: SOL-2024-001',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: _kSecondaryText,
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showSettingsBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const SettingsBottomSheet(),
  );
}

Future<void> showModeToggleSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => Consumer<UserModeProvider>(
      builder: (context, provider, _) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            4,
            24,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Switch view',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Citizen Mode shows the local problem feed. Official Mode is reserved for municipal staff.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kSecondaryText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.people_alt_outlined,
                    color: _kBannerBlue,
                  ),
                  title: const Text('Citizen Mode'),
                  trailing: provider.isCitizenMode
                      ? const Icon(Icons.check_circle, color: _kBannerBlue)
                      : null,
                  onTap: () {
                    provider.setCitizenMode(true);
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.badge_outlined,
                    color: _kBannerBlue,
                  ),
                  title: const Text('Official Mode'),
                  trailing: !provider.isCitizenMode
                      ? const Icon(Icons.check_circle, color: _kBannerBlue)
                      : null,
                  onTap: () {
                    provider.setCitizenMode(false);
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
