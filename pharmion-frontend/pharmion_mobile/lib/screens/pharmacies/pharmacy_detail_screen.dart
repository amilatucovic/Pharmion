import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/models/pharmacy_model.dart';
import '../../data/services/api_service.dart';

class PharmacyDetailScreen extends StatefulWidget {
  final PharmacyModel pharmacy;
  const PharmacyDetailScreen({super.key, required this.pharmacy});

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _loading = false;
  List<InventoryItemModel> _results = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      final data = await ApiService.get(
        'InventoryItem/public?pharmacyId=${widget.pharmacy.id}'
        '&productName=${Uri.encodeComponent(query.trim())}'
        '&pageSize=20',
      ) as List<dynamic>;

      if (mounted) {
        setState(() {
          _results = data
              .map(
                  (i) => InventoryItemModel.fromJson(i as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final pharmacy = widget.pharmacy;

    return Scaffold(
      backgroundColor: AppColors.kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.kTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF04B2B8), Color(0xFF03989E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.local_pharmacy_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(pharmacy.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(pharmacy.cityName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pharmacy Info',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kTextDark)),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppColors.kBorder),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: pharmacy.address.isNotEmpty
                              ? pharmacy.address
                              : '—',
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.location_city_outlined,
                          label: 'City',
                          value: pharmacy.cityName,
                        ),
                        if (pharmacy.phone != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: pharmacy.phone!,
                          ),
                        ],
                        if (pharmacy.email != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: pharmacy.email!,
                          ),
                        ],
                        if (pharmacy.workingHours != null) ...[
                          const SizedBox(height: 12),
                          _WorkingHoursRow(value: pharmacy.workingHours!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Available Products',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) {
                      setState(() => _searchQuery = v);
                      _search(v);
                    },
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.kTextDark),
                    decoration: InputDecoration(
                      hintText: 'Search for a medication in this pharmacy...',
                      hintStyle: const TextStyle(
                          color: AppColors.kTextLight, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.kTextMid, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _results = [];
                                  _hasSearched = false;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.kTeal, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child:
                            CircularProgressIndicator(color: AppColors.kTeal),
                      ),
                    )
                  else if (!_hasSearched)
                    _EmptyState(
                      icon: Icons.search,
                      title: 'Search for a medication',
                      subtitle:
                          'Type at least 2 characters to find available products in this pharmacy.',
                    )
                  else if (_results.isEmpty)
                    _EmptyState(
                      icon: Icons.medication_outlined,
                      title: 'No products found',
                      subtitle:
                          'No available medications match "$_searchQuery" in this pharmacy.',
                    )
                  else
                    ..._results.map(
                        (item) => _ProductCard(item: item, fmtDate: _fmtDate)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.kTealLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.kTeal, size: 28),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextDark)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.kTextMid, height: 1.4)),
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.kTealLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.kTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextMid,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.kTextDark,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      );
}

class _ProductCard extends StatelessWidget {
  final InventoryItemModel item;
  final String Function(DateTime) fmtDate;
  const _ProductCard({required this.item, required this.fmtDate});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push('/product-detail', extra: item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isLowStock
                  ? AppColors.kWarning.withValues(alpha: 0.4)
                  : AppColors.kBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _ProductImage(imageUrl: item.productImageUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kTextDark)),
                  if (item.productSku != null) ...[
                    const SizedBox(height: 2),
                    Text('SKU: ${item.productSku}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMid)),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.availableQuantity > 0
                            ? AppColors.kTealLight
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.availableQuantity > 0
                            ? 'Available'
                            : 'Not available',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.availableQuantity > 0
                              ? AppColors.kTeal
                              : AppColors.kError,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Exp: ${fmtDate(item.expirationDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: item.isExpiringSoon
                            ? AppColors.kWarning
                            : AppColors.kTextLight,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            if (item.isLowStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Low',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kWarning)),
              ),
          ]),
        ),
      );
}

class _WorkingHoursRow extends StatelessWidget {
  final String value;
  const _WorkingHoursRow({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.kTealLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.schedule, size: 16, color: AppColors.kTeal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Working Hours',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.kTextMid,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.kTextDark,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  const _ProductImage({this.imageUrl});

  bool get _hasRealImage =>
      imageUrl != null &&
      imageUrl!.isNotEmpty &&
      !imageUrl!.contains('default-product');

  @override
  Widget build(BuildContext context) {
    if (_hasRealImage) {
      return Image.network(
        '${AppConstants.baseUrl}$imageUrl',
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultImage(),
      );
    }
    return _defaultImage();
  }

  Widget _defaultImage() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.kTealLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.medication_rounded,
            color: AppColors.kTeal, size: 28),
      );
}
