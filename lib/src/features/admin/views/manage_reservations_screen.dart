import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/extensions.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/status_badge.dart';

class ManageReservationsScreen extends ConsumerStatefulWidget {
  const ManageReservationsScreen({super.key});

  @override
  ConsumerState<ManageReservationsScreen> createState() =>
      _ManageReservationsScreenState();
}

class _ManageReservationsScreenState
    extends ConsumerState<ManageReservationsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;
  String _activeTab = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReservations('pending');
    
    _tabController.addListener(() {
      final tab = _tabController.index == 0 ? 'pending' : 'all';
      if (_activeTab != tab) {
        setState(() {
          _activeTab = tab;
        });
        _loadReservations(tab);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations(String tab) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(reservationProvider);
      List<Map<String, dynamic>> reservations;
      
      if (tab == 'pending') {
        reservations = await service.getPendingReservations();
      } else {
        reservations = await service.getAllReservations();
      }
      
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reservations: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateReservationStatus(int reservationId, String status) async {
    try {
      final service = ref.read(reservationProvider);
      await service.updateReservationStatus(reservationId, status);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved' 
              ? 'Reservasi disetujui' 
              : 'Reservasi ditolak'),
        ),
      );
      
      _loadReservations(_activeTab);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating reservation: ${e.toString()}')),
      );
    }
  }

  Future<void> _cancelReservation(int reservationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembatalan'),
        content: const Text('Yakin ingin membatalkan reservasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(reservationProvider);
        await service.updateReservationStatus(reservationId, 'canceled_by_admin');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservasi berhasil dibatalkan')),
        );
        
        _loadReservations(_activeTab);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error canceling reservation: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Kelola Reservasi',
        actions: [
          if (_activeTab == 'all')
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // TODO: Implement filter dialog
              },
            ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Menunggu'),
              Tab(text: 'Semua'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reservations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _activeTab == 'pending' 
                                  ? Icons.hourglass_empty 
                                  : Icons.list_alt,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _activeTab == 'pending'
                                  ? 'Tidak ada reservasi menunggu'
                                  : 'Tidak ada reservasi',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
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
                          final user = reservation['users'] as Map<String, dynamic>;
                          
                          // Format tanggal dan waktu
                          final date = DateTime.parse(
                            '${reservation['reservation_date']}T${reservation['reservation_time']}'
                          );
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                          user['name'],
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        statusBadge(reservation['status']),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          date.formattedDateTime(),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.people, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${reservation['people_count']} orang di Meja ${table['table_number']}',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (_activeTab == 'pending' && reservation['status'] == 'pending')
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () => _updateReservationStatus(reservation['id'], 'rejected'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Tolak'),
                                          ),
                                          const SizedBox(width: 8),
                                          FilledButton(
                                            onPressed: () => _updateReservationStatus(reservation['id'], 'approved'),
                                            child: const Text('Setujui'),
                                          ),
                                        ],
                                      ),
                                    if (_activeTab == 'all' && reservation['status'] != 'canceled_by_admin')
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () => _cancelReservation(reservation['id']),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Batalkan'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}