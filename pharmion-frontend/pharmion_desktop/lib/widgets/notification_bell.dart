import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  List<dynamic> _notifications = [];
  bool _loading = false;
  bool _panelOpen = false;
  Timer? _pollingTimer;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchUnreadCount();
      if (_panelOpen) _fetchNotifications();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final data =
          await ApiService.get('Notification/my/unread-count')
              as Map<String, dynamic>;
      if (mounted) setState(() => _unreadCount = data['count'] as int? ?? 0);
    } catch (_) {}
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    _overlayEntry?.markNeedsBuild();
    try {
      final data = await ApiService.get('Notification/my') as List<dynamic>;
      if (mounted) {
        setState(() {
          _notifications = data;
          _loading = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      _overlayEntry?.markNeedsBuild();
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await ApiService.put('Notification/$id/read', {});
      await _fetchNotifications();
      await _fetchUnreadCount();
      _overlayEntry?.markNeedsBuild();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.put('Notification/read-all', {});
      await _fetchNotifications();
      await _fetchUnreadCount();
      _overlayEntry?.markNeedsBuild();
    } catch (_) {}
  }

  void _togglePanel() {
    if (_panelOpen) {
      _removeOverlay();
      setState(() => _panelOpen = false);
    } else {
      setState(() => _panelOpen = true);
      _openOverlay();
      _fetchNotifications().then((_) => _overlayEntry?.markNeedsBuild());
    }
  }

  void _openOverlay() {
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _removeOverlay();
                if (mounted) setState(() => _panelOpen = false);
              },
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            offset: const Offset(-300, 48),
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              child: StatefulBuilder(
                builder: (ctx, setOverlayState) => _NotificationPanel(
                  notifications: _notifications,
                  loading: _loading,
                  unreadCount: _unreadCount,
                  onMarkAsRead: (id) async {
                    await _markAsRead(id);
                    setOverlayState(() {});
                  },
                  onMarkAllAsRead: () async {
                    await _markAllAsRead();
                    setOverlayState(() {});
                  },
                  onRefresh: () async {
                    await _fetchNotifications();
                    await _fetchUnreadCount();
                    setOverlayState(() {});
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _togglePanel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _panelOpen ? AppColors.kTealLight : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _panelOpen
                    ? Icons.notifications_rounded
                    : Icons.notifications_outlined,
                color: _panelOpen ? AppColors.kTeal : AppColors.kTextMid,
                size: 22,
              ),
            ),
            if (_unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  final List<dynamic> notifications;
  final bool loading;
  final int unreadCount;
  final Future<void> Function(int id) onMarkAsRead;
  final Future<void> Function() onMarkAllAsRead;
  final Future<void> Function() onRefresh;

  const _NotificationPanel({
    required this.notifications,
    required this.loading,
    required this.unreadCount,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 480),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextDark,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: onMarkAllAsRead,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.kTeal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Mark all read'),
                  ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  color: AppColors.kTextMid,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          Flexible(
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.kTeal,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : notifications.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 36,
                          color: AppColors.kTextLight,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.kTextMid,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final n = notifications[index] as Map<String, dynamic>;
                      final isRead = n['isRead'] as bool? ?? true;
                      final createdAt = n['createdAt'] != null
                          ? DateTime.tryParse('${n['createdAt']}Z')
                          : null;

                      return _NotificationTile(
                        title: n['title'] as String? ?? '',
                        message: n['message'] as String? ?? '',
                        isRead: isRead,
                        createdAt: createdAt,
                        onMarkAsRead: isRead
                            ? null
                            : () => onMarkAsRead(n['id'] as int),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final VoidCallback? onMarkAsRead;

  const _NotificationTile({
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.onMarkAsRead,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final localDt = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localDt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${localDt.day.toString().padLeft(2, '0')}.${localDt.month.toString().padLeft(2, '0')}.${localDt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isRead ? Colors.white : const Color(0xFFF0FDFA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead ? Colors.transparent : AppColors.kTeal,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    color: AppColors.kTextDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.kTextMid,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.kTextLight,
                  ),
                ),
              ],
            ),
          ),
          if (onMarkAsRead != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onMarkAsRead,
              child: const Icon(
                Icons.check_circle_outline,
                size: 16,
                color: AppColors.kTeal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
