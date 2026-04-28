import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/api_service.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadNotifications(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.get('Notification/my') as List<dynamic>;
      if (mounted) {
        setState(() {
          _notifications = data
              .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
              .toList();
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await ApiService.put('Notification/$id/read', {});
      await _loadNotifications();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.put('Notification/read-all', {});
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: AppColors.kSuccess,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.kTextDark),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.kTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kTeal))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.kErrorLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.error_outline,
                            size: 32, color: AppColors.kError),
                      ),
                      const SizedBox(height: 16),
                      const Text('Something went wrong',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextDark)),
                      const SizedBox(height: 8),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.kTextMid)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadNotifications,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.kTeal,
                  onRefresh: _loadNotifications,
                  child: _notifications.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppColors.kTealLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.notifications_none_outlined,
                                          size: 32,
                                          color: AppColors.kTeal),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No notifications yet',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kTextDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'You will be notified about\nyour reservation updates here',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.kTextMid,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final n = _notifications[index];
                            return _NotificationCard(
                              notification: n,
                              formattedDate: _formatDate(n.createdAt),
                              onMarkAsRead:
                                  n.isRead ? null : () => _markAsRead(n.id),
                            );
                          },
                        ),
                ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final String formattedDate;
  final VoidCallback? onMarkAsRead;

  const _NotificationCard({
    required this.notification,
    required this.formattedDate,
    this.onMarkAsRead,
  });

  IconData get _icon {
    final title = notification.title.toLowerCase();
    if (title.contains('odobrena')) return Icons.check_circle_outline;
    if (title.contains('odbijena')) return Icons.cancel_outlined;
    if (title.contains('otkazana')) return Icons.block_outlined;
    if (title.contains('spremna')) return Icons.local_pharmacy_outlined;
    return Icons.notifications_outlined;
  }

  Color get _iconColor {
    final title = notification.title.toLowerCase();
    if (title.contains('odobrena')) return AppColors.kSuccess;
    if (title.contains('odbijena')) return AppColors.kError;
    if (title.contains('otkazana')) return AppColors.kTextMid;
    if (title.contains('spremna')) return AppColors.kTeal;
    return AppColors.kTeal;
  }

  Color get _iconBg {
    final title = notification.title.toLowerCase();
    if (title.contains('odobrena')) return const Color(0xFFD1FAE5);
    if (title.contains('odbijena')) return AppColors.kErrorLight;
    if (title.contains('otkazana')) return const Color(0xFFF1F5F9);
    if (title.contains('spremna')) return AppColors.kTealLight;
    return AppColors.kTealLight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notification.isRead
              ? AppColors.kBorder
              : AppColors.kTeal.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: AppColors.kTextDark,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.kTeal,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.kTextMid,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextLight,
                      ),
                    ),
                    if (onMarkAsRead != null)
                      GestureDetector(
                        onTap: onMarkAsRead,
                        child: const Text(
                          'Mark as read',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.kTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
