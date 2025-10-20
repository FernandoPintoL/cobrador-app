import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/map_provider.dart' as mp;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  int? _selectedCobradorId; // solo visible para admin/manager
  String? _statusFilter; // 'overdue' | 'pending' | 'paid'
  int? _selectedClientId; // cliente seleccionado desde marcador
  LatLng? _myLocation; // ubicación actual del usuario (si disponible)

  // Iconos personalizados de marcadores con etiqueta
  BitmapDescriptor? _iconPaid;
  BitmapDescriptor? _iconNotPaid;
  BitmapDescriptor? _iconUnknown;
  bool _iconsGenerating = false;
  final Map<String, BitmapDescriptor> _markerIconCache = {};

  // Tipo de mapa
  MapType _mapType = MapType.normal;

  // Posición inicial por defecto (Lima)
  static const LatLng _initialCenter = LatLng(-12.0464, -77.0428);
  static const CameraPosition _initialCamera = CameraPosition(
    target: _initialCenter,
    zoom: 11.5,
  );

  // Control para reintentos ligeros
  int _retryCount = 0;

  // Helpers para mostrar si el cliente pagó hoy
  bool? _extractPaidToday(
    dynamic client,
    AsyncValue<List<dynamic>> clientsAsync,
  ) {
    try {
      if (client is Map<String, dynamic>) {
        // Intentar leer directamente del objeto de coordenadas si viene del backend
        final direct = client['paid_today'];
        if (direct is bool) return direct;
        final todayStatus =
            client['today_status'] ?? client['payment_status_today'];
        if (todayStatus is String) {
          final s = todayStatus.toLowerCase();
          if (s == 'paid' || s == 'pagado' || s == 'al_dia' || s == 'al dia')
            return true;
          if (s == 'overdue' || s == 'pendiente' || s == 'no_pagado')
            return false;
        }
      }

      // Si no viene en las coordenadas, buscar en la lista detallada en memoria
      final data = clientsAsync.asData?.value;
      if (data != null) {
        final id = (client['id'] as num?)?.toInt();
        if (id != null) {
          Map<String, dynamic>? detalle;
          for (final e in data) {
            if (e is Map && (e['id'] as num?)?.toInt() == id) {
              detalle = Map<String, dynamic>.from(e as Map);
              break;
            }
          }
          if (detalle != null) {
            // Campo directo
            final pt = detalle['paid_today'];
            if (pt is bool) return pt;
            // Inferir desde pagos recientes
            final pagos =
                (detalle['recent_payments'] as List?)?.cast<dynamic>() ??
                const [];
            if (pagos.isNotEmpty) {
              final now = DateTime.now();
              for (final p in pagos) {
                if (p is Map) {
                  final status = (p['status'] ?? '').toString().toLowerCase();
                  final fechaStr = (p['payment_date'] ?? p['date'] ?? '')
                      .toString();
                  final fecha = _tryParseFlexibleDate(fechaStr);
                  if (fecha != null &&
                      _isSameDay(fecha, now) &&
                      (status.isEmpty ||
                          status == 'paid' ||
                          status == 'completed' ||
                          status == 'success' ||
                          status == 'pagado')) {
                    return true;
                  }
                }
              }
              // Si hay pagos, pero ninguno es hoy, asumir que no pagó hoy
              return false;
            }
          }
        }
      }
    } catch (_) {}
    return null; // sin datos
  }

  String _labelForPaidToday(bool? paid) {
    if (paid == true) return 'Pagó hoy';
    if (paid == false) return 'No pagó hoy';
    return 'Sin datos de hoy';
  }

  double _hueForPaidToday(bool? paid) {
    if (paid == true) return BitmapDescriptor.hueGreen;
    if (paid == false) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueAzure;
  }

  DateTime? _tryParseFlexibleDate(String input) {
    if (input.isEmpty) return null;
    // Intento estándar ISO
    final iso = DateTime.tryParse(input);
    if (iso != null) return iso.toLocal();
    // Intento con sólo fecha (YYYY-MM-DD ...)
    try {
      final y = int.parse(input.substring(0, 4));
      final m = int.parse(input.substring(5, 7));
      final d = int.parse(input.substring(8, 10));
      return DateTime(y, m, d);
    } catch (_) {}
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _ensureMarkerIconsGenerated() async {
    if (!mounted) return;
    if (_iconsGenerating) return;
    if (_iconPaid != null && _iconNotPaid != null && _iconUnknown != null)
      return;
    setState(() => _iconsGenerating = true);
    try {
      final paid = await _createMarkerBitmap('Pagó hoy', Colors.green.shade600);
      final notPaid = await _createMarkerBitmap(
        'No pagó hoy',
        Colors.red.shade400,
      );
      final unknown = await _createMarkerBitmap(
        'Sin datos de hoy',
        Colors.blue.shade400,
      );
      if (!mounted) return;
      setState(() {
        _iconPaid = paid;
        _iconNotPaid = notPaid;
        _iconUnknown = unknown;
        _iconsGenerating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _iconsGenerating = false);
    }
  }

  Future<BitmapDescriptor> _createMarkerBitmap(
    String line1,
    Color color, {
    String? line2,
  }) async {
    final pr = MediaQuery.of(context).devicePixelRatio;

    // 🎨 DISEÑO MODERNO: Colores más vibrantes y gradientes
    final darkColor = Color.lerp(color, Colors.black, 0.2)!;
    final lightColor = Color.lerp(color, Colors.white, 0.3)!;

    // Determinar icono según el estado
    String statusIcon = '●';
    if (line1.contains('Pagó')) {
      statusIcon = '✓'; // Check mark para pagado
    } else if (line1.contains('No pagó')) {
      statusIcon = '✗'; // X para no pagado
    } else {
      statusIcon = '?'; // Interrogación para sin datos
    }

    // Medir los textos con estilos mejorados
    final tpIcon = TextPainter(
      text: TextSpan(
        text: statusIcon,
        style: TextStyle(
          fontSize: 26, // Incrementado de 20 a 26
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 3, // Incrementado de 2 a 3
            ),
          ],
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final tp1 = TextPainter(
      text: TextSpan(
        text: line1,
        style: TextStyle(
          fontSize: 14, // Incrementado de 13 a 14
          fontWeight: FontWeight.bold,
          color: darkColor,
          shadows: [
            Shadow(
              color: Colors.white.withOpacity(0.8),
              offset: const Offset(0.5, 0.5),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    TextPainter? tp2;
    if (line2 != null && line2.trim().isNotEmpty) {
      tp2 = TextPainter(
        text: TextSpan(
          text: line2,
          style: TextStyle(
            fontSize: 13, // Incrementado de 12 a 13
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.5),
                offset: const Offset(0.5, 0.5),
                blurRadius: 1,
              ),
            ],
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
    }

    const paddingH = 18.0; // Incrementado de 12 a 14
    const paddingV = 14.0; // Incrementado de 8 a 10
    const spacing = 14.0; // Incrementado de 8 a 10
    const lineGap = 9.0; // Incrementado de 4 a 5
    const pinRadius = 42.0; // Incrementado de 18 a 24 (33% más grande)
    const pointerH = 22.0; // Incrementado de 14 a 18
    const shadowOffset = 9.0; // Incrementado de 4 a 5

    final contentW = tp2 == null
        ? tp1.width
        : (tp1.width > tp2.width ? tp1.width : tp2.width);
    final labelW = contentW + paddingH * 2;
    final contentH = tp2 == null
        ? tp1.height
        : (tp1.height + lineGap + tp2.height);
    final labelH = contentH + paddingV * 2;

    final width = labelW + 24.0; // Más margen (incrementado de 20 a 24)
    final w = width < 120.0
        ? 120.0
        : width; // Ancho mínimo incrementado de 100 a 120
    final height = labelH + spacing + pinRadius * 2 + pointerH + shadowOffset;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 🎨 SOMBRA para la etiqueta (efecto depth)
    final labelLeft = (w - labelW) / 2;
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelLeft + 3, 3, labelW, labelH),
      const Radius.circular(12),
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(shadowRect, shadowPaint);

    // 🎨 GRADIENTE para la etiqueta (moderno)
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelLeft, 0, labelW, labelH),
      const Radius.circular(12),
    );

    final gradient = ui.Gradient.linear(
      Offset(labelLeft, 0),
      Offset(labelLeft, labelH),
      [Colors.white, lightColor.withOpacity(0.15)],
    );

    final fill = Paint()..shader = gradient;
    canvas.drawRRect(rrect, fill);

    // Borde más grueso y llamativo
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5; // Incrementado de 3.0 a 3.5
    canvas.drawRRect(rrect, border);

    // Texto línea 1
    tp1.paint(canvas, Offset(labelLeft + paddingH, paddingV));

    // Texto línea 2 (opcional)
    if (tp2 != null) {
      final y2 = paddingV + tp1.height + lineGap;
      tp2.paint(canvas, Offset(labelLeft + paddingH, y2));
    }

    // 🎨 SOMBRA para el círculo del pin
    final circleCenter = Offset(w / 2, labelH + spacing + pinRadius);
    final shadowCircle = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      Offset(circleCenter.dx + 2, circleCenter.dy + 2),
      pinRadius,
      shadowCircle,
    );

    // 🎨 GRADIENTE para el círculo del pin
    final circleGradient = ui.Gradient.radial(
      circleCenter,
      pinRadius,
      [lightColor, color, darkColor],
      [0.0, 0.5, 1.0],
    );
    final pinPaint = Paint()..shader = circleGradient;
    canvas.drawCircle(circleCenter, pinRadius, pinPaint);

    // Borde blanco alrededor del pin
    final pinBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0; // Incrementado de 3.0 a 4.0
    canvas.drawCircle(circleCenter, pinRadius, pinBorder);

    // Borde de color alrededor del borde blanco
    final pinBorder2 = Paint()
      ..color = darkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Incrementado de 1.5 a 2.0
    canvas.drawCircle(
      circleCenter,
      pinRadius + 2.0,
      pinBorder2,
    ); // Ajustado radio

    // 🎨 ICONO de estado en el centro del pin
    final iconX = circleCenter.dx - tpIcon.width / 2;
    final iconY = circleCenter.dy - tpIcon.height / 2;
    tpIcon.paint(canvas, Offset(iconX, iconY));

    // 🎨 SOMBRA para el triángulo
    final tipY = labelH + spacing + pinRadius * 2 + pointerH;
    final topY = labelH + spacing + pinRadius * 2;
    final shadowPath = Path()
      ..moveTo(w / 2 + 2, tipY + 2)
      ..lineTo(w / 2 - 10 + 2, topY + 2) // Incrementado de 8 a 10
      ..lineTo(w / 2 + 10 + 2, topY + 2) // Incrementado de 8 a 10
      ..close();
    canvas.drawPath(shadowPath, shadowCircle);

    // Triángulo del pin con gradiente (más ancho)
    final path = Path()
      ..moveTo(w / 2, tipY)
      ..lineTo(w / 2 - 12, topY) // Incrementado de 10 a 12
      ..lineTo(w / 2 + 12, topY) // Incrementado de 10 a 12
      ..close();
    canvas.drawPath(path, pinPaint);

    // Borde del triángulo (más grueso)
    final pathBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5; // Incrementado de 2.0 a 2.5
    canvas.drawPath(path, pathBorder);

    final picture = recorder.endRecording();
    final img = await picture.toImage((w * pr).ceil(), (height * pr).ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // Color directo para el estado de pago de hoy (para dibujar el pin y la etiqueta)
  Color _colorForPaidToday(bool? paid) {
    if (paid == true) return Colors.green.shade600;
    if (paid == false) return Colors.red.shade400;
    return Colors.blue.shade400;
  }

  // Buscar detalles del cliente por id en el provider de clientes
  Map<String, dynamic>? _getClientDetail(
    int id,
    AsyncValue<List<dynamic>> clientsAsync,
  ) {
    final list = clientsAsync.asData?.value;
    if (list == null) return null;
    for (final item in list) {
      if (item is Map && (item['id'] as num?)?.toInt() == id) {
        return Map<String, dynamic>.from(item as Map);
      }
    }
    return null;
  }

  // Intentar extraer monto de cuota y número de cuota desde múltiples posibles llaves
  Map<String, dynamic> _extractNextPaymentInfo(Map<String, dynamic> d) {
    double? amount;
    int? installment;

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    // 1) Directo en el objeto de cliente
    for (final k in [
      'installment_amount',
      'amount_per_installment',
      'next_payment_amount',
      'quota_amount',
      'installmentAmount',
    ]) {
      amount ??= _toDouble(d[k]);
    }
    for (final k in [
      'next_installment_number',
      'installment_number',
      'numero_cuota',
      'current_installment_number',
    ]) {
      final val = d[k];
      if (val is num) {
        installment ??= val.toInt();
      } else if (val != null) {
        installment ??= int.tryParse(val.toString());
      }
    }

    // 2) Buscar en créditos (priorizar los activos)
    if (d['credits'] is List) {
      final credits = (d['credits'] as List).cast<dynamic>();
      Map? active;
      for (final cr in credits) {
        if (cr is Map) {
          final status = (cr['status'] ?? '').toString().toLowerCase();
          if (status == 'active' ||
              status == 'vigente' ||
              status == 'en_curso' ||
              status == 'en curso') {
            active = cr;
            break;
          }
        }
      }
      final Map? chosen =
          active ??
          (credits.isNotEmpty && credits.first is Map
              ? credits.first as Map
              : null);
      if (chosen != null) {
        for (final k in [
          'installment_amount',
          'amount_per_installment',
          'next_payment_amount',
          'quota_amount',
          'installmentAmount',
        ]) {
          amount ??= _toDouble(chosen[k]);
        }
        for (final k in [
          'next_installment_number',
          'installment_number',
          'numero_cuota',
          'current_installment_number',
        ]) {
          final val = chosen[k];
          if (val is num) {
            installment ??= val.toInt();
          } else if (val != null) {
            installment ??= int.tryParse(val.toString());
          }
        }
        // Si aún no hay monto pero hay amount y número total de cuotas, intentar estimar
        if (amount == null &&
            chosen['amount'] != null &&
            chosen['total_installments'] != null) {
          final totalAmount = _toDouble(chosen['amount']);
          final totalInst = (chosen['total_installments'] is num)
              ? (chosen['total_installments'] as num).toInt()
              : int.tryParse(chosen['total_installments'].toString());
          if (totalAmount != null && (totalInst ?? 0) > 0) {
            amount = totalAmount / (totalInst!);
          }
        }
      }
    }

    return {'amount': amount, 'installment': installment};
  }

  String _formatSoles(num v) => 'S/ ${v.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    // Cargar lista de cobradores si el usuario es manager (o admin, si aplica)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      final role = _getUserRole(auth.usuario?.roles ?? []);
      if (role == 'manager') {
        final managerId = auth.usuario!.id.toString();
        ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);
      }
      // Intentar centrar en mi ubicación
      _initLocation();
      // Generar iconos personalizados de marcadores
      _ensureMarkerIconsGenerated();
    });
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;

      setState(() {
        _myLocation = latLng;
      });

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
      }
    } catch (e) {
      // Ignorar silenciosamente para no interrumpir la UI
    }
  }

  String _getUserRole(List<String> roles) {
    final lowered = roles.map((e) => e.toLowerCase()).toList();
    if (lowered.contains('admin')) return 'admin';
    if (lowered.contains('manager')) return 'manager';
    if (lowered.contains('cobrador')) return 'cobrador';
    return lowered.isNotEmpty ? lowered.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.usuario;
    final role = _getUserRole(user?.roles ?? []);

    // Providers
    final coordsAsync = ref.watch(
      mp.clientCoordinatesProvider(_selectedCobradorId),
    );
    final statsAsync = ref.watch(mp.mapStatsProvider(_selectedCobradorId));
    final clientsAsync = ref.watch(
      mp.mapClientsProvider(
        mp.MapClientsQuery(
          status: _statusFilter,
          cobradorId: _selectedCobradorId,
        ),
      ),
    );

    final isAdminOrManager = role == 'admin' || role == 'manager';

    // Construir marcadores desde coordenadas
    final markers = <Marker>{};
    coordsAsync.when(
      data: (resp) {
        final data = (resp['data'] ?? resp) as Map<String, dynamic>;
        final clients = (data['clients'] ?? []) as List<dynamic>;
        for (final c in clients) {
          final coords = c['coordinates'];
          if (coords != null &&
              coords['latitude'] != null &&
              coords['longitude'] != null) {
            final lat = (coords['latitude'] as num).toDouble();
            final lng = (coords['longitude'] as num).toDouble();
            final id = (c['id'] as num).toInt();
            final name = (c['name'] ?? 'Cliente') as String;
            // Determinar si pagó hoy (si es posible)
            final paidToday = _extractPaidToday(
              Map<String, dynamic>.from(c as Map),
              clientsAsync,
            );
            final hue = _hueForPaidToday(paidToday);
            final pagoLabel = _labelForPaidToday(paidToday);

            // Construir segunda línea con monto y número de cuota (si se puede)
            final detail = _getClientDetail(id, clientsAsync);
            String? secondLine;
            if (detail != null) {
              final next = _extractNextPaymentInfo(detail);
              final amount = next['amount'] as double?;
              final cuota = next['installment'] as int?;
              if (cuota != null && amount != null) {
                secondLine = 'Cuota #$cuota · ${_formatSoles(amount)}';
              } else if (cuota != null) {
                secondLine = 'Cuota #$cuota';
              } else if (amount != null) {
                secondLine = _formatSoles(amount);
              }
            }

            // Elegir icono (dinámico con 2 líneas si hay datos, si no, genérico)
            final Color color = _colorForPaidToday(paidToday);
            BitmapDescriptor? chosenIcon;
            if (secondLine != null) {
              final st = paidToday == true
                  ? '1'
                  : paidToday == false
                  ? '0'
                  : '-1';
              final key = 'st:$st|l2:$secondLine';
              chosenIcon = _markerIconCache[key];
              if (chosenIcon == null) {
                // Generar en segundo plano y refrescar
                Future.microtask(() async {
                  final icon = await _createMarkerBitmap(
                    pagoLabel,
                    color,
                    line2: secondLine,
                  );
                  if (!mounted) return;
                  setState(() {
                    _markerIconCache[key] = icon;
                  });
                });
              }
            }
            // Fallbacks
            chosenIcon ??= (paidToday == true
                ? _iconPaid
                : paidToday == false
                ? _iconNotPaid
                : _iconUnknown);
            final finalIcon =
                chosenIcon ?? BitmapDescriptor.defaultMarkerWithHue(hue);

            markers.add(
              Marker(
                markerId: MarkerId('client_$id'),
                position: LatLng(lat, lng),
                icon: finalIcon,
                infoWindow: InfoWindow(
                  title: name,
                  snippet: secondLine != null
                      ? '$pagoLabel — $secondLine'
                      : pagoLabel,
                  onTap: () {
                    setState(() => _selectedClientId = id);
                    _showClientDetailsSheet(context, id, clientsAsync);
                  },
                ),
                onTap: () {
                  setState(() => _selectedClientId = id);
                },
              ),
            );
          }
        }
      },
      error: (_, __) {},
      loading: () {},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Clientes'),
        actions: [
          // Filtro por cobrador (solo admin/manager)
          if (isAdminOrManager) _buildCobradorSelector(role),
          IconButton(
            tooltip: _mapType == MapType.satellite
                ? 'Mapa estándar'
                : 'Vista satélite',
            icon: Icon(
              _mapType == MapType.satellite
                  ? Icons.map
                  : Icons.satellite_alt_outlined,
            ),
            onPressed: () => setState(() {
              _mapType = _mapType == MapType.satellite
                  ? MapType.normal
                  : MapType.satellite;
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Stats resumen
          _buildStatsBar(statsAsync),

          // Filtros por estado
          _buildStatusChips(),

          // Mapa
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  mapType: _mapType,
                  initialCameraPosition: _initialCamera,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  markers: markers,
                  onMapCreated: (controller) async {
                    _mapController = controller;
                    // Intentar centrar primero en mi ubicación si está disponible
                    if (_myLocation != null) {
                      await controller.animateCamera(
                        CameraUpdate.newLatLngZoom(_myLocation!, 15),
                      );
                      return;
                    }
                    // Si no hay ubicación aún, enfocar al primer marcador disponible
                    if (markers.isNotEmpty) {
                      final first = markers.first.position;
                      await controller.animateCamera(
                        CameraUpdate.newLatLngZoom(first, 13),
                      );
                    }
                  },
                ),

                // Estados de carga/empty/error superpuestos
                Positioned.fill(child: _buildOverlays(coordsAsync)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlays(AsyncValue<Map<String, dynamic>> coordsAsync) {
    return coordsAsync.when(
      data: (resp) {
        final data = (resp['data'] ?? resp) as Map<String, dynamic>;
        final total = (data['total_clients'] ?? 0) as int;
        final clients = (data['clients'] ?? []) as List<dynamic>;
        if (clients.isEmpty || total == 0) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'No hay clientes para mostrar',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    // Reintentar recargando provider
                    setState(() {});
                  },
                  child: const Text('Refrescar'),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        if (_retryCount < 2) {
          // reintento simple
          _retryCount++;
          Future.microtask(() => setState(() {}));
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 8),
              Text(
                'Error al cargar coordenadas:\n$e',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildCobradorSelector(String role) {
    final managerState = ref.watch(managerProvider);
    final isLoading = managerState.isLoading;
    final cobradores = managerState.cobradoresAsignados;

    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            hint: const Text('Filtrar por cobrador'),
            value: _selectedCobradorId,
            onChanged: isLoading
                ? null
                : (v) {
                    setState(() => _selectedCobradorId = v);
                  },
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
              ...cobradores.map(
                (u) => DropdownMenuItem<int?>(
                  value: u.id.toInt(),
                  child: Text(u.nombre ?? 'Usuario ${u.id}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => const SizedBox(height: 2),
      data: (data) {
        final d = data;
        final total = (d['total_clients'] as num?)?.toInt() ?? 0;
        final withLoc = (d['clients_with_location'] as num?)?.toInt() ?? 0;
        final overdue = (d['overdue_clients'] as num?)?.toInt() ?? 0;
        final pending = (d['pending_clients'] as num?)?.toInt() ?? 0;
        final paid = (d['paid_clients'] as num?)?.toInt() ?? 0;
        final balance = (d['total_balance'] as num?)?.toDouble() ?? 0.0;

        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Total', '$total'),
                _chip('Con ubicación', '$withLoc'),
                _chip('Vencidos', '$overdue', color: Colors.red.shade400),
                _chip('Pendientes', '$pending', color: Colors.amber.shade700),
                _chip('Al día', '$paid', color: Colors.green.shade600),
                _chip('Balance', balance.toStringAsFixed(2)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, String value, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? scheme.primary).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (color ?? scheme.primary).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color ?? scheme.primary)),
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
  }

  Widget _buildStatusChips() {
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
                key == _statusFilter || (key == null && _statusFilter == null);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(it['label'] as String),
                selected: selected,
                onSelected: (_) => setState(() => _statusFilter = key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClientDetailsSheet(
    BuildContext context,
    int clientId,
    AsyncValue<List<dynamic>> clientsAsync,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: clientsAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Error al cargar detalles:\n$e',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (clients) {
                  final c = clients.cast<Map<String, dynamic>?>().firstWhere(
                    (x) => x != null && x['id'] == clientId,
                    orElse: () => null,
                  );
                  if (c == null) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text('Cliente no encontrado en memoria'),
                      ),
                    );
                  }

                  final status = (c['overall_status'] ?? '').toString();
                  final balance =
                      (c['total_balance'] as num?)?.toDouble() ?? 0.0;
                  final credits = (c['credits'] as List?) ?? const [];
                  final payments = (c['recent_payments'] as List?) ?? const [];
                  final address = (c['address'] ?? '') as String;
                  final phone = (c['phone'] ?? '') as String;
                  final paidToday = _extractPaidToday(c, clientsAsync);

                  Color colorForStatus(String s) {
                    switch (s) {
                      case 'overdue':
                        return Colors.red.shade400;
                      case 'pending':
                        return Colors.amber.shade700;
                      case 'paid':
                        return Colors.green.shade600;
                      default:
                        return Theme.of(context).colorScheme.primary;
                    }
                  }

                  IconData iconForStatus(String s) {
                    switch (s) {
                      case 'overdue':
                        return Icons.warning_rounded;
                      case 'pending':
                        return Icons.schedule_rounded;
                      case 'paid':
                        return Icons.check_circle_rounded;
                      default:
                        return Icons.info_rounded;
                    }
                  }

                  return DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.7,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (_, controller) {
                      return SingleChildScrollView(
                        controller: controller,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🎯 Handle indicator
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // 🎨 Header con gradiente
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorForStatus(status).withOpacity(0.2),
                                    colorForStatus(status).withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorForStatus(
                                    status,
                                  ).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorForStatus(status),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          iconForStatus(status),
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (c['name'] ?? 'Cliente')
                                                  as String,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: colorForStatus(
                                                      status,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    status.toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                if (paidToday != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: paidToday
                                                          ? Colors.green
                                                          : Colors.orange,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      paidToday
                                                          ? '✓ PAGÓ HOY'
                                                          : '✗ NO PAGÓ HOY',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (address.isNotEmpty ||
                                      phone.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                  ],
                                  if (address.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          phone,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 💰 Balance destacado
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade400,
                                    Colors.deepPurple.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'BALANCE TOTAL',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'S/ ${balance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 📊 Estadísticas
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _modernBadge(
                                    'Créditos activos',
                                    (c['active_credits_count'] ?? 0).toString(),
                                    Icons.account_balance_wallet,
                                    Colors.blue,
                                  ),
                                  _modernBadge(
                                    'Cuotas vencidas',
                                    (c['overdue_payments_count'] ?? 0)
                                        .toString(),
                                    Icons.warning_amber,
                                    Colors.red,
                                  ),
                                  _modernBadge(
                                    'Pendientes',
                                    (c['pending_payments_count'] ?? 0)
                                        .toString(),
                                    Icons.schedule,
                                    Colors.orange,
                                  ),
                                  _modernBadge(
                                    'Pagadas',
                                    (c['paid_payments_count'] ?? 0).toString(),
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 💳 Créditos
                            if (credits.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Créditos',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...credits.map(
                                (cr) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    title: Text(
                                      'S/ ${((cr as Map)['amount'] as num).toString()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Saldo: S/ ${((cr)['balance'] as num)} • ${((cr)['status'])}',
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // 💸 Pagos recientes
                            if (payments.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pagos recientes',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...payments.map(
                                (p) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.payments_outlined,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    title: Text(
                                      'S/ ${((p as Map)['amount'] as num)} • ${p['status']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${p['payment_method'] ?? ''} • ${p['payment_date'] ?? ''}',
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _modernBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
