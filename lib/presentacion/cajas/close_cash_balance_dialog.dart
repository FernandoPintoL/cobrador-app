import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/cash_balance_provider.dart';

class CloseCashBalanceDialog extends ConsumerStatefulWidget {
  final int cashBalanceId;
  const CloseCashBalanceDialog({super.key, required this.cashBalanceId});

  @override
  ConsumerState<CloseCashBalanceDialog> createState() =>
      _CloseCashBalanceDialogState();
}

class _CloseCashBalanceDialogState
    extends ConsumerState<CloseCashBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _finalAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _processing = false;
  // Definimos un estado para controlar la selección, iniciando con 'closed' como predeterminado
  String _selectedStatus = 'closed';

  @override
  void dispose() {
    _finalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final double? finalAmount = double.tryParse(
      _finalAmountController.text.trim(),
    );

    setState(() {
      _processing = true;
    });

    try {
      await ref
          .read(cashBalanceProvider.notifier)
          .close(
            widget.cashBalanceId,
            finalAmount: finalAmount,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            status: _selectedStatus, // Pasamos el estado seleccionado
          );

      // Refrescar detalle y listado
      await ref
          .read(cashBalanceProvider.notifier)
          .getDetail(widget.cashBalanceId);
      await ref.read(cashBalanceProvider.notifier).list();

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caja cerrada correctamente')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cerrando caja: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lock,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Cerrar caja',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _finalAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto final',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null) return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Añade observaciones...',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Selector de estado
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Cerrada'),
                      leading: Radio<String>(
                        value: 'closed',
                        groupValue: _selectedStatus,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Reconciliada'),
                      leading: Radio<String>(
                        value: 'reconciled',
                        groupValue: _selectedStatus,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _processing
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _processing ? null : _submit,
                    icon: _processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock, size: 20),
                    label: const Text('Cerrar caja'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
