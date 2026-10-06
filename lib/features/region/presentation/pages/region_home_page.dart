import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/role_shell.dart';
import '../../../admin/presentation/pages/accounts_view.dart';
import '../../../admin/presentation/pages/units_views.dart';
import '../../../admin/presentation/state/report_cubit.dart';
import '../../../admin/presentation/widgets/org_widgets.dart';
import '../../../admin/presentation/widgets/region_report_pdf_button.dart';
import '../../../admin/presentation/widgets/report_view.dart';
import '../../../auth/domain/entities/user_role.dart';

/// The region officer's area. It shows the management screens of the General
/// Admin limited to the officer's own region: the data it loads and every
/// change it makes are scoped to that region, and the security rules refuse
/// anything outside it.
class RegionHomePage extends StatelessWidget {
  const RegionHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OrganizationMessages(
      child: RoleShell(
        tabs: [
          const RoleTab(
            label: 'المربعات',
            icon: Icons.grid_view_rounded,
            title: 'مربعات المنطقة',
            body: SquaresView(),
          ),
          const RoleTab(
            label: 'المساجد',
            icon: Icons.mosque_outlined,
            title: 'مساجد المنطقة',
            body: MosquesView(),
          ),
          const RoleTab(
            label: 'المشرفون',
            icon: Icons.supervisor_account_outlined,
            title: 'مشرفو المربعات',
            body: AccountsView(roles: [UserRole.squareSupervisor]),
          ),
          const RoleTab(
            label: 'الطلاب',
            icon: Icons.people_outline_rounded,
            title: 'طلاب المنطقة',
            body: AccountsView(roles: [UserRole.student]),
          ),
          RoleTab(
            label: 'التقارير',
            icon: Icons.bar_chart_rounded,
            title: 'تقرير المنطقة',
            onSelected: context.read<ReportCubit>().load,
            body: ReportView(
              header: (report) => RegionReportPdfButton(report: report),
            ),
          ),
        ],
      ),
    );
  }
}
