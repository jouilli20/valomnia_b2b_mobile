import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order_history.dart';
import '../providers/orders_provider.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  Future<void> _refreshOrders() async {
    ref.invalidate(orderHistoryProvider);
    await ref.read(orderHistoryProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _OrderColors.background,
      child: ref
          .watch(orderHistoryProvider)
          .when(
            loading: () => const _OrderStateView(
              icon: Icons.hourglass_top_rounded,
              title: 'Chargement des commandes',
              message: 'Veuillez patienter.',
              showProgress: true,
            ),
            error: (error, _) => _OrderStateView(
              icon: Icons.wifi_off_rounded,
              title: 'Impossible de charger les commandes',
              message: error.toString(),
              actionLabel: 'Reessayer',
              onAction: () => ref.invalidate(orderHistoryProvider),
            ),
            data: _buildContent,
          ),
    );
  }

  Widget _buildContent(List<CustomerOrder> orders) {
    return RefreshIndicator(
      color: _OrderColors.primary,
      onRefresh: _refreshOrders,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (orders.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _OrderStateView(
                icon: Icons.assignment_outlined,
                title: 'Aucune commande',
                message: 'Tirez vers le bas pour actualiser l historique.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderTile(
                    order: order,
                    onTap: () => _showOrderDetails(order),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showOrderDetails(CustomerOrder order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _OrderColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _OrderDetailsSheet(order: order),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final CustomerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _OrderColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _OrderColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _OrderColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(status: order.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _OrderFact(
                    icon: Icons.event_available_outlined,
                    label: 'Creation',
                    value: _formatOptionalDate(order.createdAt),
                  ),
                  _OrderFact(
                    icon: Icons.local_shipping_outlined,
                    label: 'Livraison',
                    value: _formatOptionalDate(order.deliveryDate),
                  ),
                  _OrderFact(
                    icon: Icons.payments_outlined,
                    label: 'Total',
                    value: order.totalLabel ?? 'Non defini',
                  ),
                  _OrderFact(
                    icon: Icons.inventory_2_outlined,
                    label: 'Articles',
                    value: order.orderLines.length.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Voir details'),
                  style: TextButton.styleFrom(
                    foregroundColor: _OrderColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderFact extends StatelessWidget {
  const _OrderFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _OrderColors.muted, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _OrderColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _OrderColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final lines = order.orderLines;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        builder: (context, controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _OrderColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.reference,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _OrderColors.ink,
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(status: order.status),
                ],
              ),
              const SizedBox(height: 18),
              _DetailRow(
                icon: Icons.event_available_outlined,
                label: 'Date de creation',
                value: _formatOptionalDate(order.createdAt),
              ),
              _DetailRow(
                icon: Icons.local_shipping_outlined,
                label: 'Date de livraison',
                value: _formatOptionalDate(order.deliveryDate),
              ),
              _DetailRow(
                icon: Icons.payments_outlined,
                label: 'Total',
                value: order.totalLabel ?? 'Non defini',
              ),
              _DetailRow(
                icon: Icons.inventory_2_outlined,
                label: 'Nombre d articles',
                value: lines.length.toString(),
              ),
              if (lines.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Articles',
                  style: TextStyle(
                    color: _OrderColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                for (final line in lines) ...[
                  _OrderLineTile(line: line),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _OrderColors.muted, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 136,
            child: Text(
              label,
              style: const TextStyle(
                color: _OrderColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _OrderColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLineTile extends StatelessWidget {
  const _OrderLineTile({required this.line});

  final Map<String, dynamic> line;

  @override
  Widget build(BuildContext context) {
    final name =
        _lineText(line, const ['productName', 'name', 'label', 'itemName']) ??
        'Article';
    final reference = _lineText(line, const [
      'productReference',
      'itemReference',
      'reference',
      'ref',
    ]);
    final quantity =
        _lineText(line, const ['quantity', 'salesQty', 'qty']) ?? '1';
    final unitPrice = _lineMoney(line, const [
      'formattedUnitPrice',
      'unitPrice',
      'price',
    ]);
    final finalPrice = _lineMoney(line, const [
      'finalPrice',
      'lineTotal',
      'total',
    ]);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _OrderColors.softSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _OrderColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _OrderColors.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (reference != null) ...[
            const SizedBox(height: 4),
            Text(
              reference,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _OrderColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _LineAmount(label: 'Qte', value: quantity),
              if (unitPrice != null)
                _LineAmount(label: 'Prix', value: unitPrice),
              if (finalPrice != null)
                _LineAmount(label: 'Total', value: finalPrice),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineAmount extends StatelessWidget {
  const _LineAmount({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _OrderColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        children: [
          TextSpan(text: '$label : '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: _OrderColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStateView extends StatelessWidget {
  const _OrderStateView({
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
                    const CircularProgressIndicator(color: _OrderColors.primary)
                  else
                    Icon(icon, color: _OrderColors.primary, size: 38),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _OrderColors.lightText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _OrderColors.lightMuted,
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

String _formatOptionalDate(DateTime? value) {
  if (value == null) return 'Non defini';

  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year.toString().padLeft(4, '0')}';
}

String? _lineText(Map<String, dynamic> line, List<String> keys) {
  for (final key in keys) {
    final value = line[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value != 'null') {
      return value;
    }
  }

  return null;
}

String? _lineMoney(Map<String, dynamic> line, List<String> keys) {
  for (final key in keys) {
    final value = line[key];
    if (value is num) return '${value.toStringAsFixed(3)} DT';

    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text != 'null') {
      return text.contains('DT') || text.contains('TND') ? text : '$text DT';
    }
  }

  return null;
}

Color _statusColor(String status) {
  final value = status.trim().toLowerCase();

  if (value.contains('annul') ||
      value.contains('cancel') ||
      value.contains('reject')) {
    return _OrderColors.danger;
  }

  if (value.contains('valid') ||
      value.contains('confirm') ||
      value.contains('paid') ||
      value.contains('livr')) {
    return _OrderColors.success;
  }

  if (value.contains('attente') ||
      value.contains('pending') ||
      value.contains('wait')) {
    return _OrderColors.warning;
  }

  return _OrderColors.primary;
}

class _OrderColors {
  const _OrderColors._();

  static const background = Color(0xFF031126);
  static const lightText = Color(0xFFF8FAFC);
  static const lightMuted = Color(0xFF9FB1CC);
  static const surface = Colors.white;
  static const softSurface = Color(0xFFF8FAFC);
  static const surfaceBorder = Color(0xFFE5EAF1);
  static const primary = Color(0xFF2563EB);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF97316);
  static const danger = Color(0xFFE11D48);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
}
