import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/cart_item.dart';
import '../providers/cart_provider.dart';
import '../../catalog/providers/catalog_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key, this.onContinueShopping});

  final VoidCallback? onContinueShopping;

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final minimum = ref.watch(customerMinOrderTotalProvider);
    final cart = ref.watch(cartControllerProvider);
    final isOnline = ref
        .watch(isOnlineProvider)
        .when(
          data: (value) => value,
          loading: () => true,
          error: (_, _) => true,
        );

    return ColoredBox(
      color: _CartColors.background,
      child: RefreshIndicator(
        color: _CartColors.primary,
        onRefresh: _refresh,
        child: _buildContent(minimum, cart, isOnline: isOnline),
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
    AsyncValue<CustomerCart> cart, {
    required bool isOnline,
  }) {
    final l10n = context.l10n;
    if (minimum.hasError) {
      return _CartStateView(
        icon: Icons.wifi_off_rounded,
        title: l10n.text('minOrderUnavailable'),
        message: minimum.error.toString(),
        actionLabel: l10n.text('retry'),
        onAction: () => ref.invalidate(customerMinOrderTotalProvider),
      );
    }

    if (cart.hasError) {
      return _CartStateView(
        icon: Icons.shopping_cart_outlined,
        title: l10n.text('cartUnavailable'),
        message: cart.error.toString(),
        actionLabel: l10n.text('retry'),
        onAction: () => ref.invalidate(cartControllerProvider),
      );
    }

    final minimumOrderTotal = minimum.value;
    final customerCart = cart.value;

    if (minimumOrderTotal == null || customerCart == null) {
      return _CartStateView(
        icon: Icons.hourglass_top_rounded,
        title: l10n.text('loadingCart'),
        message: l10n.text('pleaseWait'),
        showProgress: true,
      );
    }

    return _CartSummary(
      cart: customerCart,
      minimumOrderTotal: minimumOrderTotal,
      isOnline: isOnline,
      onContinueShopping: widget.onContinueShopping,
    );
  }
}

class _CartSummary extends ConsumerStatefulWidget {
  const _CartSummary({
    required this.cart,
    required this.minimumOrderTotal,
    required this.isOnline,
    required this.onContinueShopping,
  });

  final CustomerCart cart;
  final double minimumOrderTotal;
  final bool isOnline;
  final VoidCallback? onContinueShopping;

