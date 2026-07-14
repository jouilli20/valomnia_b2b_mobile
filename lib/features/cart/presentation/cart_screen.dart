import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cart_item.dart';
import '../providers/cart_provider.dart';
import '../../catalog/providers/catalog_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final minimum = ref.watch(customerMinOrderTotalProvider);
    final cart = ref.watch(cartControllerProvider);

    return ColoredBox(
      color: _CartColors.background,
      child: RefreshIndicator(
        color: _CartColors.primary,
        onRefresh: _refresh,
        child: _buildContent(minimum, cart),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(customerMinOrderTotalProvider);
    ref.invalidate(cartControllerProvider);
    await Future.wait<Object?>([
      ref.read(customerMinOrderTotalProvider.future),
      ref.read(cartControllerProvider.future),
    ]);
  }

  Widget _buildContent(
    AsyncValue<double> minimum,
    AsyncValue<CustomerCart> cart,
  ) {
    if (minimum.hasError) {
      return _CartStateView(
        icon: Icons.wifi_off_rounded,
        title: 'Minimum de commande indisponible',
        message: minimum.error.toString(),
        actionLabel: 'Reessayer',
        onAction: () => ref.invalidate(customerMinOrderTotalProvider),
      );
    }

    if (cart.hasError) {
      return _CartStateView(
        icon: Icons.shopping_cart_outlined,
        title: 'Panier indisponible',
        message: cart.error.toString(),
        actionLabel: 'Reessayer',
        onAction: () => ref.invalidate(cartControllerProvider),
      );
    }

    final minimumOrderTotal = minimum.value;
    final customerCart = cart.value;

    if (minimumOrderTotal == null || customerCart == null) {
      return const _CartStateView(
        icon: Icons.hourglass_top_rounded,
        title: 'Chargement du panier',
        message: 'Veuillez patienter.',
        showProgress: true,
      );
    }

    return _CartSummary(
      cart: customerCart,
      minimumOrderTotal: minimumOrderTotal,
    );
  }
}

class _CartSummary extends ConsumerWidget {
  const _CartSummary({required this.cart, required this.minimumOrderTotal});

