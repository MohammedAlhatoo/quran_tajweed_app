import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/state/auth_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One tab of a [RoleShell].
class RoleTab {
  const RoleTab({
    required this.label,
    required this.icon,
    required this.title,
    required this.body,
    this.badge = 0,
    this.onSelected,
  });

  /// The short name under the tab's icon.
  final String label;
  final IconData icon;

  /// The app bar title while the tab is open.
  final String title;
  final Widget body;

  /// A count shown on the icon when it is above zero.
  final int badge;

  /// Called every time the tab is opened, for example to refresh its data.
  final VoidCallback? onSelected;
}

/// The frame of a supervisor's, officer's or administrator's area: the open
/// tab under an app bar with the sign-out action, above a bottom bar in the
/// style of the student's.
class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.tabs});

  final List<RoleTab> tabs;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;

  Future<void> _signOut() async {
    final cubit = context.read<AuthCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.signOut();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    widget.tabs[index].onSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(tabs[_index].title),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, color: AppColors.muted),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [for (final tab in tabs) tab.body],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
            child: Row(
              children: [
                for (final (index, tab) in tabs.indexed)
                  Expanded(
                    child: _TabButton(
                      tab: tab,
                      isActive: index == _index,
                      onTap: () => _select(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final RoleTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.faint;

    return Semantics(
      button: true,
      selected: isActive,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge.count(
                count: tab.badge,
                isLabelVisible: tab.badge > 0,
                backgroundColor: AppColors.danger,
                child: Icon(tab.icon, size: 24, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cairo(
                  size: 11,
                  weight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  lineHeight: 16.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
