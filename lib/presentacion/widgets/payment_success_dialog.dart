import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Diálogo que se muestra después de un pago exitoso
/// Permite al usuario ver, imprimir o compartir el recibo
class PaymentSuccessDialog extends ConsumerStatefulWidget {
  final int paymentId;
  final double amount;
  final String? clientName;
  final int creditId;
  final String? receiptUrl;
  final VoidCallback? onClose;

  const PaymentSuccessDialog({
    super.key,
    required this.paymentId,
    required this.amount,
    this.clientName,
    required this.creditId,
    this.receiptUrl,
    this.onClose,
  });

  @override
  ConsumerState<PaymentSuccessDialog> createState() =>
      _PaymentSuccessDialogState();

  /// Método estático para mostrar el diálogo
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required int paymentId,
    required double amount,
    String? clientName,
    required int creditId,
    String? receiptUrl,
    VoidCallback? onClose,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentSuccessDialog(
        paymentId: paymentId,
        amount: amount,
        clientName: clientName,
        creditId: creditId,
        receiptUrl: receiptUrl,
        onClose: onClose,
      ),
    );
  }
}

class _PaymentSuccessDialogState extends ConsumerState<PaymentSuccessDialog> {
  bool _isLoading = false;
  String? _error;

  String _formatCurrency(double value) {
    return 'Bs. ${value.toStringAsFixed(2)}';
  }

  /// Abre el recibo PDF en el navegador
  Future<void> _openReceipt() async {
    if (widget.receiptUrl == null) {
      setState(() {
        _error = 'URL del recibo no disponible';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(widget.receiptUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _error = 'No se pudo abrir el recibo';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al abrir el recibo: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Comparte la URL del recibo
  Future<void> _shareReceipt() async {
    if (widget.receiptUrl == null) {
      setState(() {
        _error = 'URL del recibo no disponible';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Recibo de pago #${widget.paymentId}\n'
              'Monto: ${_formatCurrency(widget.amount)}\n'
              'Ver recibo: ${widget.receiptUrl}',
          subject: 'Recibo de Pago #${widget.paymentId}',
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Error al compartir: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de éxito
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              'Pago Registrado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ),
            const SizedBox(height: 8),

            // Monto
            Text(
              _formatCurrency(widget.amount),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),

            // Cliente y crédito
            if (widget.clientName != null)
              Text(
                widget.clientName!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                textAlign: TextAlign.center,
              ),
            Text(
              'Crédito #${widget.creditId}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pago #${widget.paymentId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),

            // Error si existe
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Separador
            Divider(color: Colors.grey.shade300),

            const SizedBox(height: 12),

            // Título de opciones de recibo
            Text(
              'Opciones de Recibo',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
            ),

            const SizedBox(height: 12),

            // Botones de acción para recibo
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (widget.receiptUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Ver PDF
                  _ActionButton(
                    icon: Icons.picture_as_pdf,
                    label: 'Ver PDF',
                    color: Colors.blue,
                    onTap: _openReceipt,
                  ),
                  // Compartir
                  _ActionButton(
                    icon: Icons.share,
                    label: 'Compartir',
                    color: Colors.green,
                    onTap: _shareReceipt,
                  ),
                ],
              )
            else
              Text(
                'Recibo no disponible',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
      actions: [
        // Botón de cerrar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(context).pop();
                    widget.onClose?.call();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Cerrar'),
          ),
        ),
      ],
    );
  }
}

/// Botón de acción circular para las opciones del recibo
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
