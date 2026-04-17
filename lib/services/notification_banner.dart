import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class NotificationBanner {
  static void show(
    BuildContext context, {
    required String title,
    required String body,
    IconData icon = Icons.notifications_outlined,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _BannerWidget(
        title: title,
        body: body,
        icon: icon,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Disparaît automatiquement après 4 secondes
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _BannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onDismiss;

  const _BannerWidget({
    required this.title,
    required this.body,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(widget.body,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onDismiss,
                  icon: const Icon(Icons.close,
                      size: 16, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}