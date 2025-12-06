import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../negocio/providers/auth_provider.dart';
import '../services/filter_visibility_service.dart';
import 'search_select_field.dart';

/// Widget que construye filtros dinámicamente según el rol del usuario
class RoleAwareFilterBuilder extends ConsumerWidget {
  final String reportType;
  final Map<String, dynamic> currentFilters;
  final Function(String key, dynamic value) onFilterChanged;

  const RoleAwareFilterBuilder({
    required this.reportType,
    required this.currentFilters,
    required this.onFilterChanged,
    Key? key,
  }) : super(key: key);

  // 🎨 Emojis para cada tipo de filtro
  static const Map<String, String> _filterEmojis = {
    'start_date': '📅',
    'end_date': '📆',
    'date': '📅',
    'status': '🏷️',
    'cobrador_id': '👤',
    'client_id': '👥',
    'created_by': '✍️',
    'delivered_by': '🚚',
    'amount': '💵',
    'min_amount': '💰',
    'max_amount': '💰',
    'role': '🎭',
    'client_category': '⭐',
    'min_days_overdue': '⏰',
    'max_days_overdue': '⏰',
    'min_overdue_amount': '💸',
    'with_discrepancies': '⚠️',
    'manager_id': '👔',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;

    if (usuario == null) {
      return const Center(
        child: Text('Usuario no autenticado'),
      );
    }

    // Obtener los filtros visibles para este rol
    final visibleFilters = FilterVisibilityService.getVisibleFilters(
      reportType: reportType,
      usuario: usuario,
    );

    // Obtener descripción contextual
    final contextDescription = FilterVisibilityService.getDataContextDescription(
      reportType: reportType,
      usuario: usuario,
    );

    if (visibleFilters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No hay filtros disponibles para este reporte'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Banner informativo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  contextDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Constructores de filtros dinámicos
        ...visibleFilters.map((filterConfig) {
          return _buildFilterWidget(
            context: context,
            config: filterConfig,
            currentValue: currentFilters[filterConfig.filterKey],
            onChanged: (value) => onFilterChanged(filterConfig.filterKey, value),
          );
        }),
      ],
    );
  }

  /// Construye el widget para un filtro específico según su tipo
  Widget _buildFilterWidget({
    required BuildContext context,
    required FilterVisibilityConfig config,
    required dynamic currentValue,
    required Function(dynamic) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label con emoji
          Row(
            children: [
              // 🎨 Emoji del filtro
              if (_filterEmojis.containsKey(config.filterKey))
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _filterEmojis[config.filterKey]!,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              Text(
                config.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (config.required)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
          if (config.description != null) ...[
            const SizedBox(height: 4),
            Text(
              config.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 8),

          // Widget según tipo
          _buildInputWidget(
            config: config,
            currentValue: currentValue,
            onChanged: onChanged,
            context: context,
          ),
        ],
      ),
    );
  }

  /// Construye el input según el tipo de filtro
  Widget _buildInputWidget({
    required FilterVisibilityConfig config,
    required dynamic currentValue,
    required Function(dynamic) onChanged,
    required BuildContext context,
  }) {
    switch (config.type) {
      case 'date':
        return _buildDateInput(
          config,
          currentValue,
          onChanged,
          context,
        );

      case 'select':
        return _buildSelectInput(
          config,
          currentValue,
          onChanged,
          context,
        );

      case 'search_select':
        return _buildSearchSelectInput(
          config,
          currentValue,
          onChanged,
          context,
        );

      case 'number':
        return _buildNumberInput(
          config,
          currentValue,
          onChanged,
          context,
        );

      case 'text':
        return _buildTextInput(
          config,
          currentValue,
          onChanged,
          context,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// Construye input de fecha
  Widget _buildDateInput(
    FilterVisibilityConfig config,
    dynamic currentValue,
    Function(dynamic) onChanged,
    BuildContext context,
  ) {
    final dateValue = currentValue is DateTime
        ? currentValue
        : (currentValue is String
            ? DateTime.tryParse(currentValue)
            : null);

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: dateValue ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          locale: const Locale('es', 'ES'),
        );

        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateValue != null
                    ? DateFormat('dd/MM/yyyy').format(dateValue)
                    : 'Seleccionar fecha',
                style: TextStyle(
                  color: dateValue != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (dateValue != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(
                  Icons.clear,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construye input de búsqueda con selección (SearchSelectField)
  Widget _buildSearchSelectInput(
    FilterVisibilityConfig config,
    dynamic currentValue,
    Function(dynamic) onChanged,
    BuildContext context,
  ) {
    return SearchSelectField(
      label: config.label,
      initialValue: currentValue?.toString(),
      type: config.searchType ?? 'categoria',  // Usa searchType de la config
      onSelected: (id, label) {
        onChanged(id);  // Envía solo el ID (código) al filtro
      },
    );
  }

  /// Construye input de selección
  Widget _buildSelectInput(
    FilterVisibilityConfig config,
    dynamic currentValue,
    Function(dynamic) onChanged,
    BuildContext context,
  ) {
    final options = config.options ?? {};

    // Validar que el valor actual esté en las opciones disponibles
    // Si no está, establecer a null para evitar error en DropdownButton
    String? validValue;
    if (currentValue != null) {
      final stringValue = currentValue.toString();
      if (options.containsKey(stringValue)) {
        validValue = stringValue;
      }
      // Si el valor no está en las opciones, ignorarlo (será null)
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String?>(
        value: validValue,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(
          'Seleccionar ${config.label.toLowerCase()}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        items: [
          if (validValue != null)
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Limpiar filtro',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ...options.entries.map((entry) {
            return DropdownMenuItem<String?>(
              value: entry.key,
              child: Text(entry.value as String),
            );
          }),
        ],
        onChanged: (value) => onChanged(value),
      ),
    );
  }

  /// Construye input de número
  Widget _buildNumberInput(
    FilterVisibilityConfig config,
    dynamic currentValue,
    Function(dynamic) onChanged,
    BuildContext context,
  ) {
    final controller = TextEditingController(
      text: currentValue?.toString() ?? '',
    );

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Ingresar ${config.label.toLowerCase()}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: currentValue != null
            ? GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged(null);
                },
                child: const Icon(Icons.clear),
              )
            : null,
      ),
      onChanged: (value) {
        if (value.isEmpty) {
          onChanged(null);
        } else {
          onChanged(int.tryParse(value) ?? value);
        }
      },
    );
  }

  /// Construye input de texto
  Widget _buildTextInput(
    FilterVisibilityConfig config,
    dynamic currentValue,
    Function(dynamic) onChanged,
    BuildContext context,
  ) {
    final controller = TextEditingController(
      text: currentValue?.toString() ?? '',
    );

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Ingresar ${config.label.toLowerCase()}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: currentValue != null
            ? GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged(null);
                },
                child: const Icon(Icons.clear),
              )
            : null,
      ),
      onChanged: (value) {
        if (value.isEmpty) {
          onChanged(null);
        } else {
          onChanged(value);
        }
      },
    );
  }
}
