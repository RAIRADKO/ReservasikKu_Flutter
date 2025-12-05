import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final reservationProvider = Provider<ReservationService>((ref) {
  return ReservationService(ref.watch(supabaseProvider));
});

final tableProvider = Provider<TableService>((ref) {
  return TableService(ref.watch(supabaseProvider));
});

class ReservationService {
  final SupabaseClient client;

  ReservationService(this.client);

  Future<List<Map<String, dynamic>>> getAvailableTables({
    required int peopleCount,
    required DateTime reservationDate,
    required TimeOfDay reservationTime,
  }) async {
    int requiredCapacity = peopleCount;
    if (peopleCount.isOdd && peopleCount >= 3) {
      requiredCapacity = peopleCount + 1;
    }

    final tables = await client
        .from('tables')
        .select()
        .gte('capacity', requiredCapacity)
        .eq('is_active', true)
        .order('capacity', ascending: true);

    if (tables.isEmpty) return [];

    final tableIds = (tables as List).map((t) => t['id']).toList();

    final formattedTime = '${reservationTime.hour.toString().padLeft(2, '0')}:'
        '${reservationTime.minute.toString().padLeft(2, '0')}:00';
    final formattedDate = reservationDate.toIso8601String().split('T')[0];

    final reservations = await client
        .from('reservations')
        .select('table_id')
        .inFilter('table_id', tableIds)
        .eq('reservation_date', formattedDate)
        .eq('reservation_time', formattedTime)
        .not('status', 'in', '(canceled_by_user,canceled_by_admin,rejected)');

    final reservedTableIds = (reservations as List)
        .map((r) => r['table_id'])
        .toSet();

    return (tables as List<dynamic>)
        .where((table) => !reservedTableIds.contains(table['id']))
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<void> createReservation({
    required String userId,
    required int tableId,
    required DateTime reservationDate,
    required TimeOfDay reservationTime,
    required int peopleCount,
  }) async {
    final now = DateTime.now();
    if (reservationDate.isBefore(now)) {
      throw Exception('Tidak bisa memesan untuk waktu yang sudah lewat');
    }

    final formattedTime = '${reservationTime.hour.toString().padLeft(2, '0')}:'
        '${reservationTime.minute.toString().padLeft(2, '0')}:00';
    final formattedDate = reservationDate.toIso8601String().split('T')[0];

    await client.from('reservations').insert({
      'user_id': userId,
      'table_id': tableId,
      'reservation_date': formattedDate,
      'reservation_time': formattedTime,
      'people_count': peopleCount,
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getUserReservations(String userId) async {
    final data = await client
        .from('reservations')
        .select('*, tables(table_number, capacity)')
        .eq('user_id', userId)
        .order('reservation_date', ascending: false)
        .order('reservation_time', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getReservationDetail(int reservationId) async {
    final data = await client
        .from('reservations')
        .select('*, tables(*), users(name, phone_number)')
        .eq('id', reservationId)
        .single();

    return Map<String, dynamic>.from(data);
  }

  Future<void> cancelReservation(int reservationId, String cancelType) async {
    await client
        .from('reservations')
        .update({'status': cancelType})
        .eq('id', reservationId);
  }

  Future<List<Map<String, dynamic>>> getPendingReservations() async {
    final data = await client
        .from('reservations')
        .select('*, tables(table_number, capacity), users(name, phone_number)')
        .eq('status', 'pending')
        .order('reservation_date')
        .order('reservation_time');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAllReservations({
    String? status,
    DateTime? date,
  }) async {
    // Build query dengan filter kondisional
    PostgrestFilterBuilder query = client
        .from('reservations')
        .select('*, tables(table_number, capacity), users(name, phone_number)');

    // Apply filters jika ada
    if (status != null) {
      query = query.eq('status', status);
    }

    if (date != null) {
      final formattedDate = date.toIso8601String().split('T')[0];
      query = query.eq('reservation_date', formattedDate);
    }

    // Apply ordering dan execute query
    final data = await query
        .order('reservation_date', ascending: false)
        .order('reservation_time', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateReservationStatus(int reservationId, String status) async {
    await client
        .from('reservations')
        .update({'status': status})
        .eq('id', reservationId);
  }
}

class TableService {
  final SupabaseClient client;

  TableService(this.client);

  Future<List<Map<String, dynamic>>> getAllTables() async {
    final data = await client
        .from('tables')
        .select()
        .order('table_number');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createTable({
    required String tableNumber,
    required int capacity,
    required String location,
    required bool isActive,
  }) async {
    await client.from('tables').insert({
      'table_number': tableNumber,
      'capacity': capacity,
      'location': location,
      'is_active': isActive,
    });
  }

  Future<void> updateTable({
    required int id,
    required String tableNumber,
    required int capacity,
    required String location,
    required bool isActive,
  }) async {
    await client.from('tables').update({
      'table_number': tableNumber,
      'capacity': capacity,
      'location': location,
      'is_active': isActive,
    }).eq('id', id);
  }

  Future<void> deleteTable(int id) async {
    await client.from('tables').delete().eq('id', id);
  }
}