import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/pharmacy_model.dart';
import '../../data/services/api_service.dart';

class PharmaciesScreen extends StatefulWidget {
  const PharmaciesScreen({super.key});

  @override
  State<PharmaciesScreen> createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends State<PharmaciesScreen> {
  List<PharmacyModel> _all = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.get('Pharmacy?pageSize=200&isActive=true')
          as Map<String, dynamic>;
      final items = ((data['items'] as List?) ?? [])
          .map((p) => PharmacyModel.fromJson(p as Map<String, dynamic>))
          .where((p) => p.isActive)
          .toList();
      if (mounted) setState(() => _all = items);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _cities {
    final cities = _all.map((p) => p.cityName).toSet().toList();
    cities.sort();
    return cities;
  }

  List<PharmacyModel> get _filtered {
    var list = _all;
    if (_selectedCity != null)
      list = list.where((p) => p.cityName == _selectedCity).toList();
    if (_searchQuery.trim().isNotEmpty)
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.address.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pharmacies',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextDark),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kTeal))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppColors.kTeal,
                  onRefresh: _load,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchCtrl,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.kTextDark),
                              decoration: InputDecoration(
                                hintText: 'Search pharmacies...',
                                hintStyle: const TextStyle(
                                    color: AppColors.kTextLight, fontSize: 13),
                                prefixIcon: const Icon(Icons.search,
                                    color: AppColors.kTextMid, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.kBg,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.kBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.kBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.kTeal, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                          
                            if (_cities.length > 1)
                              DropdownButtonFormField<String>(
                                value: _selectedCity,
                                decoration: InputDecoration(
                                  hintText: 'All cities',
                                  hintStyle: const TextStyle(
                                      color: AppColors.kTextLight,
                                      fontSize: 13),
                                  prefixIcon: const Icon(
                                      Icons.location_city_outlined,
                                      color: AppColors.kTextMid,
                                      size: 20),
                                  filled: true,
                                  fillColor: AppColors.kBg,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.kBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.kBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.kTeal, width: 2),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                      value: null, child: Text('All cities')),
                                  ..._cities.map((city) => DropdownMenuItem(
                                      value: city, child: Text(city))),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedCity = v),
                              ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(children: [
                          Text(
                            '${_filtered.length} pharmacy${_filtered.length != 1 ? 's' : ''} found',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.kTextMid),
                          ),
                        ]),
                      ),

                      Expanded(
                        child: _filtered.isEmpty
                            ? _EmptyState(
                                searchQuery: _searchQuery,
                                selectedCity: _selectedCity,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) =>
                                    _PharmacyCard(pharmacy: _filtered[index]),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  const _PharmacyCard({required this.pharmacy});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push('/pharmacy', extra: pharmacy),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.kTealLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_pharmacy_outlined,
                  color: AppColors.kTeal, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.kTextLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pharmacy.address.isNotEmpty
                            ? '${pharmacy.address}, ${pharmacy.cityName}'
                            : pharmacy.cityName,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.kTextMid),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  if (pharmacy.workingHours != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.schedule_outlined,
                          size: 12, color: AppColors.kTextLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pharmacy.workingHours!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.kTextMid),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ],
                  if (pharmacy.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.phone_outlined,
                          size: 12, color: AppColors.kTextLight),
                      const SizedBox(width: 4),
                      Text(
                        pharmacy.phone!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.kTextMid),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppColors.kTextLight, size: 20),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final String searchQuery;
  final String? selectedCity;
  const _EmptyState({required this.searchQuery, this.selectedCity});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                child: const Icon(Icons.local_pharmacy_outlined,
                    size: 32, color: AppColors.kTeal),
              ),
              const SizedBox(height: 16),
              const Text(
                'No pharmacies found',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kTextDark),
              ),
              const SizedBox(height: 8),
              Text(
                searchQuery.isNotEmpty
                    ? 'No results for "$searchQuery"'
                    : selectedCity != null
                        ? 'No pharmacies in $selectedCity'
                        : 'Try adjusting your search',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.kTextMid),
              ),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
              Text(error,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.kTextMid)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}
