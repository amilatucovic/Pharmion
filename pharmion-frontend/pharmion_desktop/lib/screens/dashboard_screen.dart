import 'package:flutter/material.dart';
import 'package:pharmion_desktop/screens/chronic_diseases_screen.dart';
import 'package:pharmion_desktop/screens/cities_screen.dart';
import 'package:pharmion_desktop/screens/exceptions_screen.dart';
import 'package:pharmion_desktop/screens/pharmacies_screen.dart';
import 'package:pharmion_desktop/screens/products_screen.dart';
import 'package:pharmion_desktop/screens/reports_screen.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';
import 'reservations_screen.dart';
import 'patients_screen.dart';
import 'prescriptions_screen.dart';
import 'inventory_screen.dart';
import 'my_account_screen.dart';
import 'pharmacists_screen.dart';
import '../widgets/notification_bell.dart';
import 'medication_categories_screen.dart';
import 'pharmacological_categories_screen.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      title,
      style: const TextStyle(fontSize: 24, color: Color(0xFF64748B)),
    ),
  );
}

// ─── Sidebar item model ───────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final bool adminOnly;
  const _NavItem(this.label, this.icon, {this.adminOnly = false});
}

//  Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  String _firstName = '';
  String _lastName = '';
  bool _loading = true;

  // Nav items
  final List<_NavItem> _adminItems = const [
    _NavItem('Dashboard', Icons.dashboard_rounded),
    _NavItem('Reservations', Icons.assignment_rounded),
    _NavItem('Patients', Icons.people_rounded),
    _NavItem('Prescriptions', Icons.description_rounded),
    _NavItem('Products', Icons.medication_rounded, adminOnly: true),
    _NavItem('Inventory', Icons.inventory_2_rounded, adminOnly: true),
    _NavItem('Pharmacies', Icons.local_pharmacy_rounded, adminOnly: true),
    _NavItem('Cities', Icons.location_city_rounded, adminOnly: true),
    _NavItem('Chronic Diseases', Icons.healing_rounded, adminOnly: true),
    _NavItem('Reports', Icons.bar_chart_rounded, adminOnly: true),
    _NavItem('My Account', Icons.account_circle_rounded),
    _NavItem('Pharmacists', Icons.badge_rounded, adminOnly: true),
    _NavItem('Exceptions', Icons.warning_rounded, adminOnly: true),
    _NavItem('Medication Categories', Icons.category_rounded, adminOnly: true),
    _NavItem('Pharmacol. Categories', Icons.science_rounded, adminOnly: true),
  ];

  final List<_NavItem> _pharmacistItems = const [
    _NavItem('Dashboard', Icons.dashboard_rounded),
    _NavItem('Reservations', Icons.assignment_rounded),
    _NavItem('Patients', Icons.people_rounded),
    _NavItem('Prescriptions', Icons.description_rounded),
    _NavItem('Inventory', Icons.inventory_2_rounded),
    _NavItem('Exceptions', Icons.warning_rounded),
    _NavItem('My Account', Icons.account_circle_rounded),
  ];

  List<_NavItem> get _navItems => _isAdmin ? _adminItems : _pharmacistItems;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final admin = await ApiService.isAdmin();
    final prefs = await _getPrefs();
    setState(() {
      _isAdmin = admin;
      _firstName = prefs['firstName'] ?? '';
      _lastName = prefs['lastName'] ?? '';
      _loading = false;
    });
  }

  Future<Map<String, String>> _getPrefs() async {
    final prefs = await SharedPreferencesHelper.getAll();
    return prefs;
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.kTextMid),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.clearToken();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Widget _buildContent() {
    final label = _navItems[_selectedIndex].label;
    switch (label) {
      case 'Dashboard':
        return _DashboardHome(isAdmin: _isAdmin);
      case 'Reservations':
        return const ReservationsScreen();
      case 'Patients':
        return const PatientsScreen();
      case 'Prescriptions':
        return const PrescriptionsScreen();
      case 'Products':
        return const ProductsScreen();
      case 'Pharmacies':
        return const PharmaciesScreen();
      case 'Cities':
        return const CitiesScreen();
      case 'Chronic Diseases':
        return const ChronicDiseasesScreen();
      case 'Reports':
        return const ReportsScreen();
      case 'Inventory':
        return const InventoryScreen();
      case 'My Account':
        return const MyAccountScreen();
      case 'Pharmacists':
        return const PharmacistsScreen();
      case 'Exceptions':
        return const ExceptionsScreen();
      case 'Medication Categories':
        return const MedicationCategoriesScreen();
      case 'Pharmacol. Categories':
        return const PharmacologicalCategoriesScreen();
      default:
        return const PlaceholderScreen(title: 'Coming soon');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.kTeal)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.kBg,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: AppColors.kSidebar,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/pharmion_logo.png',
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isAdmin
                        ? AppColors.kTeal.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isAdmin
                          ? AppColors.kTeal.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isAdmin ? Icons.admin_panel_settings : Icons.badge,
                        color: _isAdmin ? AppColors.kTeal : Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isAdmin ? 'Administrator' : 'Pharmacist',
                        style: TextStyle(
                          color: _isAdmin ? AppColors.kTeal : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                const SizedBox(height: 8),

                // Nav items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final selected = _selectedIndex == index;
                      return _SidebarItem(
                        item: item,
                        selected: selected,
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),

                // Divider
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: Colors.white12, height: 1),
                ),

                // My Account + Sign Out
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      // User info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.kTeal.withValues(
                                alpha: 0.3,
                              ),
                              child: Text(
                                _firstName.isNotEmpty
                                    ? _firstName[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  color: AppColors.kTeal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_firstName $_lastName',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _logout,
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white38,
                                size: 18,
                              ),
                              tooltip: 'Sign Out',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _navItems[_selectedIndex].label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark,
                        ),
                      ),
                      const Spacer(),
                      // Notification bell
                      const NotificationBell(),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.kTealLight,
                        child: Text(
                          _firstName.isNotEmpty
                              ? _firstName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: AppColors.kTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page content
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar Item Widget ──────────────────────────────────────────────────────
class _SidebarItem extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.kTeal
                : _hovering
                ? AppColors.kSidebarHover
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                color: widget.selected ? Colors.white : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: widget.selected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Home Page ──────────────────────────────────────────────────────
class _DashboardHome extends StatefulWidget {
  final bool isAdmin;
  const _DashboardHome({required this.isAdmin});

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  bool _loading = true;
  DashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await DashboardService.getStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.kTeal),
      );
    }

    final stats = _stats;
    if (stats == null) {
      return const Center(
        child: Text(
          'Failed to load data',
          style: TextStyle(color: AppColors.kTextMid),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good ${_greeting()}, welcome back!',
            style: const TextStyle(fontSize: 14, color: AppColors.kTextMid),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              _StatCard(
                title: 'Reservations Today',
                value: '${stats.reservationsToday}',
                icon: Icons.assignment_turned_in_rounded,
                color: AppColors.kTeal,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Active Patients',
                value: '${stats.activePatients}',
                icon: Icons.people_rounded,
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: widget.isAdmin ? 'Total Products' : 'Items in Stock',
                value: '${stats.totalProducts}',
                icon: Icons.medication_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top 5 products
              Expanded(
                flex: 2,
                child: _Card(
                  title: 'Top 5 Most Reserved Products',
                  child: stats.topProducts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No data available',
                            style: TextStyle(color: AppColors.kTextMid),
                          ),
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                children: const [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      'Rank',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kTextMid,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Product',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kTextMid,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Reservations',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.kTextMid,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ...stats.topProducts.asMap().entries.map((entry) {
                              final i = entry.key;
                              final p = entry.value;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: i.isEven
                                      ? Colors.white
                                      : const Color(0xFFF8FAFC),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: i == 0
                                              ? const Color.fromARGB(
                                                  255,
                                                  14,
                                                  146,
                                                  140,
                                                )
                                              : i == 1
                                              ? const Color.fromARGB(
                                                  255,
                                                  195,
                                                  197,
                                                  58,
                                                )
                                              : i == 2
                                              ? const Color.fromARGB(
                                                  255,
                                                  223,
                                                  145,
                                                  68,
                                                )
                                              : AppColors.kTealLight,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${p.rank}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: i < 3
                                                  ? Colors.white
                                                  : AppColors.kTeal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.kTextDark,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.kTealLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${p.count}',
                                        style: const TextStyle(
                                          color: AppColors.kTeal,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Recent reservations
              Expanded(
                flex: 3,
                child: _Card(
                  title: 'Recent Reservations',
                  child: stats.recentReservations.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No reservations found',
                            style: TextStyle(color: AppColors.kTextMid),
                          ),
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                children: const [
                                  Expanded(
                                    child: Text(
                                      'Patient',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kTextMid,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Pharmacy',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kTextMid,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kTextMid,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ...stats.recentReservations.asMap().entries.map((
                              entry,
                            ) {
                              final i = entry.key;
                              final r = entry.value;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: i.isEven
                                      ? Colors.white
                                      : const Color(0xFFF8FAFC),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.patientName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.kTextDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        r.pharmacyName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.kTextMid,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: _StatusBadge(status: r.status),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.kTextDark,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.kTextMid,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'submitted':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case 'approved':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
        break;
      case 'readyforpickup':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF2563EB);
        break;
      case 'pickedup':
        bg = AppColors.kTealLight;
        fg = AppColors.kTeal;
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      case 'cancelled':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class SharedPreferencesHelper {
  static Future<Map<String, String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
    };
  }
}
