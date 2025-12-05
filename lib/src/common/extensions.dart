import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String formattedDate() {
    return DateFormat('dd MMM yyyy').format(this);
  }

  String formattedDateTime() {
    return DateFormat('dd MMM yyyy, HH:mm').format(this);
  }
}

extension TimeOfDayExtension on TimeOfDay {
  String formatTime(BuildContext context) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    return DateFormat.jm().format(dateTime).replaceAll('.', '');
  }
  
  String toHHmm() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
  
  String statusToIndonesian() {
    switch (this) {
      case "pending": return "Menunggu";
      case "approved": return "Disetujui";
      case "rejected": return "Ditolak";
      case "canceled_by_user": return "Dibatalkan User";
      case "canceled_by_admin": return "Dibatalkan Admin";
      default: return capitalize();
    }
  }
}