import 'package:flutter/material.dart';

import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/mosque.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/organization.dart';
import '../state/organization_cubit.dart';
import '../widgets/org_widgets.dart';

/// The regions of the system. Only the General Admin manages them.
class RegionsView extends StatelessWidget {
  const RegionsView({super.key});

  Future<void> _edit(
    BuildContext context,
    OrganizationCubit cubit, [
    Region? region,
  ]) async {
    final values = await showOrgForm(
      context,
      title: region == null ? 'إضافة منطقة' : 'تعديل المنطقة',
      fields: [
        OrgField.text(
          'name',
          'اسم المنطقة',
          initial: region?.name,
          validator: Validators.name,
        ),
      ],
    );
    if (values == null) return;
    await cubit.saveRegion(
      id: region?.id,
      name: values['name']!,
      isActive: region?.isActive ?? true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrganizationView(
      builder: (context, organization, cubit) => OrgList(
        addLabel: 'إضافة منطقة',
        onAdd: () => _edit(context, cubit),
        emptyMessage: 'لا توجد مناطق بعد.',
        children: [
          for (final region in organization.regions)
            OrgCard(
              title: region.name,
              isActive: region.isActive,
              lines: [
                'المسؤول: '
                    '${organization.userName(region.officerId) ?? 'بدون مسؤول'}',
                'المربعات: '
                    '${organization.squares.where((s) => s.regionId == region.id).length}',
              ],
              actions: [
                ('تعديل الاسم', () => _edit(context, cubit, region)),
                (
                  region.isActive ? 'إيقاف المنطقة' : 'تفعيل المنطقة',
                  () => cubit.saveRegion(
                    id: region.id,
                    name: region.name,
                    isActive: !region.isActive,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The squares of the scope: every region for the General Admin, one region
/// for its officer.
class SquaresView extends StatelessWidget {
  const SquaresView({super.key});

  Future<void> _edit(
    BuildContext context,
    OrganizationCubit cubit,
    Organization organization, [
    Square? square,
  ]) async {
    // A new square needs a region: the officer's own, or one the General
    // Admin chooses. An existing square never changes its region.
    final ownRegionId = square?.regionId ?? cubit.scope.regionId;
    if (ownRegionId == null && organization.regions.isEmpty) {
      showAppSnackBar(context, 'أضف منطقة أولًا.', isError: true);
      return;
    }
    final values = await showOrgForm(
      context,
      title: square == null ? 'إضافة مربع' : 'تعديل المربع',
      fields: [
        OrgField.text(
          'name',
          'اسم المربع',
          initial: square?.name,
          validator: Validators.name,
        ),
        if (ownRegionId == null)
          OrgField.choice('regionId', 'المنطقة', [
            for (final region in organization.regions) (region.id, region.name),
          ]),
      ],
    );
    if (values == null) return;
    await cubit.saveSquare(
      id: square?.id,
      name: values['name']!,
      regionId: ownRegionId ?? values['regionId']!,
      isActive: square?.isActive ?? true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrganizationView(
      builder: (context, organization, cubit) => OrgList(
        addLabel: 'إضافة مربع',
        onAdd: () => _edit(context, cubit, organization),
        emptyMessage: 'لا توجد مربعات بعد.',
        children: [
          for (final square in organization.squares)
            OrgCard(
              title: square.name,
              isActive: square.isActive,
              lines: [
                if (cubit.scope.isSystem)
                  'المنطقة: ${organization.regionName(square.regionId)}',
                'المشرف: '
                    '${organization.userName(square.supervisorId) ?? 'بدون مشرف'}',
                'المساجد: '
                    '${organization.mosques.where((m) => m.squareId == square.id).length}',
              ],
              actions: [
                (
                  'تعديل الاسم',
                  () => _edit(context, cubit, organization, square),
                ),
                (
                  square.isActive ? 'إيقاف المربع' : 'تفعيل المربع',
                  () => cubit.saveSquare(
                    id: square.id,
                    name: square.name,
                    regionId: square.regionId,
                    isActive: !square.isActive,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The mosques of the scope. A mosque can be moved to another square the
/// administrator manages; its students follow it.
class MosquesView extends StatelessWidget {
  const MosquesView({super.key});

  static String _squareLabel(
    Organization organization,
    OrganizationCubit cubit,
    Square square,
  ) => cubit.scope.isSystem
      ? '${square.name} — ${organization.regionName(square.regionId)}'
      : square.name;

  static Square? _squareOf(Organization organization, String? id) {
    for (final square in organization.squares) {
      if (square.id == id) return square;
    }
    return null;
  }

  Future<void> _edit(
    BuildContext context,
    OrganizationCubit cubit,
    Organization organization, [
    Mosque? mosque,
  ]) async {
    if (organization.squares.isEmpty) {
      showAppSnackBar(context, 'أضف مربعًا أولًا.', isError: true);
      return;
    }
    final values = await showOrgForm(
      context,
      title: mosque == null ? 'إضافة مسجد' : 'تعديل المسجد',
      fields: [
        OrgField.text(
          'name',
          'اسم المسجد',
          initial: mosque?.name,
          validator: Validators.name,
        ),
        OrgField.text(
          'address',
          'العنوان (اختياري)',
          initial: mosque?.address,
          validator: (_) => null,
        ),
        // Moving an existing mosque is a separate action.
        if (mosque == null)
          OrgField.choice('squareId', 'المربع', [
            for (final square in organization.squares)
              (square.id, _squareLabel(organization, cubit, square)),
          ]),
      ],
    );
    if (values == null) return;
    final square = _squareOf(
      organization,
      mosque?.squareId ?? values['squareId'],
    );
    if (square == null) return;
    await cubit.saveMosque(
      id: mosque?.id,
      name: values['name']!,
      address: values['address'] ?? '',
      square: square,
      isActive: mosque?.isActive ?? true,
    );
  }

  Future<void> _move(
    BuildContext context,
    OrganizationCubit cubit,
    Organization organization,
    Mosque mosque,
  ) async {
    // Only the squares in the administrator's scope are offered, so an
    // officer cannot move a mosque out of the region.
    final others = [
      for (final square in organization.squares)
        if (square.id != mosque.squareId) square,
    ];
    if (others.isEmpty) {
      showAppSnackBar(context, 'لا يوجد مربع آخر لنقل المسجد إليه.');
      return;
    }
    final values = await showOrgForm(
      context,
      title: 'نقل ${mosque.name}',
      submitLabel: 'نقل',
      fields: [
        OrgField.choice('squareId', 'المربع الجديد', [
          for (final square in others)
            (square.id, _squareLabel(organization, cubit, square)),
        ]),
      ],
    );
    final square = _squareOf(organization, values?['squareId']);
    if (square == null || !context.mounted) return;
    final confirmed = await confirmOrgAction(
      context,
      title: 'نقل المسجد',
      message:
          'سينتقل المسجد وطلابه الحاليون إلى «${square.name}». '
          'الامتحانات السابقة تبقى على المربع الذي أُجريت فيه.',
      confirmLabel: 'نقل',
    );
    if (confirmed) await cubit.moveMosque(mosque: mosque, square: square);
  }

  @override
  Widget build(BuildContext context) {
    return OrganizationView(
      builder: (context, organization, cubit) => OrgList(
        addLabel: 'إضافة مسجد',
        onAdd: () => _edit(context, cubit, organization),
        emptyMessage: 'لا توجد مساجد بعد.',
        children: [
          for (final mosque in organization.mosques)
            OrgCard(
              title: mosque.name,
              isActive: mosque.isActive,
              lines: [
                if (mosque.address.isNotEmpty) mosque.address,
                'المربع: ${organization.squareName(mosque.squareId)}'
                    '${cubit.scope.isSystem ? ' — ${organization.regionName(mosque.regionId)}' : ''}',
                'الطلاب: '
                    '${organization.users.where((u) => u.role == UserRole.student && u.mosqueId == mosque.id).length}',
              ],
              actions: [
                ('تعديل', () => _edit(context, cubit, organization, mosque)),
                (
                  'نقل إلى مربع آخر',
                  () => _move(context, cubit, organization, mosque),
                ),
                if (_squareOf(organization, mosque.squareId) case final square?)
                  (
                    mosque.isActive ? 'إيقاف المسجد' : 'تفعيل المسجد',
                    () => cubit.saveMosque(
                      id: mosque.id,
                      name: mosque.name,
                      address: mosque.address,
                      square: square,
                      isActive: !mosque.isActive,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
