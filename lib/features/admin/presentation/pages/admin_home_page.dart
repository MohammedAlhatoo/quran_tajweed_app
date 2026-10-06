import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/role_shell.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../state/report_cubit.dart';
import '../widgets/general_admin_report_pdf_button.dart';
import '../widgets/org_widgets.dart';
import '../widgets/report_view.dart';
import 'accounts_view.dart';
import 'units_views.dart';

/// The General Admin's area: the whole system.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OrganizationMessages(
      child: RoleShell(
        tabs: [
          const RoleTab(
            label: 'المناطق',
            icon: Icons.map_outlined,
            title: 'المناطق',
            body: RegionsView(),
          ),
          const RoleTab(
            label: 'المربعات',
            icon: Icons.grid_view_rounded,
            title: 'المربعات',
            body: SquaresView(),
          ),
          const RoleTab(
            label: 'المساجد',
            icon: Icons.mosque_outlined,
            title: 'المساجد',
            body: MosquesView(),
          ),
          const RoleTab(
            label: 'الحسابات',
            icon: Icons.people_outline_rounded,
            title: 'الحسابات',
            body: AccountsView(
              roles: [
                UserRole.regionOfficer,
                UserRole.squareSupervisor,
                UserRole.student,
              ],
            ),
          ),
          RoleTab(
            label: 'التقارير',
            icon: Icons.bar_chart_rounded,
            title: 'تقرير النظام',
            onSelected: context.read<ReportCubit>().load,
            body: ReportView(
              header: (report) => GeneralAdminReportPdfButton(report: report),
            ),
          ),
        ],
      ),
    );
  }
}
