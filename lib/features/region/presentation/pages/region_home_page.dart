import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/role_home_placeholder.dart';

/// Temporary. Replaced when the region officer screens are implemented.
class RegionHomePage extends StatelessWidget {
  const RegionHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHomePlaceholder(roleLabel: 'مسؤول منطقة');
  }
}
