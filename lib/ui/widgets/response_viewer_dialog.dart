import 'package:flutter/material.dart';
import 'dart:convert';

class ResponseViewerDialog {
  static void show(BuildContext context, Map<String, dynamic> response, {String title = 'Respuesta del servidor'}) {
    showDialog(
      context: context,
      builder: (context) {
        final formatted = const JsonEncoder.withIndent('  ').convert(response);
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                formatted,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CERRAR'),
            ),
          ],
        );
      },
    );
  }
}
