import 'package:flutter/material.dart';

class NotificationUtils {
  static const Color _primaryColor = Color.fromRGBO(239, 120, 26, 1);
  static const Duration _defaultDuration = Duration(seconds: 3);
  static OverlayEntry? _currentOverlay;

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    String? title,
  }) {
    _showOverlayNotification(
      context: context,
      message: message,
      title: title,
      icon: Icons.check_circle,
      backgroundColor: Colors.green[600]!,
      duration: duration ?? _defaultDuration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    String? title,
  }) {
    _showOverlayNotification(
      context: context,
      message: message,
      title: title,
      icon: Icons.error,
      backgroundColor: Colors.red[600]!,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    String? title,
  }) {
    _showOverlayNotification(
      context: context,
      message: message,
      title: title,
      icon: Icons.info,
      backgroundColor: Colors.blue[600]!,
      duration: duration ?? _defaultDuration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    String? title,
  }) {
    _showOverlayNotification(
      context: context,
      message: message,
      title: title,
      icon: Icons.warning,
      backgroundColor: Colors.orange[600]!,
      duration: duration ?? _defaultDuration,
    );
  }

  static void showPrimary(
    BuildContext context,
    String message, {
    Duration? duration,
    String? title,
    IconData? icon,
  }) {
    _showOverlayNotification(
      context: context,
      message: message,
      title: title,
      icon: icon ?? Icons.notifications,
      backgroundColor: _primaryColor,
      duration: duration ?? _defaultDuration,
    );
  }

  static void _showOverlayNotification({
    required BuildContext context,
    required String message,
    String? title,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    _removeCurrentOverlay();

    if (!context.mounted) return;

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        message: message,
        title: title,
        icon: icon,
        backgroundColor: backgroundColor,
        onDismiss: _removeCurrentOverlay,
      ),
    );

    overlay.insert(_currentOverlay!);

    Future.delayed(duration, () {
      _removeCurrentOverlay();
    });
  }

  static void _removeCurrentOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  static void hideCurrentNotification() {
    _removeCurrentOverlay();
  }

  static void clearAllNotifications() {
    _removeCurrentOverlay();
  }
}

class _NotificationOverlay extends StatefulWidget {
  final String message;
  final String? title;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onDismiss;

  const _NotificationOverlay({
    required this.message,
    this.title,
    required this.icon,
    required this.backgroundColor,
    required this.onDismiss,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 35,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.title != null) ...[
                          Text(
                            widget.title!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: widget.title != null ? 14 : 16,
                            fontWeight: widget.title != null
                                ? FontWeight.normal
                                : FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}