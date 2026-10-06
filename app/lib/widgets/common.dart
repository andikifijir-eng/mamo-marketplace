import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';

final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

/// Placeholder gambar produk (dipakai kalau produk belum punya foto).
class ProductImageBox extends StatelessWidget {
  final String? url;
  final double? width;
  final double height;
  final double radius;
  final BoxFit fit;

  const ProductImageBox({
    super.key,
    this.url,
    this.width,
    this.height = 120,
    this.radius = MamoRadius.md,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: hasUrl
          ? CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: fit,
              placeholder: (_, __) => _placeholder(),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    // height bisa double.infinity (mis. di dalam AspectRatio) — jangan dipakai
    // langsung untuk ukuran ikon, atau nilainya jadi infinity dan layout crash.
    final iconSize = (height.isFinite ? height * 0.3 : 34.0).clamp(16.0, 48.0);
    return Container(
      width: width,
      height: height.isFinite ? height : null,
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined,
          size: iconSize, color: MamoColors.textMuted.withValues(alpha: 0.6)),
    );
  }
}

/// Kartu produk untuk grid/list.
class ProductCard extends StatelessWidget {
  final String name;
  final int price;
  final String? imageUrl;
  final String? location;
  final String conditionLabel;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    this.imageUrl,
    this.location,
    this.conditionLabel = 'Bekas',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MamoRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: MamoColors.surface,
          borderRadius: BorderRadius.circular(MamoRadius.lg),
          border: Border.all(color: MamoColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: ProductImageBox(url: imageUrl, height: double.infinity, width: double.infinity,
                  radius: MamoRadius.lg),
            ),
            Padding(
              padding: const EdgeInsets.all(MamoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
                  const SizedBox(height: 6),
                  Text(rupiah.format(price),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: MamoColors.primary)),
                  if (location != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: MamoColors.textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: MamoColors.textSecondary)),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill status (Aktif/Pending/Ditolak/dll) — dipakai mobile & admin.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
    this.icon,
  });

  factory StatusPill.order(String status) {
    switch (status) {
      case 'pending':
        return StatusPill(label: 'Menunggu', color: MamoColors.primary, bg: MamoColors.infoBg,
            icon: Icons.schedule);
      case 'accepted':
        return StatusPill(label: 'Diterima', color: MamoColors.primary, bg: MamoColors.infoBg,
            icon: Icons.check_circle_outline);
      case 'processed':
        return StatusPill(label: 'Diproses', color: Color(0xFF7C3AED), bg: Color(0xFFEDE9FE),
            icon: Icons.inventory_2_outlined);
      case 'ready':
        return StatusPill(label: 'Siap', color: Color(0xFFD97706), bg: MamoColors.warningBg,
            icon: Icons.shopping_bag_outlined);
      case 'completed':
        return StatusPill(label: 'Selesai', color: MamoColors.success, bg: MamoColors.successBg,
            icon: Icons.task_alt);
      case 'cancelled':
        return StatusPill(label: 'Dibatalkan', color: MamoColors.textSecondary,
            bg: Color(0xFFF1F5F9), icon: Icons.cancel_outlined);
      case 'rejected':
        return StatusPill(label: 'Ditolak', color: MamoColors.danger, bg: MamoColors.dangerBg,
            icon: Icons.close);
      case 'sold':
        return StatusPill(label: 'Terjual', color: Color(0xFFD97706), bg: MamoColors.warningBg,
            icon: Icons.sell_outlined);
      case 'active':
        return StatusPill(label: 'Aktif', color: MamoColors.success, bg: MamoColors.successBg,
            icon: Icons.check_circle_outline);
      case 'flagged':
        return StatusPill(label: 'Flagged', color: MamoColors.danger, bg: MamoColors.dangerBg,
            icon: Icons.flag_outlined);
      case 'draft':
        return StatusPill(label: 'Draft', color: MamoColors.textSecondary,
            bg: Color(0xFFF1F5F9), icon: Icons.edit_outlined);
      default:
        return StatusPill(label: status, color: MamoColors.textSecondary,
            bg: Color(0xFFF1F5F9));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(MamoRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Wrapper untuk loading / error / empty — semua async punya feedback.
class AsyncView<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final bool Function(T)? isEmpty;

  const AsyncView({
    super.key,
    required this.snapshot,
    required this.builder,
    this.onRetry,
    this.emptyMessage = 'Belum ada data',
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ));
    }
    if (snapshot.hasError) {
      return ErrorState(message: '$snapshot.error', onRetry: onRetry);
    }
    final data = snapshot.data;
    if (data == null || (isEmpty?.call(data) ?? false)) {
      return EmptyState(message: emptyMessage);
    }
    return builder(data);
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.message = 'Belum ada data',
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: MamoColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MamoColors.textSecondary, fontSize: 14)),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(color: MamoColors.dangerBg, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off, size: 32, color: MamoColors.danger),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MamoColors.textSecondary, fontSize: 13)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section header dengan aksi "Lihat semua".
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MamoColors.primary)),
            ),
        ],
      ),
    );
  }
}

/// Logo MAMO (ikon perisai gradien + wordmark).
class MamoLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? textColor;

  const MamoLogo({super.key, this.size = 36, this.showWordmark = true, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: MamoColors.brandGradient,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Icon(Icons.verified, color: Colors.white, size: size * 0.58),
        ),
        if (showWordmark) ...[
          SizedBox(width: size * 0.3),
          Text('MAMO',
              style: TextStyle(
                  fontSize: size * 0.62,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: textColor ?? MamoColors.textPrimary)),
        ],
      ],
    );
  }
}

/// Snackbar helper.
void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? MamoColors.danger : null,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MamoRadius.md)),
    margin: const EdgeInsets.all(12),
  ));
}
