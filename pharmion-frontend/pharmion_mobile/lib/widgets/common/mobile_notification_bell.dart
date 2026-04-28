import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/api_service.dart';

class MobileNotificationBell extends StatefulWidget {
  const MobileNotificationBell();

  @override
  State<MobileNotificationBell> createState() => _MobileNotificationBellState();
}

class _MobileNotificationBellState extends State<MobileNotificationBell> {
  int _unreadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchCount(); // ← odmah učita
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchCount(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCount() async {
    try {
      final data = await ApiService.get('Notification/my/unread-count')
          as Map<String, dynamic>;
      if (mounted) setState(() => _unreadCount = data['count'] as int? ?? 0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 24),
          if (_unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _unreadCount > 9 ? '9+' : '$_unreadCount',
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
    );
  }
}