import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/extensions.dart';
import '../../../common/utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/status_badge.dart';

class ReservationDetailScreen extends ConsumerStatefulWidget {
  final int reservationId;

  const ReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  @override
  ConsumerState<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState
    extends ConsumerState<ReservationDetailScreen> {
  Map<String, dynamic>? _reservation;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadReservation();
  }

  Future<void> _loadReservation() async {
    try {
      final service = ref.read(reservationProvider);
      final reservation = await service.getReservationDetail(widget.reservationId);
      
      setState(() {
        _reservation = reservation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Gagal memuat detail reservasi: ${e.toString()}';
      });
    }
  }

  Future<void> _cancelReservation() async {
    if (_reservation == null) return;
    
    final confirm = await showConfirmationDialog(
      context: context,
      title: 'Konfirmasi Pembatalan',
      content: 'Yakin ingin membatalkan reservasi ini?',
      confirmText: 'Batalkan',
    );

    if (confirm) {
      try {
        showLoadingDialog(context);
        final service = ref.read(reservationProvider);
        await service.cancelReservation(widget.reservationId, 'canceled_by_user');
        hideLoadingDialog(context);
        
        if (mounted) {
          showToast(context, 'Reservasi berhasil dibatalkan');
          _loadReservation();
        }
      } catch (e) {
        hideLoadingDialog(context);
        showToast(context, 'Gagal membatalkan reservasi: ${e.toString()}', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Detail Reservasi'),
        body: Center(child: Text(_errorMessage)),
      );
    }

    if (_reservation == null) {
      return const Scaffold(
        body: Center(child: Text('Reservasi tidak ditemukan')),
      );
    }

    final reservation = _reservation!;
    final table = reservation['tables'] as Map<String, dynamic>;
    final user = reservation['users'] as Map<String, dynamic>;
    final date = DateTime.parse('${reservation['reservation_date']}T${reservation['reservation_time']}');

    // Cek apakah waktu reservasi sudah lewat
    final isPast = date.isBefore(DateTime.now());
    // Cek apakah user bisa cancel (status pending/approved dan belum lewat waktu)
    final canCancel = !isPast && 
        (reservation['status'] == 'pending' || reservation['status'] == 'approved');

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Detail Reservasi',
        actions: [
          if (reservation['status'] == 'pending' && ref.read(authProvider).role == 'admin')
            PopupMenuButton<String>(
              onSelected: (value) async {
                try {
                  showLoadingDialog(context);
                  final service = ref.read(reservationProvider);
                  
                  if (value == 'approve') {
                    await service.updateReservationStatus(widget.reservationId, 'approved');
                  } else if (value == 'reject') {
                    await service.updateReservationStatus(widget.reservationId, 'rejected');
                  }
                  
                  hideLoadingDialog(context);
                  
                  if (mounted) {
                    showToast(context, value == 'approve' ? 'Reservasi disetujui' : 'Reservasi ditolak');
                    _loadReservation();
                  }
                } catch (e) {
                  hideLoadingDialog(context);
                  showToast(context, 'Gagal memperbarui reservasi: ${e.toString()}', error: true);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'approve',
                  child: Text('Setujui Reservasi'),
                ),
                const PopupMenuItem(
                  value: 'reject',
                  child: Text('Tolak Reservasi'),
                ),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Reservasi Meja',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Tanggal & Jam',
                      value: date.formattedDateTime(),
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.table_restaurant,
                      label: 'Nomor Meja',
                      value: 'Meja ${table['table_number']}',
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.chair,
                      label: 'Kapasitas',
                      value: '${table['capacity']} orang',
                    ),
                    if (table['location'] != null)
                      _buildInfoRow(
                        context,
                        icon: Icons.location_on,
                        label: 'Lokasi',
                        value: table['location'].toString().capitalize(),
                      ),
                    _buildInfoRow(
                      context,
                      icon: Icons.people,
                      label: 'Jumlah Tamu',
                      value: '${reservation['people_count']} orang',
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.person,
                      label: 'Atas Nama',
                      value: user['name'],
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.phone,
                      label: 'Nomor HP',
                      value: user['phone_number'],
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.access_time,
                      label: 'Waktu Dibuat',
                      value: DateTime.parse(reservation['created_at']).formattedDateTime(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        statusBadge(reservation['status']),
                      ],
                    ),
                    if (reservation['status'].contains('canceled') && reservation['canceled_reason'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Alasan: ${reservation['canceled_reason']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (canCancel)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cancelReservation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Batalkan Reservasi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}