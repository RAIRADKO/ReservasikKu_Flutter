import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/extensions.dart';
import '../../../common/app_theme.dart';
// PERBAIKAN: Import yang benar
import '../../auth/controllers/auth_controller.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/status_badge.dart';

class ReservationHistoryScreen extends ConsumerStatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  ConsumerState<ReservationHistoryScreen> createState() =>
      _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState
    extends ConsumerState<ReservationHistoryScreen> {
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'User tidak ditemukan';
      });
      return;
    }

    try {
      final service = ref.read(reservationProvider);
      final reservations = await service.getUserReservations(authState.user!.id);
      
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Gagal memuat riwayat reservasi: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Riwayat Reservasi'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text(_errorMessage))
              : _reservations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history,
                              size: 64,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Belum ada reservasi',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Buat reservasi pertama Anda sekarang!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _reservations.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final reservation = _reservations[index];
                        final table = reservation['tables'] as Map<String, dynamic>;
                        
                        // Format tanggal dan waktu
                        final date = DateTime.parse('${reservation['reservation_date']}T${reservation['reservation_time']}');
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () => context.push('/reservations/${reservation['id']}'),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Meja ${table['table_number']}',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                        ),
                                        statusBadge(reservation['status']),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: AppTheme.primaryBlue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          date.formattedDateTime(),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          size: 18,
                                          color: AppTheme.primaryBlue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${reservation['people_count']} orang',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-reservation'),
        child: const Icon(Icons.add),
      ),
    );
  }
}