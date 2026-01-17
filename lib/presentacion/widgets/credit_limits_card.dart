import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../datos/modelos/client_category.dart';
import '../../datos/api_services/credit_limit_api_service.dart';

/// Widget que muestra los límites de crédito de un cliente
/// y permite editarlos si el usuario tiene permisos de manager.
class CreditLimitsCard extends StatefulWidget {
  final BigInt clientId;
  final String clientName;
  final bool isManager;
  final VoidCallback? onLimitsUpdated;

  const CreditLimitsCard({
    super.key,
    required this.clientId,
    required this.clientName,
    this.isManager = false,
    this.onLimitsUpdated,
  });

  @override
  State<CreditLimitsCard> createState() => _CreditLimitsCardState();
}

class _CreditLimitsCardState extends State<CreditLimitsCard> {
  final _apiService = CreditLimitApiService();
  ClientCreditLimits? _limits;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final limits = await _apiService.getClientCreditLimits(
        widget.clientId.toString(),
      );
      setState(() {
        _limits = limits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.withValues(alpha: isDark ? 0.2 : 0.1),
              Colors.purple.withValues(alpha: isDark ? 0.15 : 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.indigo,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Límites de Crédito',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_limits?.hasCustomLimits == true)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Personalizado',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.isManager)
                    IconButton(
                      onPressed: _showEditDialog,
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Editar límites',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Content
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _buildErrorState()
              else if (_limits != null)
                _buildLimitsContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error al cargar límites',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          TextButton(
            onPressed: _loadLimits,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsContent() {
    final limits = _limits!;
    final effective = limits.effectiveLimits;
    final formatter = NumberFormat('#,##0.00');

    return Column(
      children: [
        // Monto máximo
        _buildLimitRow(
          icon: Icons.attach_money,
          label: 'Monto máximo por crédito',
          value: effective.maxAmount != null
              ? 'Bs. ${formatter.format(effective.maxAmount)}'
              : 'Sin límite',
          color: Colors.green,
        ),

        const SizedBox(height: 12),

        // Máximo de créditos
        _buildLimitRow(
          icon: Icons.credit_card,
          label: 'Máximo de créditos activos',
          value: effective.maxCredits != null
              ? '${effective.maxCredits} créditos'
              : 'Sin límite',
          color: Colors.blue,
        ),

        const SizedBox(height: 12),

        // Créditos actuales y disponibles
        _buildLimitRow(
          icon: Icons.analytics,
          label: 'Créditos actuales / disponibles',
          value: limits.availableCredits != null
              ? '${limits.currentCredits} / ${limits.availableCredits} disponibles'
              : '${limits.currentCredits} activos',
          color: limits.availableCredits == 0 ? Colors.red : Colors.orange,
          showWarning: limits.availableCredits == 0,
        ),

        // Fuente de los límites
        if (limits.clientCategory != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    limits.hasCustomLimits
                        ? 'Usando límites personalizados (no de categoría ${limits.clientCategory})'
                        : 'Límites según categoría ${limits.clientCategory}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLimitRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool showWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (showWarning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LÍMITE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    if (_limits == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditLimitsBottomSheet(
        limits: _limits!,
        clientName: widget.clientName,
        onSave: (creditLimit, maxCredits) async {
          await _updateLimits(creditLimit, maxCredits);
        },
        onClear: () async {
          await _clearLimits();
        },
      ),
    );
  }

  Future<void> _updateLimits(double? creditLimit, int? maxCredits) async {
    try {
      await _apiService.updateClientCreditLimits(
        widget.clientId.toString(),
        creditLimitOverride: creditLimit,
        maxCreditsOverride: maxCredits,
      );
      await _loadLimits();
      widget.onLimitsUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Límites actualizados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearLimits() async {
    try {
      await _apiService.clearClientCreditLimits(widget.clientId.toString());
      await _loadLimits();
      widget.onLimitsUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Límites personalizados eliminados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar límites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// BottomSheet para editar los límites de crédito
class _EditLimitsBottomSheet extends StatefulWidget {
  final ClientCreditLimits limits;
  final String clientName;
  final Future<void> Function(double?, int?) onSave;
  final Future<void> Function() onClear;

  const _EditLimitsBottomSheet({
    required this.limits,
    required this.clientName,
    required this.onSave,
    required this.onClear,
  });

  @override
  State<_EditLimitsBottomSheet> createState() => _EditLimitsBottomSheetState();
}

class _EditLimitsBottomSheetState extends State<_EditLimitsBottomSheet> {
  late TextEditingController _amountController;
  late TextEditingController _creditsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.limits.individualOverrides.creditLimitOverride?.toString() ?? '',
    );
    _creditsController = TextEditingController(
      text: widget.limits.individualOverrides.maxCreditsOverride?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  const Icon(Icons.tune, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Editar Límites de Crédito',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.clientName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Info about category limits
              if (widget.limits.categoryLimits != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Categoría ${widget.limits.clientCategory}: '
                          'Max Bs. ${NumberFormat('#,##0').format(widget.limits.categoryLimits!.maxAmount ?? 0)}, '
                          '${widget.limits.categoryLimits!.maxCredits ?? 0} créditos',
                          style: const TextStyle(fontSize: 13, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Amount field
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto máximo personalizado (Bs.)',
                  hintText: 'Dejar vacío para usar el de categoría',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Límite máximo de monto por crédito',
                ),
              ),

              const SizedBox(height: 16),

              // Credits field
              TextField(
                controller: _creditsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Máximo de créditos personalizado',
                  hintText: 'Dejar vacío para usar el de categoría',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Cantidad máxima de créditos activos permitidos',
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Clear button
                  if (widget.limits.hasCustomLimits)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _handleClear,
                        icon: const Icon(Icons.restore),
                        label: const Text('Restaurar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  if (widget.limits.hasCustomLimits) const SizedBox(width: 12),

                  // Save button
                  Expanded(
                    flex: widget.limits.hasCustomLimits ? 1 : 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final amount = _amountController.text.isEmpty
        ? null
        : double.tryParse(_amountController.text);
    final credits = _creditsController.text.isEmpty
        ? null
        : int.tryParse(_creditsController.text);

    await widget.onSave(amount, credits);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar límites'),
        content: const Text(
          '¿Eliminar los límites personalizados y usar los de la categoría?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      await widget.onClear();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
