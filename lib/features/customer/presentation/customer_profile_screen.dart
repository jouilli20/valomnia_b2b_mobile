import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/customer_profile.dart';
import '../providers/customer_provider.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(customerProfileProvider);

    return ColoredBox(
      color: _ProfileColors.background,
      child: RefreshIndicator(
        color: _ProfileColors.primary,
        onRefresh: () async {
          ref.invalidate(customerProfileProvider);
          await ref.read(customerProfileProvider.future);
        },
        child: asyncProfile.when(
          loading: () => const _ProfileStateView(
            icon: Icons.hourglass_top_rounded,
            title: 'Chargement du profil',
            message: 'Veuillez patienter.',
            showProgress: true,
          ),
          error: (error, _) => _ProfileStateView(
            icon: Icons.wifi_off_rounded,
            title: 'Impossible de charger le profil',
            message: error.toString(),
            actionLabel: 'Reessayer',
            onAction: () => ref.invalidate(customerProfileProvider),
          ),
          data: (data) => _ProfileContent(data: data),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.data});

  final CustomerProfileData data;

  @override
  Widget build(BuildContext context) {
    final customer = data.customer;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _UserHeader(
              name: data.user.name ?? 'Utilisateur',
              email: data.user.email ?? 'E-mail non defini',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _SectionPanel(
              title: 'Informations client',
              icon: Icons.storefront_outlined,
              child: _CustomerIdentity(customer: customer),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _SectionPanel(
              title: 'Adresse de facturation',
              icon: Icons.receipt_long_outlined,
              child: _AddressBlock(address: customer.billingAddress),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverToBoxAdapter(
            child: _SectionPanel(
              title: 'Adresse de livraison',
              icon: Icons.local_shipping_outlined,
              child: _AddressBlock(address: customer.shippingAddress),
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
                const Text(
                  'Profil',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ProfileColors.success,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _HeaderValue(label: 'Nom & Prenom', value: name),
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

class _CustomerIdentity extends StatelessWidget {
  const _CustomerIdentity({required this.customer});

  final CustomerProfile customer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final details = _InfoGrid(
          rows: [
            _InfoRowData(Icons.tag_outlined, 'Reference', customer.reference),
            _InfoRowData(Icons.business_outlined, 'Nom', customer.name),
            _InfoRowData(
              Icons.alternate_email_rounded,
              'E-mail',
              customer.email,
            ),
            _InfoRowData(Icons.call_outlined, 'Telephone', customer.phone),
            _InfoRowData(Icons.smartphone_outlined, 'Mobile', customer.mobile),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoValue(
          icon: Icons.place_outlined,
          label: 'Adresse',
          value: address.address,
        ),
        const SizedBox(height: 14),
        _InfoGrid(
          rows: [
            _InfoRowData(
              Icons.markunread_mailbox_outlined,
              'Code postal',
              address.postalCode,
            ),
            _InfoRowData(Icons.location_city_outlined, 'Ville', address.city),
            _InfoRowData(Icons.flag_outlined, 'Pays', address.country),
          ],
        ),
      ],
    );
  }
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
