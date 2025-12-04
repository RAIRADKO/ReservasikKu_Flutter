import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/client.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClientManager.client;
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
    // Hitung kapasitas yang dibutuhkan (jika ganjil, tambah 1)
    int requiredCapacity = peopleCount;
    if (peopleCount.isOdd && peopleCount >= 3) {
      requiredCapacity = peopleCount + 1;
    }

    // Cari meja yang aktif dengan kapasitas memadai
    final { tables, error: tablesError} = await client
        .from('tables')
        .select()
        .gte('capacity', requiredCapacity)
        .eq('is_active', true)
        .order('capacity', ascending: true);

    if (tablesError != null) throw Exception(tablesError.message);
    if (tables == null || tables.isEmpty) return [];

    final tableIds = (tables as List).map((t) => t['id']).toList();

    // Format waktu dan tanggal
    final formattedTime = '${reservationTime.hour.toString().padLeft(2, '0')}:'
        '${reservationTime.minute.toString().padLeft(2, '0')}:00';
    final formattedDate = reservationDate.toIso8601String().split('T')[0];

    // Cek meja yang sudah dipesan pada waktu yang sama
    final { reservations, error: reservationsError} = await client
        .from('reservations')
        .select('table_id')
        .in_('table_id', tableIds)
        .eq('reservation_date', formattedDate)
        .eq('reservation_time', formattedTime)
        .not('status', 'in', ['canceled_by_user', 'canceled_by_admin', 'rejected']);

    if (reservationsError != null) throw Exception(reservationsError.message);

    final reservedTableIds = (reservations as List?)
        ?.map((r) => r['table_id'])
        .toSet() ?? {};

    // Filter meja yang tersedia
    return (tables as List)
        .where((table) => !reservedTableIds.contains(table['id']))
        .toList();
  }

  Future<void> createReservation({
    required String userId,
    required int tableId,
    required DateTime reservationDate,
    required TimeOfDay reservationTime,
    required int peopleCount,
  }) async {
    // Validasi tanggal tidak di masa lalu
    final now = DateTime.now();
    if (reservationDate.isBefore(now) ||
        (reservationDate == now && reservationTime.isBefore(TimeOfDay.now()))) {
      throw Exception('Tidak bisa memesan untuk waktu yang sudah lewat');
    }

    final formattedTime = '${reservationTime.hour.toString().padLeft(2, '0')}:'
        '${reservationTime.minute.toString().padLeft(2, '0')}:00';
    final formattedDate = reservationDate.toIso8601String().split('T')[0];

    final {error} = await client.from('reservations').insert({
      'user_id': userId,
      'table_id': tableId,
      'reservation_date': formattedDate,
      'reservation_time': formattedTime,
      'people_count': peopleCount,
      'status': 'pending',
    });

    if (error != null) throw Exception(error.message);
  }

  Future<List<Map<String, dynamic>>> getUserReservations(String userId) async {
    final {data, error} = await client
        .from('reservations')
        .select('*, tables(table_number, capacity)')
        .eq('user_id', userId)
        .order('reservation_date', ascending: false)
        .order('reservation_time', ascending: false);

    if (error != null) throw Exception(error.message);
    return data as List<Map<String, dynamic>>;
  }

  Future<Map<String, dynamic>> getReservationDetail(int reservationId) async {
    final {data, error} = await client
        .from('reservations')
        .select('*, tables(*), users(name, phone_number)')
        .eq('id', reservationId)
        .single();

    if (error != null) throw Exception(error.message);
    return data as Map<String, dynamic>;
  }

  Future<void> cancelReservation(int reservationId, String cancelType) async {
    final {error} = await client
        .from('reservations')
        .update({'status': cancelType})
        .eq('id', reservationId);

    if (error != null) throw Exception(error.message);
  }

  Future<List<Map<String, dynamic>>> getPendingReservations() async {
    final {data, error} = await client
        .from('reservations')
        .select('*, tables(table_number, capacity), users(name, phone_number)')
        .eq('status', 'pending')
        .order('reservation_date')
        .order('reservation_time');

    if (error != null) throw Exception(error.message);
    return data as List<Map<String, dynamic>>;
  }

  Future<List<Map<String, dynamic>>> getAllReservations({
    String? status,
    DateTime? date,
  }) async {
    var query = client
        .from('reservations')
        .select('*, tables(table_number, capacity), users(name, phone_number)')
        .order('reservation_date', ascending: false)
        .order('reservation_time', ascending: false);

    if (status != null) {
      query = query.eq('status', status);
    }

    if (date != null) {
      final formattedDate = date.toIso8601String().split('T')[0];
      query = query.eq('reservation_date', formattedDate);
    }

    final {data, error} = await query;

    if (error != null) throw Exception(error.message);
    return data as List<Map<String, dynamic>>;
  }

  Future<void> updateReservationStatus(int reservationId, String status) async {
    final {error} = await client
        .from('reservations')
        .update({'status': status})
        .eq('id', reservationId);

    if (error != null) throw Exception(error.message);
  }
}

class TableService {
  final SupabaseClient client;

  TableService(this.client);

  Future<List<Map<String, dynamic>>> getAllTables() async {
    final {data, error} = await client
        .from('tables')
        .select()
        .order('table_number');

    if (error != null) throw Exception(error.message);
    return data as List<Map<String, dynamic>>;
  }

  Future<void> createTable({
    required String tableNumber,
    required int capacity,
    required String location,
    required bool isActive,
  }) async {
    final {error} = await client.from('tables').insert({
      'table_number': tableNumber,
      'capacity': capacity,
      'location': location,
      'is_active': isActive,
    });

    if (error != null) throw Exception(error.message);
  }

  Future<void> updateTable({
    required int id,
    required String tableNumber,
    required int capacity,
    required String location,
    required bool isActive,
  }) async {
    final {error} = await client.from('tables').update({
      'table_number': tableNumber,
      'capacity': capacity,
      'location': location,
      'is_active': isActive,
    }).eq('id', id);

    if (error != null) throw Exception(error.message);
  }

  Future<void> deleteTable(int id) async {
    final {error} = await client.from('tables').delete().eq('id', id);

    if (error != null) throw Exception(error.message);
  }
}