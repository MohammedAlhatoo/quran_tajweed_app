import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/role_home_placeholder.dart';

/// Temporary. Replaced when the general admin screens are implemented.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomePlaceholder(roleLabel: 'مدير عام');
  }
}
