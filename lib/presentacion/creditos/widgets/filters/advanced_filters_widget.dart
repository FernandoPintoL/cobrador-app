import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'advanced_filters_panel.dart';
import 'credit_filter_state.dart';
import '../../../../negocio/providers/filter_options_provider.dart';

/// Widget contenedor para el panel de filtros avanzados
/// Este widget proporciona la estructura y comportamiento para mostrar/ocultar filtros avanzados
class AdvancedFiltersWidget extends ConsumerStatefulWidget {
  final CreditFilterState filterState;
  final Function(CreditFilterState) onApply;

  const AdvancedFiltersWidget({
    super.key,
    required this.filterState,
    required this.onApply,
  });

  @override
  ConsumerState<AdvancedFiltersWidget> createState() =>
      _AdvancedFiltersWidgetState();
}

class _AdvancedFiltersWidgetState
    extends ConsumerState<AdvancedFiltersWidget> {
  @override
  void initState() {
    super.initState();
    // Cargar opciones de filtros cuando se abre el panel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(filterOptionsProvider.notifier).loadFilterOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filterOptionsState = ref.watch(filterOptionsProvider);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: filterOptionsState.isLoading && filterOptionsState.options == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Cargando opciones de filtros...'),
                      ],
                    ),
                  ),
                )
              : AdvancedFiltersPanel(
                  filterState: widget.filterState,
                  onApplyFilters: widget.onApply,
                  onClose: () => widget.onApply(
                    widget.filterState.copyWith(),
                  ), // Mantener estado actual pero cerrar
                ),
        ),
      ),
    );
  }
}
