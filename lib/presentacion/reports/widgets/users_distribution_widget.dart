import 'package:flutter/material.dart';

Widget buildUsersCategoryDistribution(Map categories, BuildContext context) {
  final cats = categories.entries.toList();
  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: cats.map((entry) {
      final category = entry.key;
      final count = entry.value ?? 0;
      Color catColor = Colors.purple;
      String icon = '?';
      if (category == 'A') { catColor = Colors.green; icon = '✓'; }
      else if (category == 'B') { catColor = Colors.blue; icon = '○'; }
      else if (category == 'C') { catColor = Colors.orange; icon = '▪'; }
      return SizedBox(
        width: 140,
        child: Card(
          elevation: 0,
          color: catColor.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: catColor.withOpacity(0.2),
                  foregroundColor: catColor,
                  radius: 28,
                  child: Text(icon, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                ),
                const SizedBox(height: 12),
                Text('$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: catColor)),
                const SizedBox(height: 4),
                const Text('clientes', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}
