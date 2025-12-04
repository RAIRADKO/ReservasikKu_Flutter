import 'package:flutter/material.dart';

Widget statusBadge(String status) {
  Color color;
  String text;

  switch (status) {
    case 'pending':
      color = Colors.orange;
      text = 'Menunggu';
      break;
    case 'approved':
      color = Colors.green;
      text = 'Disetujui';
      break;
    case 'rejected':
      color = Colors.red;
      text = 'Ditolak';
      break;
    case 'canceled_by_user':
    case 'canceled_by_admin':
      color = Colors.grey;
      text = 'Dibatalkan';
      break;
    default:
      color = Colors.blue;
      text = status;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );
}