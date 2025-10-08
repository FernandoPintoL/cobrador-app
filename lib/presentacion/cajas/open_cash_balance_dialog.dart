import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/cash_balance_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/cobrador_assignment_provider.dart';
import '../../datos/modelos/usuario.dart';

class OpenCashBalanceDialog extends ConsumerStatefulWidget {
  const OpenCashBalanceDialog({super.key});

  @override
  ConsumerState<OpenCashBalanceDialog> createState() =>
      _OpenCashBalanceDialogState();
}

class _OpenCashBalanceDialogState extends ConsumerState<OpenCashBalanceDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController initialController = TextEditingController(
    text: '0.00',
  );
  Usuario? _selectedCobrador;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.isAdmin || auth.isManager) {
        ref.read(cobradorAssignmentProvider.notifier).cargarCobradores();
      }
    });
  }

  @override
  void dispose() {
    initialController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final usuario = auth.usuario;

    double initial =
        double.tryParse(initialController.text.replaceAll(',', '.')) ?? 0.0;
    setState(() => isProcessing = true);
    try {
      final resp = await ref
          .read(cashBalanceProvider.notifier)
          .open(
            cobradorId: (auth.isAdmin || auth.isManager)
                ? (_selectedCobrador?.id.toInt())
                : null, // Cobrador omite cobrador_id según backend
            date: DateTime.now().toIso8601String().split('T')[0],
            initialAmount: initial,
          );

      if (!mounted) return;

      if (resp['success'] == true) {
        Navigator.of(context).pop(true);
      } else {
        final msg = resp['message'] ?? 'Error abriendo caja';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final assignState = ref.watch(cobradorAssignmentProvider);

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
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lock_open,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Abrir caja',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (auth.isAdmin || auth.isManager)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<Usuario>(
                    isExpanded: true,
                    value: _selectedCobrador,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar cobrador',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: assignState.cobradores
                        .map((u) => DropdownMenuItem<Usuario>(
                              value: u,
                              child: Text(u.nombre),
                            ))
                        .toList(),
                    onChanged: isProcessing
                        ? null
                        : (val) {
                            setState(() => _selectedCobrador = val);
                          },
                    validator: (val) {
                      if (auth.isAdmin || auth.isManager) {
                        if (val == null) return 'Seleccione un cobrador';
                      }
                      return null;
                    },
                  ),
                ),
              if (auth.isAdmin || auth.isManager)
                const SizedBox(height: 16),
              TextFormField(
                controller: initialController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto inicial',
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
                  final parsed = double.tryParse(v.replaceAll(',', '.').trim());
                  if (parsed == null) return 'Ingrese un número válido';
                  if (parsed < 0) return 'No puede ser negativo';
                  return null;
                },
              ),
              if (assignState.isLoading && (auth.isAdmin || auth.isManager))
                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isProcessing ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: isProcessing ? null : _submit,
                    icon: isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 20),
                    label: const Text('Abrir'),
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
