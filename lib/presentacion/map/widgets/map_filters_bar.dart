import 'package:flutter/material.dart';
import '../../../datos/modelos/map/location_cluster.dart';
import '../utils/client_data_extractor.dart';

/// Barra de filtros por estado de pago con diseño moderno
class MapStatusFiltersBar extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  const MapStatusFiltersBar({
    Key? key,
    required this.selectedStatus,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      {'key': null, 'label': 'Todos', 'icon': Icons.apps_rounded, 'color': Colors.blue},
      {'key': 'overdue', 'label': 'Vencidos', 'icon': Icons.warning_rounded, 'color': Colors.red},
      {'key': 'pending', 'label': 'Pendientes', 'icon': Icons.schedule_rounded, 'color': Colors.orange},
      {'key': 'paid', 'label': 'Al día', 'icon': Icons.check_circle_rounded, 'color': Colors.green},
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                ]
              : [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((it) {
              final key = it['key'] as String?;
              final selected = key == selectedStatus || (key == null && selectedStatus == null);
              final color = it['color'] as Color;
              final icon = it['icon'] as IconData;

              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: _ModernFilterChip(
                  label: it['label'] as String,
                  icon: icon,
                  color: color,
                  selected: selected,
                  onTap: () => onStatusChanged(key),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Chip moderno con animaciones y gradientes
class _ModernFilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ModernFilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ModernFilterChip> createState() => _ModernFilterChipState();
}

class _ModernFilterChipState extends State<_ModernFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: isDark ? 0.4 : 0.25),
                      widget.color.withValues(alpha: isDark ? 0.3 : 0.15),
                    ],
                  )
                : null,
            color: widget.selected
                ? null
                : (isDark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.selected
                  ? widget.color.withValues(alpha: 0.6)
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.selected
                    ? widget.color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.selected ? FontWeight.bold : FontWeight.w600,
                  color: widget.selected
                      ? widget.color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de estadísticas para un cluster
class ClusterStatsBar extends StatelessWidget {
  final LocationCluster cluster;

  const ClusterStatsBar({
    Key? key,
    required this.cluster,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final summary = cluster.clusterSummary;
    final stats = ClientDataExtractor.calculateClusterStats(cluster);

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip('Personas', '${stats['total_people']}'),
            _chip('Créditos', '${summary.totalCredits}'),
            /*_chip(
              'Balance',
              ClientDataExtractor.formatSoles(summary.totalBalance),
            ),*/
            _chip(
              'Vencidos',
              '${summary.overdueCount}',
              color: Colors.red.shade400,
            ),
            _chip(
              'Pendientes',
              '${summary.activeCount}',
              color: Colors.amber.shade700,
            ),
            _chip(
              'Pagados',
              '${summary.completedCount}',
              color: Colors.green.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, {Color? color}) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (color ?? scheme.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (color ?? scheme.primary).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(color: color ?? scheme.primary),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color ?? scheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Barra de búsqueda para filtrar clusters
/// Solo busca cuando presionas el botón o Enter, no mientras escribes
class ClusterSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final String? initialValue;

  const ClusterSearchBar({
    super.key,
    required this.onSearch,
    this.initialValue,
  });

  @override
  State<ClusterSearchBar> createState() => _ClusterSearchBarState();
}

class _ClusterSearchBarState extends State<ClusterSearchBar> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() => _isSearching = true);
    widget.onSearch(_controller.text);
    // Mostrar feedback visual brevemente
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _performSearch(), // Buscar al presionar Enter
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, teléfono, CI...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                        tooltip: 'Limpiar búsqueda',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _isSearching ? null : _performSearch,
            icon: _isSearching
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.search),
            label: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}

/// Widget que muestra información resumida de un cluster en una tarjeta
class ClusterCard extends StatelessWidget {
  final LocationCluster cluster;
  final VoidCallback onTap;

  const ClusterCard({
    Key? key,
    required this.cluster,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final summary = cluster.clusterSummary;
    final firstPerson = cluster.people.isNotEmpty ? cluster.people.first : null;
    final (statusIcon, statusColor) =
        ClientDataExtractor.getStatusIconAndColor(cluster.clusterStatus);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (firstPerson != null)
                          Text(
                            firstPerson.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (summary.totalPeople > 1)
                          Text(
                            '+${summary.totalPeople - 1} personas más',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                cluster.location.address,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniStat(
                    Icons.account_circle,
                    '${summary.totalPeople} personas',
                    Colors.blue,
                  ),
                  _miniStat(
                    Icons.credit_card,
                    '${summary.totalCredits} créditos',
                    Colors.green,
                  ),
                  _miniStat(
                    Icons.money,
                    ClientDataExtractor.formatSoles(summary.totalBalance),
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
