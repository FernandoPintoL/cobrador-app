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
    return AlertDialog(
      title: const Text('Cerrar caja'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _finalAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto final (opcional)',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed = double.tryParse(v.trim());
                if (parsed == null) return 'Ingrese un número válido';
                return null;
              },
            ),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _processing
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _processing ? null : _submit,
          child: _processing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cerrar caja'),
        ),
      ],
    );
  }
}
