import 'package:flutter/material.dart';

/// Campo de filtro por fecha con selector de calendario
class DateFilterField extends StatefulWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const DateFilterField({
    required this.label,
    this.value,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<DateFilterField> createState() => _DateFilterFieldState();
}

class _DateFilterFieldState extends State<DateFilterField> {
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant DateFilterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller?.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _controller!.text.isNotEmpty
        ? DateTime.tryParse(_controller!.text) ?? now
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      final iso = picked.toIso8601String().split('T').first;
      _controller?.text = iso;
      widget.onChanged(iso);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDate,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller?.clear();
                widget.onChanged(null);
              },
            ),
          ],
        ),
      ),
      onTap: _pickDate,
    );
  }
}
