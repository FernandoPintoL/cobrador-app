import 'package:flutter/material.dart';
import '../../../datos/modelos/map/location_cluster.dart';
import '../utils/client_data_extractor.dart';

/// Barra de filtros por estado de pago
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
    final items = const [
      {'key': null, 'label': 'Todos'},
      {'key': 'overdue', 'label': 'Vencidos'},
      {'key': 'pending', 'label': 'Pendientes'},
      {'key': 'paid', 'label': 'Al día'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((it) {
            final key = it['key'] as String?;
            final selected =
                key == selectedStatus || (key == null && selectedStatus == null);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(it['label'] as String),
                selected: selected,
                onSelected: (_) => onStatusChanged(key),
              ),
            );
          }).toList(),
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
            color: (color ?? scheme.primary).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (color ?? scheme.primary).withOpacity(0.3),
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
                      color: statusColor.withOpacity(0.1),
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
