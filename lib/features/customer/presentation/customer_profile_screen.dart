import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/customer_profile.dart';
import '../providers/customer_provider.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final asyncProfile = ref.watch(customerProfileProvider);
    final isOnline = ref
        .watch(isOnlineProvider)
        .when(
          data: (value) => value,
          loading: () => true,
          error: (_, _) => true,
        );

    return ColoredBox(
      color: _ProfileColors.background,
      child: RefreshIndicator(
        color: _ProfileColors.primary,
        onRefresh: () async {
          ref.invalidate(customerProfileProvider);
          await ref.read(customerProfileProvider.future);
        },
        child: asyncProfile.when(
          loading: () => _ProfileStateView(
            icon: Icons.hourglass_top_rounded,
            title: l10n.text('loadingProfile'),
            message: l10n.text('pleaseWait'),
            showProgress: true,
          ),
          error: (error, _) => _ProfileStateView(
            icon: Icons.wifi_off_rounded,
            title: l10n.text('profileLoadFailed'),
            message: error.toString(),
            actionLabel: l10n.text('retry'),
            onAction: () => ref.invalidate(customerProfileProvider),
          ),
          data: (data) => _ProfileContent(data: data, isOnline: isOnline),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.data, required this.isOnline});

  final CustomerProfileData data;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final customer = data.customer;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _UserHeader(
              name: data.user.name ?? l10n.text('userFallback'),
              email: data.user.email ?? l10n.text('emailNotDefined'),
            ),
          ),
        ),
        if (!isOnline)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _OfflineNotice(message: l10n.text('profileOffline')),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _SectionPanel(
              title: l10n.text('customerInfo'),
              icon: Icons.storefront_outlined,
              child: _CustomerIdentity(customer: customer),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _SectionPanel(
              title: l10n.text('billingAddress'),
              icon: Icons.receipt_long_outlined,
              child: _AddressBlock(address: customer.billingAddress),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverToBoxAdapter(
            child: _SectionPanel(
              title: l10n.text('shippingAddress'),
              icon: Icons.local_shipping_outlined,
              child: _AddressBlock(address: customer.shippingAddress),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverToBoxAdapter(
            child: _SectionPanel(
              title: l10n.text('security'),
              icon: Icons.lock_outline_rounded,
              child: _PasswordUpdateForm(data: data, isOnline: isOnline),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ProfileColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ProfileColors.darkBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000614),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _ProfileColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _ProfileColors.success.withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _ProfileColors.success,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.text('profile'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ProfileColors.success,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _HeaderValue(label: l10n.text('fullName'), value: name),
                const SizedBox(height: 10),
                _HeaderValue(label: 'E-mail', value: email),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderValue extends StatelessWidget {
  const _HeaderValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label :',
          style: const TextStyle(
            color: _ProfileColors.lightMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: const TextStyle(
            color: _ProfileColors.lightText,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ProfileColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ProfileColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _ProfileColors.successDark, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProfileColors.successDark,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF97316)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFFB45309),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerIdentity extends StatelessWidget {
  const _CustomerIdentity({required this.customer});

  final CustomerProfile customer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final details = _InfoGrid(
          rows: [
            _InfoRowData(
              Icons.tag_outlined,
              l10n.text('reference'),
              customer.reference,
            ),
            _InfoRowData(
              Icons.business_outlined,
              l10n.text('name'),
              customer.name,
            ),
            _InfoRowData(
              Icons.alternate_email_rounded,
              l10n.text('email'),
              customer.email,
            ),
            _InfoRowData(
              Icons.call_outlined,
              l10n.text('phone'),
              customer.phone,
            ),
            _InfoRowData(
              Icons.smartphone_outlined,
              l10n.text('mobile'),
              customer.mobile,
            ),
          ],
        );

        return details;
      },
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.rows});

  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 420 ? 2 : 1;
        return Wrap(
          spacing: 16,
          runSpacing: 13,
          children: [
            for (final row in rows)
              SizedBox(
                width: columnCount == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 2,
                child: _InfoValue(
                  icon: row.icon,
                  label: row.label,
                  value: row.value,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.address});

  final CustomerAddress address;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoValue(
          icon: Icons.place_outlined,
          label: l10n.text('address'),
          value: address.address,
        ),
        const SizedBox(height: 14),
        _InfoGrid(
          rows: [
            _InfoRowData(
              Icons.markunread_mailbox_outlined,
              l10n.text('postalCode'),
              address.postalCode,
            ),
            _InfoRowData(
              Icons.location_city_outlined,
              l10n.text('city'),
              address.city,
            ),
            _InfoRowData(
              Icons.flag_outlined,
              l10n.text('country'),
              address.country,
            ),
          ],
        ),
      ],
    );
  }
}

class _PasswordUpdateForm extends ConsumerStatefulWidget {
  const _PasswordUpdateForm({required this.data, required this.isOnline});

  final CustomerProfileData data;
  final bool isOnline;

  @override
  ConsumerState<_PasswordUpdateForm> createState() =>
      _PasswordUpdateFormState();
}

class _PasswordUpdateFormState extends ConsumerState<_PasswordUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('accountInternetRequired'))),
      );
      return;
    }

    final form = _formKey.currentState;
    if (form == null || !form.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final l10n = context.l10n;
      final organisation = (await SecureStorageService.getOrganisation())
          ?.trim();
      final storedUsername = (await SecureStorageService.getUsername())?.trim();
      final email = _firstNonEmpty([widget.data.user.email, storedUsername]);
      final userName = _firstNonEmpty([
        widget.data.user.name,
        widget.data.customer.name,
        email,
      ]);

      if (organisation == null || organisation.isEmpty) {
        throw StateError(l10n.text('organizationMissing'));
      }
      if (email == null || email.isEmpty) {
        throw StateError(l10n.text('userEmailMissing'));
      }
      if (userName == null || userName.isEmpty) {
        throw StateError(l10n.text('userNameMissing'));
      }

      final profile = await ref
          .read(userProfileApiProvider)
          .updateConnectedUser(
            organisation: organisation,
            email: email,
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
            userName: userName,
          );

      if (profile.email != null) {
        await SecureStorageService.saveUsername(profile.email!);
      }

      if (!mounted) return;
      _oldPasswordController.clear();
      _newPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('passwordUpdated'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.passwordUpdateFailed(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PasswordField(
            controller: _oldPasswordController,
            label: l10n.text('oldPassword'),
            hint: l10n.text('oldPasswordHint'),
            enabled: widget.isOnline && !_isSubmitting,
            isVisible: _showOldPassword,
            textInputAction: TextInputAction.next,
            onVisibilityChanged: () {
              setState(() => _showOldPassword = !_showOldPassword);
            },
          ),
          const SizedBox(height: 14),
          _PasswordField(
            controller: _newPasswordController,
            label: l10n.text('newPassword'),
            hint: l10n.text('newPasswordHint'),
            enabled: widget.isOnline && !_isSubmitting,
            isVisible: _showNewPassword,
            textInputAction: TextInputAction.done,
            onVisibilityChanged: () {
              setState(() => _showNewPassword = !_showNewPassword);
            },
            onSubmitted: (_) => _submit(),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return l10n.text('fieldRequired');
              if (text == _oldPasswordController.text.trim()) {
                return l10n.text('newPasswordMustDiffer');
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.isOnline && !_isSubmitting ? _submit : null,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _isSubmitting ? l10n.text('validating') : l10n.text('validate'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.isVisible,
    required this.onVisibilityChanged,
    required this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final bool isVisible;
  final VoidCallback onVisibilityChanged;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: !isVisible,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator:
          validator ??
          (value) {
            final text = value?.trim() ?? '';
            return text.isEmpty ? context.l10n.text('fieldRequired') : null;
          },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: isVisible
              ? context.l10n.text('hide')
              : context.l10n.text('show'),
          onPressed: enabled ? onVisibilityChanged : null,
          icon: Icon(
            isVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final text = value?.trim();
    if (text != null && text.isNotEmpty) return text;
  }

  return null;
}

class _InfoValue extends StatelessWidget {
  const _InfoValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _ProfileColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _ProfileColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label :',
                style: const TextStyle(
                  color: _ProfileColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue == null || displayValue.isEmpty
                    ? '-'
                    : displayValue,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: displayValue == null || displayValue.isEmpty
                      ? _ProfileColors.empty
                      : _ProfileColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRowData {
  const _InfoRowData(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String? value;
}

class _ProfileStateView extends StatelessWidget {
  const _ProfileStateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showProgress)
                    const CircularProgressIndicator(
                      color: _ProfileColors.primary,
                    )
                  else
                    Icon(icon, color: _ProfileColors.primary, size: 38),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ProfileColors.lightText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ProfileColors.lightMuted,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileColors {
  const _ProfileColors._();

  static const background = Color(0xFF031126);
  static const panel = Color(0xFF061B3B);
  static const darkBorder = Color(0xFF17335D);
  static const lightText = Color(0xFFF8FAFC);
  static const lightMuted = Color(0xFF9FB1CC);
  static const surface = Colors.white;
  static const border = Color(0xFFE5EAF1);
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEAF2FF);
  static const success = Color(0xFF22C55E);
  static const successDark = Color(0xFF2F8E72);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const empty = Color(0xFF94A3B8);
}
