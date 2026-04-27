part of 'credit_form_screen.dart';

extension _CreditFormWidgets on _CreditFormScreenState {
  // ============================================================
  // Título de sección
  // ============================================================
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Card de ubicación
  // ============================================================
  Widget _buildLocationCard() {
    final hasLocation =
        _latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty;

    return Card(
      elevation: 0,
      color: hasLocation ? Colors.green.shade50 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasLocation ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasLocation ? Icons.location_on : Icons.location_off,
                  color: hasLocation
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLocation ? 'Ubicación registrada' : 'Sin ubicación',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: hasLocation
                              ? Colors.green.shade900
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (_isLocationCardExpanded) ...[
                        if (_addressController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _addressController.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (hasLocation)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Lat: ${double.tryParse(_latitudeController.text)?.toStringAsFixed(6) ?? ""}, '
                              'Lng: ${double.tryParse(_longitudeController.text)?.toStringAsFixed(6) ?? ""}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isLocationCardExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () {
                    // ignore: invalid_use_of_protected_member
                    setState(() {
                      _isLocationCardExpanded = !_isLocationCardExpanded;
                    });
                  },
                  tooltip: _isLocationCardExpanded
                      ? 'Ocultar detalles'
                      : 'Ver detalles',
                ),
                IconButton(
                  icon: Icon(
                    _isLocating ? Icons.hourglass_empty : Icons.my_location,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _isLocating ? null : _useCurrentLocation,
                  tooltip: 'Obtener ubicación actual',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Card de fecha fin calculada
  // ============================================================
  Widget _buildEndDateCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.event_available, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha estimada de finalización',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _endDate != null
                        ? DateFormat(
                            'EEEE, dd \'de\' MMMM \'de\' yyyy',
                            'es',
                          ).format(_endDate!)
                        : 'Selecciona fecha de inicio y cuotas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _endDate != null
                          ? Colors.blue.shade900
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Fila del resumen financiero (grande)
  // ============================================================
  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Fila compacta de fechas
  // ============================================================
  Widget _buildCompactDateRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Resumen financiero completo
  // FIX: calcula installmentAmount directamente desde estado,
  // no desde el controlador, para reflejar _calcOnRemainingAmount
  // en tiempo real.
  // ============================================================
  Widget _buildFinancialSummary() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final installments = int.tryParse(_durationDaysController.text) ?? 0;
    final interestRate = double.tryParse(_interestRateController.text) ?? 0.0;
    final downPayment = _isCustomCredit
        ? (double.tryParse(_downPaymentController.text) ?? 0.0)
        : 0.0;

    // Fuente de verdad única: misma lógica que _updateCalculations
    final calc = CreditCalculation(
      amount: amount,
      interestRate: interestRate,
      downPayment: downPayment,
      installments: installments,
      calcOnRemainingAmount: _isCustomCredit && _calcOnRemainingAmount,
    );

    final interest = calc.interest;
    final totalWithInterest = calc.totalWithInterest;
    final balance = calc.balance;
    final installmentAmount = calc.installmentAmount;
    final downPaymentInstallments = calc.downPaymentInstallments;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 8),
              Text(
                'Resumen del Credito',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fechas
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                _buildCompactDateRow(
                  icon: Icons.event_note,
                  label: 'Inicio:',
                  value: _startDate != null
                      ? DateFormat('dd/MM/yyyy').format(_startDate!)
                      : 'No seleccionada',
                  color: Colors.blue.shade700,
                ),
                _buildCompactDateRow(
                  icon: Icons.event_available,
                  label: 'Finalizacion:',
                  value: _endDate != null
                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                      : 'Pendiente',
                  color: Colors.blue.shade700,
                ),
                if (_scheduledDeliveryDate != null)
                  _buildCompactDateRow(
                    icon: Icons.local_shipping,
                    label: 'Entrega:',
                    value: DateFormat('dd/MM/yyyy').format(_scheduledDeliveryDate!),
                    color: Colors.purple.shade700,
                  ),
              ],
            ),
          ),

          // Desglose financiero
          Divider(color: Colors.orange.shade300, thickness: 2),

          if (amount > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Precio total:',
                      style: TextStyle(color: Colors.grey.shade700)),
                  Text('Bs. ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (interestRate > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '+ Interes (${interestRate.toStringAsFixed(0)}%):',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                    Text(
                      'Bs. ${interest.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
            const Divider(height: 12),
          ],

          _buildSummaryRow(
            icon: Icons.account_balance_wallet,
            label: 'Total a pagar',
            value: totalWithInterest > 0
                ? 'Bs. ${totalWithInterest.toStringAsFixed(2)}'
                : 'Bs. 0.00',
            color: Colors.orange,
          ),

          // Anticipo + equivalencia
          if (_isCustomCredit && downPayment > 0) ...[
            Divider(color: Colors.orange.shade300),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cuota inicial:',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '- Bs. ${downPayment.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (downPaymentInstallments > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 13, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      () {
                        final remainder = downPayment -
                            (downPaymentInstallments * installmentAmount);
                        final base =
                            'Equivale a $downPaymentInstallments cuota${downPaymentInstallments != 1 ? 's' : ''}';
                        return remainder > 0.01
                            ? '$base + Bs. ${remainder.toStringAsFixed(2)} de adelanto'
                            : base;
                      }(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Divider(color: Colors.orange.shade300),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo en cuotas:',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Bs. ${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          Divider(color: Colors.orange.shade300),
          _buildSummaryRow(
            icon: Icons.payments,
            label: _isCustomCredit && _calcOnRemainingAmount && downPayment > 0
                ? 'Cuota ($installments cuotas - sobre saldo)'
                : 'Cuota Sugerida ($installments cuotas)',
            value: installmentAmount > 0
                ? 'Bs. ${installmentAmount.toStringAsFixed(2)}'
                : 'Bs. 0.00',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}
