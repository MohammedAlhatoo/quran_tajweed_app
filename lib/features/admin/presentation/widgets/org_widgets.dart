import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/organization.dart';
import '../state/organization_cubit.dart';

/// Shows the organization held by the [OrganizationCubit] above it, with its
/// loading and error states, and reports the outcome of every change.
class OrganizationView extends StatelessWidget {
  const OrganizationView({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    Organization organization,
    OrganizationCubit cubit,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationCubit, OrganizationState>(
      builder: (context, state) {
        final cubit = context.read<OrganizationCubit>();
        final organization = state.organization;
        if (organization == null) {
          final error = state.loadError;
          return error == null
              ? const AppLoadingView()
              : AppMessageView(message: error, onRetry: cubit.load);
        }

        return Column(
          children: [
            if (state.isBusy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: AbsorbPointer(
                absorbing: state.isBusy,
                child: RefreshIndicator(
                  onRefresh: cubit.load,
                  child: builder(context, organization, cubit),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shows the outcome of the organization's changes as snack bars. It wraps
/// the whole area once, so a message appears whichever tab is open.
class OrganizationMessages extends StatelessWidget {
  const OrganizationMessages({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganizationCubit, OrganizationState>(
      listenWhen: (previous, current) => current.message != null,
      listener: (context, state) =>
          showAppSnackBar(context, state.message!, isError: state.isError),
      child: child,
    );
  }
}

/// A scrollable list of [children] under an optional "add" button, or
/// [emptyMessage] when there are none.
class OrgList extends StatelessWidget {
  const OrgList({
    super.key,
    required this.children,
    required this.emptyMessage,
    this.header,
    this.addLabel,
    this.onAdd,
  });

  final List<Widget> children;
  final String emptyMessage;

  /// Shown above the list, for example a filter.
  final Widget? header;
  final String? addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Always scrollable, so pulling to refresh works on a short list.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (addLabel case final label?) ...[
          AppButton(label: label, secondary: true, onPressed: onAdd),
          const SizedBox(height: 12),
        ],
        if (header case final header?) ...[header, const SizedBox(height: 12)],
        if (children.isEmpty)
          AppMessageView(message: emptyMessage)
        else
          for (final child in children) ...[child, const SizedBox(height: 12)],
      ],
    );
  }
}

/// An action in the menu of an [OrgCard].
typedef OrgAction = (String label, VoidCallback onSelected);

/// A region, square, mosque or account in a management list.
class OrgCard extends StatelessWidget {
  const OrgCard({
    super.key,
    required this.title,
    required this.lines,
    required this.isActive,
    this.actions = const [],
  });

  final String title;

  /// The details under the title.
  final List<String> lines;
  final bool isActive;
  final List<OrgAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(15, 12, 4, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cairo(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          lineHeight: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    isActive
                        ? const StatusChip('نشط', tone: StatusTone.success)
                        : const StatusChip('موقوف', tone: StatusTone.danger),
                  ],
                ),
                for (final line in lines)
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cairo(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.muted,
                      lineHeight: 18,
                    ),
                  ),
              ],
            ),
          ),
          if (actions.isEmpty)
            const SizedBox(width: 11)
          else
            PopupMenuButton<int>(
              tooltip: 'إجراءات',
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
              onSelected: (index) => actions[index].$2(),
              itemBuilder: (context) => [
                for (final (index, (label, _)) in actions.indexed)
                  PopupMenuItem(value: index, child: Text(label)),
              ],
            ),
        ],
      ),
    );
  }
}

/// A field of [showOrgForm]: free text, or one choice from [options].
class OrgField {
  const OrgField.text(
    this.key,
    this.label, {
    this.initial,
    this.validator,
    this.keyboardType,
  }) : options = null,
       optional = false;

  const OrgField.choice(
    this.key,
    this.label,
    List<(String id, String label)> this.options, {
    this.initial,
    this.optional = false,
  }) : validator = null,
       keyboardType = null;

  final String key;
  final String label;
  final String? initial;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  /// The choices as (ID, label), or null for a text field.
  final List<(String id, String label)>? options;

  /// Whether a choice may be left empty.
  final bool optional;
}

/// Asks for [fields] in a dialog. Returns the values by field key, with the
/// chosen ID for a choice, or null when the dialog is dismissed.
Future<Map<String, String?>?> showOrgForm(
  BuildContext context, {
  required String title,
  required List<OrgField> fields,
  String submitLabel = 'حفظ',
}) {
  return showDialog<Map<String, String?>>(
    context: context,
    builder: (context) =>
        _OrgFormDialog(title: title, fields: fields, submitLabel: submitLabel),
  );
}

/// Asks to confirm [message]. Returns true when confirmed.
Future<bool> confirmOrgAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _OrgFormDialog extends StatefulWidget {
  const _OrgFormDialog({
    required this.title,
    required this.fields,
    required this.submitLabel,
  });

  final String title;
  final List<OrgField> fields;
  final String submitLabel;

  @override
  State<_OrgFormDialog> createState() => _OrgFormDialogState();
}

class _OrgFormDialogState extends State<_OrgFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.fields)
      if (field.options == null)
        field.key: TextEditingController(text: field.initial),
  };
  late final Map<String, String?> _choices = {
    for (final field in widget.fields)
      if (field.options case final options?)
        // An initial value that is no longer offered is dropped.
        field.key: options.any((option) => option.$1 == field.initial)
            ? field.initial
            : null,
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      for (final MapEntry(:key, :value) in _controllers.entries)
        key: value.text.trim(),
      ..._choices,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildField(field),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }

  Widget _buildField(OrgField field) {
    final options = field.options;
    if (options == null) {
      return AppTextField(
        controller: _controllers[field.key]!,
        hintText: field.label,
        keyboardType: field.keyboardType,
        validator:
            field.validator ??
            (value) => value == null || value.trim().isEmpty
                ? 'هذا الحقل مطلوب'
                : null,
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _choices[field.key],
      isExpanded: true,
      style: AppTextStyles.body,
      borderRadius: BorderRadius.circular(12),
      decoration: AppTextField.decoration(hintText: field.label),
      items: [
        for (final (id, label) in options)
          DropdownMenuItem(
            value: id,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) => _choices[field.key] = value,
      validator: (value) =>
          value == null && !field.optional ? 'اختر ${field.label}' : null,
    );
  }
}
