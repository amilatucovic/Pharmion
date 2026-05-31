import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final int itemCount;
  final void Function(int page) onPageChanged;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.itemCount,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = (currentPage - 2).clamp(0, (totalPages - 5).clamp(0, totalPages));
    final end = (start + 5).clamp(0, totalPages);
    final adjustedStart = (end - start < 5) ? (end - 5).clamp(0, end) : start;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Text(
            'Showing ${currentPage * pageSize + 1}–${(currentPage * pageSize + itemCount)} of $totalCount',
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMid),
          ),
          const Spacer(),
          IconButton(
            onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.kTextMid,
            disabledColor: const Color(0xFFCBD5E1),
          ),
          ...List.generate(end - adjustedStart, (i) {
            final page = adjustedStart + i;
            final isSelected = page == currentPage;
            return GestureDetector(
              onTap: () => onPageChanged(page),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.kTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${page + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.kTextMid,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.kTextMid,
            disabledColor: const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}