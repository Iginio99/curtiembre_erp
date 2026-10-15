import 'package:erp_curtiembre_fronted/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Pie de tabla reutilizable. Recibe estado y callbacks ya calculados por cada
/// módulo para no acoplar la presentación a la fuente de datos.
class AppTablePagination extends StatelessWidget {
  const AppTablePagination({
    required this.page,
    required this.totalPages,
    required this.start,
    required this.end,
    required this.total,
    required this.onPageChanged,
    this.pageSize,
    this.pageSizeOptions,
    this.onPageSizeChanged,
    this.emptyLabel = '0 resultados',
    super.key,
  });

  final int page;
  final int totalPages;
  final int start;
  final int end;
  final int total;
  final ValueChanged<int> onPageChanged;
  final int? pageSize;
  final List<int>? pageSizeOptions;
  final ValueChanged<int>? onPageSizeChanged;
  final String emptyLabel;

  bool get _showsPageSize =>
      pageSize != null && pageSizeOptions != null && onPageSizeChanged != null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isFirstPage = page <= 0;
    final isLastPage = page + 1 >= totalPages;

    final navigation = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          total == 0 ? emptyLabel : '${start + 1}–$end de $total',
          style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        _ArrowButton(
          tooltip: 'Página anterior',
          icon: Icons.chevron_left_rounded,
          onPressed: isFirstPage ? null : () => onPageChanged(page - 1),
        ),
        const SizedBox(width: 6),
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            '${page + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _ArrowButton(
          tooltip: 'Página siguiente',
          icon: Icons.chevron_right_rounded,
          onPressed: isLastPage ? null : () => onPageChanged(page + 1),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          if (_showsPageSize)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Mostrar', style: TextStyle(fontSize: 11.5)),
                const SizedBox(width: 7),
                DropdownButton<int>(
                  value: pageSize ?? pageSizeOptions!.first,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: pageSizeOptions!
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onPageSizeChanged!(value);
                  },
                ),
                const SizedBox(width: 7),
                const Text('por página', style: TextStyle(fontSize: 11.5)),
              ],
            ),
          navigation,
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            fixedSize: const Size(42, 42),
            minimumSize: const Size(42, 42),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Icon(icon, size: 21),
        ),
      );
}