  @override
  ConsumerState<_CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends ConsumerState<_CartSummary> {
  final _commentController = TextEditingController();
  DateTime? _deliveryDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = widget.cart;
    final missingAmount = (widget.minimumOrderTotal - cart.total).clamp(
      0.0,
      double.infinity,
    );
    final canSubmit = !cart.isEmpty && missingAmount == 0 && widget.isOnline;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _SummaryPanel(
              cart: cart,
              minimumOrderTotal: widget.minimumOrderTotal,
              missingAmount: missingAmount,
            ),
          ),
        ),
        if (cart.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _EmptyCartView())
        else ...[
          if (!widget.isOnline)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _CartNotice(
                  icon: Icons.wifi_off_rounded,
                  message: l10n.text('cartOffline'),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: missingAmount > 0
                  ? _CartNotice(
                      icon: Icons.info_rounded,
                      message: l10n.missingOrderAmount(
                        _formatDt(missingAmount),
                      ),
                    )
                  : _CartNotice(
                      icon: Icons.check_circle_rounded,
                      message: l10n.text('minOrderReached'),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _CheckoutPanel(
                cart: cart,
                deliveryDate: _deliveryDate,
                commentController: _commentController,
                enabled: !_isSubmitting,
                onPickDeliveryDate: _pickDeliveryDate,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: canSubmit && !_isSubmitting
                      ? () => _confirmSubmitOrder(cart)
                      : null,
                  icon: _isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _isSubmitting
                        ? l10n.text('submitting')
                        : !widget.isOnline
                        ? l10n.text('connectionRequired')
                        : l10n.text('submitOrder'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDeliveryDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2, today.month, today.day),
    );

    if (picked == null || !mounted) return;
    setState(() => _deliveryDate = picked);
  }

  Future<void> _confirmSubmitOrder(CustomerCart cart) async {
    if (!widget.isOnline) {
      _showMessage(context.l10n.text('cartOffline'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.text('confirmation')),
          content: Text(context.l10n.text('confirmOrderQuestion')),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _CartColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.text('no')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _CartColors.successDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.text('yes')),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _submitOrder(cart);
    }
  }

  Future<void> _submitOrder(CustomerCart cart) async {
    final deliveryDate = _deliveryDate;
    if (deliveryDate == null) {
      _showMessage(context.l10n.text('selectDeliveryDate'));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cartOrderApi = ref.read(cartOrderApiProvider);
      final reference = await cartOrderApi.addOrder(
        cart: cart,
        deliveryDate: deliveryDate,
        deliveryComment: _commentController.text,
      );

      try {
        await cartOrderApi.checkoutEmail(cart: cart, reference: reference);
      } catch (_) {
        // La commande reste valide meme si l'e-mail de confirmation echoue.
      }

      final organization = await SecureStorageService.getOrganisation();

      await ref.read(cartControllerProvider.notifier).clear();

      if (!mounted) return;
      _commentController.clear();
      setState(() => _deliveryDate = null);

      await _showOrderSuccessDialog(
        reference: reference,
        organization: organization,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(context.l10n.format('submitOrderFailed', {'error': error}));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showOrderSuccessDialog({
    required String reference,
    required String? organization,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _OrderSuccessDialog(
          reference: reference,
          organization: organization,
          onContinueShopping: () {
            Navigator.of(context).pop();
            widget.onContinueShopping?.call();
          },
        );
      },
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
          SnackBar(content: Text(context.l10n.cartUpdateFailed(error))),
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
    final l10n = context.l10n;
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
          _SummaryRow(
            label: l10n.text('totalQuantity'),
            value: '${cart.itemCount}',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: l10n.text('cartTotal'),
            value: _formatDt(cart.total),
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.text('minimumOrder')} : ${_formatDt(minimumOrderTotal)}',
            style: const TextStyle(
              color: _CartColors.lightText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (!cart.isEmpty && missingAmount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${l10n.text('remainingToAdd')} : ${_formatDt(missingAmount)}',
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

class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel({
    required this.cart,
    required this.deliveryDate,
    required this.commentController,
    required this.enabled,
    required this.onPickDeliveryDate,
  });

  final CustomerCart cart;
  final DateTime? deliveryDate;
  final TextEditingController commentController;
  final bool enabled;
  final VoidCallback onPickDeliveryDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _CartColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CartColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('orderSummary'),
            style: const TextStyle(
              color: _CartColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.text('deliveryInfo'),
            style: const TextStyle(
              color: _CartColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.text('deliveryDate'),
            style: const TextStyle(
              color: _CartColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPickDeliveryDate : null,
            child: InputDecorator(
              decoration: _fieldDecoration(
                hintText: 'jj/mm/aaaa',
                suffixIcon: const Icon(Icons.calendar_month_outlined),
              ),
              child: Text(
                deliveryDate == null
                    ? 'jj/mm/aaaa'
                    : _formatDate(deliveryDate!),
                style: TextStyle(
                  color: deliveryDate == null
                      ? _CartColors.muted
                      : _CartColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.text('comment'),
            style: const TextStyle(
              color: _CartColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          TextField(
            controller: commentController,
            enabled: enabled,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: _fieldDecoration(hintText: l10n.text('comment')),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _CartColors.surfaceBorder),
          const SizedBox(height: 14),
          _SummaryRow(
            label: l10n.text('total'),
            value: _formatDt(cart.total),
            dark: true,
          ),
        ],
      ),
    );
  }
}

class _OrderSuccessDialog extends StatelessWidget {
  const _OrderSuccessDialog({
    required this.reference,
    required this.organization,
    required this.onContinueShopping,
  });

  final String reference;
  final String? organization;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final organizationName = organization?.trim();
    final companyText = organizationName == null || organizationName.isEmpty
        ? l10n.text('companyFallback')
        : organizationName;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: _CartColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _CartColors.successButton,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.text('orderSaved'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _CartColors.ink,
                  fontSize: 22,
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _CartColors.softSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _CartColors.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.text('orderReference'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _CartColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reference,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _CartColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.orderConfirmedBy(companyText),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _CartColors.muted,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: onContinueShopping,
                  style: FilledButton.styleFrom(
                    backgroundColor: _CartColors.successButton,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text(l10n.text('continueShopping')),
                ),
              ),
            ],
          ),
        ),
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
    final l10n = context.l10n;
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
                        label: l10n.text('price'),
                        value: item.unitPrice == null
                            ? item.priceLabel ?? l10n.text('notDefined')
                            : _formatDt(item.unitPrice!),
                      ),
                      _LineAmount(
                        label: l10n.text('subtotal'),
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
                  tooltip: l10n.text('add'),
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
                  tooltip: l10n.text('remove'),
                  icon: Icons.remove_rounded,
                  onPressed: onDecrement,
                ),
                const SizedBox(height: 4),
                _LineIconButton(
                  tooltip: l10n.text('delete'),
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

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year.toString().padLeft(4, '0')}';
}

InputDecoration _fieldDecoration({
  required String hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: _inputBorder(_CartColors.surfaceBorder),
    enabledBorder: _inputBorder(_CartColors.surfaceBorder),
    focusedBorder: _inputBorder(_CartColors.primary, width: 1.4),
    disabledBorder: _inputBorder(_CartColors.surfaceBorder),
  );
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.dark = false,
  });

  final String label;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final labelColor = dark ? _CartColors.ink : _CartColors.lightMuted;
    final valueColor = dark ? _CartColors.ink : _CartColors.lightText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
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
  static const successDark = Color(0xFF198754);
  static const successButton = Color(0xFF3E9678);
  static const successSoft = Color(0xFFE7F5EF);
  static const warning = Color(0xFFF97316);
  static const danger = Color(0xFFE11D48);
  static const dangerSoft = Color(0xFFFFE4EA);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
}
