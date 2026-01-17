import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../datos/modelos/credito.dart';
import '../../datos/api_services/payment_api_service.dart';
import '../../negocio/providers/credit_provider.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  final int creditId;

  const PaymentHistoryScreen({super.key, required this.creditId});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  bool _isLoading = true;
  List<Pago> _history = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final details = await ref.read(creditProvider.notifier).getCreditFullDetails(widget.creditId);

      // ✅ OPTIMIZACIÓN: Usar PaymentScheduleHelper para convertir schedule a payments
      final schedule = details?.schedule ?? [];
      final history = schedule.isNotEmpty
          ? PaymentScheduleHelper.scheduleToPayments(
              schedule: schedule,
              creditId: widget.creditId,
            )
          : <Pago>[];

      // Ordenar descendente por fecha de creación o pago
      history.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      setState(() {
        _history = history;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar historial: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de pagos'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _history.isEmpty
                  ? const Center(child: Text('No hay pagos registrados'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = _history[index];
                          final amount = NumberFormat('#,##0.00').format(p.amount);
                          final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(p.paymentDate);
                          final statusColor = _statusColor(p.status);
                          final method = _paymentMethodLabel(p.paymentType);
                          final rowChildren = <Widget>[
                            _StatusChip(status: p.status),
                            const SizedBox(width: 6),
                          ];
                          if (p.cobrador != null) {
                            rowChildren.add(
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person, size: 14, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        p.cobrador!.nombre,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          final subtitleChildren = <Widget>[
                            const SizedBox(height: 2),
                            Text('$dateStr · $method'),
                            const SizedBox(height: 2),
                            Row(children: rowChildren),
                          ];
                          if (p.notes != null && p.notes!.isNotEmpty) {
                            subtitleChildren.add(const SizedBox(height: 4));
                            subtitleChildren.add(Text('Notas: ${p.notes!}'));
                          }
                          /*if (p.latitude != null && p.longitude != null) {
                            subtitleChildren.add(const SizedBox(height: 4));
                            subtitleChildren.add(
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Text('(${p.latitude!.toStringAsFixed(6)}, ${p.longitude!.toStringAsFixed(6)})'),
                                ],
                              ),
                            );
                          }*/
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: statusColor.withAlpha(30),
                                child: Icon(Icons.payments, color: statusColor),
                              ),
                              title: Text(
                                'Cuota #${p.installmentNumber ?? '-'} · Bs. $amount',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: subtitleChildren,
                              ),
                              trailing: p.id > 0
                                  ? IconButton(
                                      icon: const Icon(Icons.share, color: Colors.blue),
                                      tooltip: 'Compartir recibo',
                                      onPressed: () => _shareReceipt(p),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _paymentMethodLabel(String? method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'transfer':
        return 'Transferencia';
      case 'qr':
        return 'QR';
      case 'card':
        return 'Tarjeta';
      default:
        return method ?? 'Método desconocido';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _shareReceipt(Pago pago) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final receiptUrl = await PaymentApiService().getPublicReceiptUrl(pago.id);

      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading

      if (receiptUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener el recibo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mostrar opciones
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('Ver recibo PDF'),
                  onTap: () async {
                    Navigator.pop(context);
                    final uri = Uri.parse(receiptUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.blue),
                  title: const Text('Compartir recibo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await SharePlus.instance.share(
                      ShareParams(
                        text: 'Recibo de pago #${pago.id}\n'
                            'Monto: Bs. ${pago.amount.toStringAsFixed(2)}\n'
                            'Ver recibo: $receiptUrl',
                        subject: 'Recibo de Pago #${pago.id}',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener recibo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Completado';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      case 'failed':
        color = Colors.red;
        label = 'Fallido';
        break;
      default:
        color = Colors.blueGrey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
