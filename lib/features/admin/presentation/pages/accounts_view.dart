import 'package:flutter/material.dart';

import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/organization.dart';
import '../state/organization_cubit.dart';
import '../widgets/org_widgets.dart';

/// The accounts of the scope with one of [roles]. Region officers and square
/// supervisors can be created and linked here; students register themselves
/// and can only be suspended or reactivated.
class AccountsView extends StatefulWidget {
  const AccountsView({super.key, required this.roles});

  /// The roles the administrator manages, in the order they are offered.
  final List<UserRole> roles;

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView> {
  late UserRole _role = widget.roles.first;

  static String _roleLabel(UserRole role) => switch (role) {
    UserRole.regionOfficer => 'مسؤولو المناطق',
    UserRole.squareSupervisor => 'المشرفون',
    UserRole.student => 'الطلاب',
    UserRole.generalAdmin => 'المديرون',
  };

  static List<(String, String)> _squareOptions(
    Organization organization,
    OrganizationCubit cubit,
    AppUser? supervisor,
  ) => [
    for (final square in organization.squaresOpenTo(supervisor))
      (
        square.id,
        cubit.scope.isSystem
            ? '${square.name} — ${organization.regionName(square.regionId)}'
            : square.name,
      ),
  ];

  static Square? _squareOf(Organization organization, String? id) {
    for (final square in organization.squares) {
      if (square.id == id) return square;
    }
    return null;
  }

  Future<void> _create(
    OrganizationCubit cubit,
    Organization organization,
  ) async {
    final isOfficer = _role == UserRole.regionOfficer;
    final scopes = isOfficer
        ? [for (final region in organization.regions) (region.id, region.name)]
        : _squareOptions(organization, cubit, null);
    if (scopes.isEmpty) {
      showAppSnackBar(
        context,
        isOfficer ? 'أضف منطقة أولًا.' : 'لا يوجد مربع بدون مشرف. أضف مربعًا.',
        isError: true,
      );
      return;
    }
    final values = await showOrgForm(
      context,
      title: isOfficer ? 'إضافة مسؤول منطقة' : 'إضافة مشرف مربع',
      submitLabel: 'إنشاء الحساب',
      fields: [
        OrgField.text('name', 'الاسم', validator: Validators.name),
        OrgField.text(
          'email',
          'البريد الإلكتروني',
          validator: Validators.email,
          keyboardType: TextInputType.emailAddress,
        ),
        OrgField.text(
          'phone',
          'رقم الهاتف',
          validator: Validators.phone,
          keyboardType: TextInputType.phone,
        ),
        OrgField.choice('scope', isOfficer ? 'المنطقة' : 'المربع', scopes),
      ],
    );
    if (values == null) return;
    final square = isOfficer ? null : _squareOf(organization, values['scope']);
    final regionId = isOfficer ? values['scope'] : square?.regionId;
    if (regionId == null) return;
    // No password is chosen here: the owner sets it from the emailed link.
    await cubit.createStaff(
      name: values['name']!,
      email: values['email']!,
      phone: values['phone']!,
      role: _role,
      regionId: regionId,
      squareId: square?.id,
    );
  }

  Future<void> _assign(
    OrganizationCubit cubit,
    Organization organization,
    AppUser user,
  ) async {
    if (user.role == UserRole.regionOfficer) {
      final values = await showOrgForm(
        context,
        title: 'منطقة ${user.name}',
        fields: [
          OrgField.choice('regionId', 'المنطقة', [
            for (final region in organization.regions) (region.id, region.name),
          ], initial: user.regionId),
        ],
      );
      final regionId = values?['regionId'];
      if (regionId != null) {
        await cubit.assignStaff(user: user, regionId: regionId);
      }
      return;
    }

    final values = await showOrgForm(
      context,
      title: 'مربع ${user.name}',
      fields: [
        // Left empty, the supervisor has no square and reviews nothing.
        OrgField.choice(
          'squareId',
          'المربع (اتركه فارغًا لإلغاء الربط)',
          _squareOptions(organization, cubit, user),
          initial: user.squareId,
          optional: true,
        ),
      ],
    );
    if (values == null) return;
    final square = _squareOf(organization, values['squareId']);
    final regionId = square?.regionId ?? user.regionId;
    if (regionId == null) return;
    await cubit.assignStaff(
      user: user,
      regionId: regionId,
      squareId: square?.id,
    );
  }

  Future<void> _toggleActive(OrganizationCubit cubit, AppUser user) async {
    final confirmed = await confirmOrgAction(
      context,
      title: user.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب',
      message: user.isActive
          ? 'لن يتمكن ${user.name} من تسجيل الدخول حتى يُفعَّل الحساب.'
          : 'سيتمكن ${user.name} من تسجيل الدخول من جديد.',
      confirmLabel: user.isActive ? 'إيقاف' : 'تفعيل',
    );
    if (confirmed) {
      await cubit.setAccountActive(user: user, isActive: !user.isActive);
    }
  }

  List<String> _scopeLines(
    Organization organization,
    OrganizationCubit cubit,
    AppUser user,
  ) {
    final region = cubit.scope.isSystem
        ? ' — ${organization.regionName(user.regionId)}'
        : '';
    return switch (user.role) {
      UserRole.regionOfficer => [
        'المنطقة: ${organization.regionName(user.regionId)}',
      ],
      UserRole.squareSupervisor => [
        'المربع: ${organization.squareName(user.squareId)}$region',
      ],
      _ => [
        'المسجد: ${organization.mosqueName(user.mosqueId)}',
        'المربع: ${organization.squareName(user.squareId)}$region',
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = _role != UserRole.student;

    return OrganizationView(
      builder: (context, organization, cubit) => OrgList(
        addLabel: switch (_role) {
          UserRole.regionOfficer => 'إضافة مسؤول منطقة',
          UserRole.squareSupervisor => 'إضافة مشرف مربع',
          _ => null,
        },
        onAdd: () => _create(cubit, organization),
        header: widget.roles.length < 2
            ? null
            : Wrap(
                spacing: 8,
                children: [
                  for (final role in widget.roles)
                    ChoiceChip(
                      label: Text(_roleLabel(role)),
                      selected: role == _role,
                      onSelected: (_) => setState(() => _role = role),
                    ),
                ],
              ),
        emptyMessage: 'لا توجد حسابات.',
        children: [
          for (final user in organization.usersWithRole(_role))
            OrgCard(
              title: user.name,
              isActive: user.isActive,
              lines: [
                user.email,
                if (user.phone case final phone? when phone.isNotEmpty) phone,
                ..._scopeLines(organization, cubit, user),
              ],
              actions: [
                if (isStaff) ...[
                  (
                    user.role == UserRole.regionOfficer
                        ? 'تغيير المنطقة'
                        : 'تغيير المربع',
                    () => _assign(cubit, organization, user),
                  ),
                  (
                    'إرسال رابط كلمة المرور',
                    () => cubit.sendPasswordReset(user.email),
                  ),
                ],
                (
                  user.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب',
                  () => _toggleActive(cubit, user),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
