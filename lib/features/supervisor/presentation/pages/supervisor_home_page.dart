import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/role_home_placeholder.dart';

/// Temporary. Replaced when the square supervisor screens are implemented.
class SupervisorHomePage extends StatelessWidget {
  const SupervisorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomePlaceholder(roleLabel: 'مشرف مربع');
  }
}