  final CustomerCart cart;
  final double minimumOrderTotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missingAmount = (minimumOrderTotal - cart.total).clamp(
      0.0,
      double.infinity,
    );
    final canSubmit = !cart.isEmpty && missingAmount == 0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _SummaryPanel(
              cart: cart,
              minimumOrderTotal: minimumOrderTotal,
              missingAmount: missingAmount,
            ),
          ),
        ),
        if (cart.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyCartView(),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: missingAmount > 0
                  ? _CartNotice(
                      icon: Icons.info_rounded,
                      message:
                          'Il manque ${_formatDt(missingAmount)} pour atteindre le minimum de commande.',
                    )
                  : const _CartNotice(
                      icon: Icons.check_circle_rounded,
                      message: 'Le minimum de commande est atteint.',
                      success: true,
                    ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            sliver: SliverList.separated(
              itemCount: cart.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return _CartLineTile(
                  item: item,
                  onIncrement: () => _runCartAction(
                    context,
                    ref,
                    (controller) =>
                        controller.addItem(item.copyWith(quantity: 1)),
                  ),
                  onDecrement: () => _runCartAction(
                    context,
                    ref,
                    (controller) => controller.decrementItem(item.productKey),
                  ),
                  onRemove: () => _runCartAction(
                    context,
                    ref,
                    (controller) => controller.removeItem(item.productKey),
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: canSubmit ? () {} : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('VALIDER LA COMMANDE'),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _runCartAction(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(CartController controller) action,
  ) {
    unawaited(() async {
      try {
        await action(ref.read(cartControllerProvider.notifier));
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de mettre a jour le panier: $error'),
          ),
        );
      }
    }());
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.cart,
    required this.minimumOrderTotal,
    required this.missingAmount,
  });

  final CustomerCart cart;
  final double minimumOrderTotal;
  final double missingAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _CartColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CartColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: 'Quantite totale', value: '${cart.itemCount}'),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Total du panier', value: _formatDt(cart.total)),
          const SizedBox(height: 12),
          Text(
            'Minimum de commande : ${_formatDt(minimumOrderTotal)}',
            style: const TextStyle(
              color: _CartColors.lightText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (!cart.isEmpty && missingAmount > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Reste a ajouter : ${_formatDt(missingAmount)}',
              style: const TextStyle(
                color: _CartColors.warning,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _CartColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _CartColors.surfaceBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.square(
                dimension: 66,
                child: _CartLineImage(imageUrl: item.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _CartColors.ink,
                      fontSize: 14,
                      height: 1.16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (item.reference != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.reference!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CartColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _LineAmount(
                        label: 'Prix',
                        value: item.unitPrice == null
                            ? item.priceLabel ?? 'Non defini'
                            : _formatDt(item.unitPrice!),
                      ),
                      _LineAmount(
                        label: 'Sous-total',
                        value: _formatDt(item.lineTotal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LineIconButton(
                  tooltip: 'Ajouter',
                  icon: Icons.add_rounded,
                  onPressed: onIncrement,
                ),
                Container(
                  width: 34,
                  height: 30,
                  alignment: Alignment.center,
                  child: Text(
                    item.quantity.toString(),
                    style: const TextStyle(
                      color: _CartColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _LineIconButton(
                  tooltip: 'Retirer',
                  icon: Icons.remove_rounded,
                  onPressed: onDecrement,
                ),
                const SizedBox(height: 4),
                _LineIconButton(
                  tooltip: 'Supprimer',
                  icon: Icons.delete_outline_rounded,
                  danger: true,
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineImage extends StatelessWidget {
  const _CartLineImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const _CartImagePlaceholder();

    return ColoredBox(
      color: _CartColors.softSurface,
      child: Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _CartImagePlaceholder(),
        loadingBuilder: (context, child, progress) {
          return progress == null ? child : const _CartImagePlaceholder();
        },
      ),
    );
  }
}

class _CartImagePlaceholder extends StatelessWidget {
  const _CartImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _CartColors.softSurface,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: _CartColors.muted,
          size: 28,
        ),
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
          color: _CartColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: '$label : '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: _CartColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineIconButton extends StatelessWidget {
  const _LineIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final foreground = danger ? _CartColors.danger : _CartColors.primary;
    final background = danger
        ? _CartColors.dangerSoft
        : _CartColors.primarySoft;

    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(34),
          minimumSize: const Size.square(34),
          backgroundColor: background,
          foregroundColor: foreground,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_shopping_cart_outlined,
              color: _CartColors.primary,
              size: 42,
            ),
            SizedBox(height: 16),
            Text(
              'Panier vide',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _CartColors.lightText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Ajoutez des produits depuis le catalogue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _CartColors.lightMuted,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDt(double value) {
  return '${value.toStringAsFixed(3)} DT';
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _CartColors.lightMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: _CartColors.lightText,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CartNotice extends StatelessWidget {
  const _CartNotice({
    required this.icon,
    required this.message,
    this.success = false,
  });

  final IconData icon;
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? _CartColors.success : _CartColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13.5,
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

class _CartStateView extends StatelessWidget {
  const _CartStateView({
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
                    const CircularProgressIndicator(color: _CartColors.primary)
                  else
                    Icon(icon, color: _CartColors.primary, size: 38),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _CartColors.lightText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _CartColors.lightMuted,
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

class _CartColors {
  const _CartColors._();

  static const background = Color(0xFF031126);
  static const panel = Color(0xFF061B3B);
  static const border = Color(0xFF17335D);
  static const lightText = Color(0xFFF8FAFC);
  static const lightMuted = Color(0xFF9FB1CC);
  static const surface = Colors.white;
  static const softSurface = Color(0xFFF1F5F9);
  static const surfaceBorder = Color(0xFFE5EAF1);
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEAF2FF);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF97316);
  static const danger = Color(0xFFE11D48);
  static const dangerSoft = Color(0xFFFFE4EA);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
}
