import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../datos/modelos/client_category.dart';
import '../../datos/api_services/credit_limit_api_service.dart';

/// Pantalla para gestionar los límites de crédito por categoría de cliente.
/// Solo accesible para managers.
class CategoryLimitsScreen extends StatefulWidget {
  const CategoryLimitsScreen({super.key});

  @override
  State<CategoryLimitsScreen> createState() => _CategoryLimitsScreenState();
}

class _CategoryLimitsScreenState extends State<CategoryLimitsScreen> {
  final _apiService = CreditLimitApiService();
  List<ClientCategory> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _apiService.getAllCategories();
      setState(() {
        _categories = categories;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Límites por Categoría'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _buildBody(theme, isDark),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error al cargar categorías',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.withValues(alpha: isDark ? 0.3 : 0.15),
                  Colors.purple.withValues(alpha: isDark ? 0.2 : 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.indigo.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: Colors.indigo,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración de Límites',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Define los límites de crédito para cada categoría de cliente',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Categories list
          ..._categories.map((category) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _CategoryCard(
                  category: category,
                  onEdit: () => _editCategory(category),
                ),
              )),
        ],
      ),
    );
  }

  void _editCategory(ClientCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditCategoryLimitsSheet(
        category: category,
        onSave: (maxAmount, minAmount, maxCredits) async {
          await _updateCategory(category.code, maxAmount, minAmount, maxCredits);
        },
      ),
    );
  }

  Future<void> _updateCategory(
    String code,
    double? maxAmount,
    double? minAmount,
    int? maxCredits,
  ) async {
    try {
      await _apiService.updateCategoryLimits(
        code,
        maxAmount: maxAmount,
        minAmount: minAmount,
        maxCredits: maxCredits,
      );
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Límites de categoría $code actualizados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final ClientCategory category;
  final VoidCallback onEdit;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = Color(category.colorValue);
    final formatter = NumberFormat('#,##0.00');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        category.code,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (category.description != null)
                          Text(
                            category.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar límites',
                    style: IconButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.1),
                      foregroundColor: color,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Limits grid
              Row(
                children: [
                  Expanded(
                    child: _LimitChip(
                      icon: Icons.attach_money,
                      label: 'Monto máx.',
                      value: category.maxAmount != null
                          ? 'Bs. ${formatter.format(category.maxAmount)}'
                          : 'Sin límite',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LimitChip(
                      icon: Icons.credit_card,
                      label: 'Máx. créditos',
                      value: category.maxCredits != null
                          ? '${category.maxCredits}'
                          : 'Sin límite',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              // Warning for category C
              if (category.code.toUpperCase() == 'C' && !category.canCreateNewCredit)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta categoría no puede recibir nuevos créditos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LimitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LimitChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EditCategoryLimitsSheet extends StatefulWidget {
  final ClientCategory category;
  final Future<void> Function(double?, double?, int?) onSave;

  const _EditCategoryLimitsSheet({
    required this.category,
    required this.onSave,
  });

  @override
  State<_EditCategoryLimitsSheet> createState() =>
      _EditCategoryLimitsSheetState();
}

class _EditCategoryLimitsSheetState extends State<_EditCategoryLimitsSheet> {
  late TextEditingController _maxAmountController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxCreditsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _maxAmountController = TextEditingController(
      text: widget.category.maxAmount?.toString() ?? '',
    );
    _minAmountController = TextEditingController(
      text: widget.category.minAmount?.toString() ?? '0',
    );
    _maxCreditsController = TextEditingController(
      text: widget.category.maxCredits?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _maxAmountController.dispose();
    _minAmountController.dispose();
    _maxCreditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(widget.category.colorValue);

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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.category.code,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar Límites',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.category.name,
                          style: TextStyle(color: color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Max amount
              TextField(
                controller: _maxAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto máximo por crédito (Bs.)',
                  hintText: 'Dejar vacío para sin límite',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Min amount
              TextField(
                controller: _minAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto mínimo por crédito (Bs.)',
                  prefixIcon: const Icon(Icons.money_off),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Max credits
              TextField(
                controller: _maxCreditsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Máximo de créditos activos',
                  hintText: 'Dejar vacío para sin límite',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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

    final maxAmount = _maxAmountController.text.isEmpty
        ? null
        : double.tryParse(_maxAmountController.text);
    final minAmount = _minAmountController.text.isEmpty
        ? null
        : double.tryParse(_minAmountController.text);
    final maxCredits = _maxCreditsController.text.isEmpty
        ? null
        : int.tryParse(_maxCreditsController.text);

    await widget.onSave(maxAmount, minAmount, maxCredits);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
