import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/constants.dart';
import '../../../common/extensions.dart';
import '../../../common/utils.dart';
import '../../../common/app_theme.dart';
// PERBAIKAN: Import yang benar
import '../../auth/controllers/auth_controller.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/table_card.dart';

class CreateReservationScreen extends ConsumerStatefulWidget {
  const CreateReservationScreen({super.key});

  @override
  ConsumerState<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState
    extends ConsumerState<CreateReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now().replacing(hour: 18, minute: 0);
  int _peopleCount = 2;
  List<Map<String, dynamic>> _availableTables = [];
  int? _selectedTableId;

  Future<void> _findAvailableTables() async {
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    if (authState.user == null) {
      showToast(context, 'Anda harus login terlebih dahulu', error: true);
      context.pop();
      return;
    }

    try {
      // Validasi tanggal dan waktu tidak di masa lalu
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      if (selectedDateTime.isBefore(now.add(const Duration(hours: 1)))) {
        showToast(context, 'Reservasi minimal 1 jam sebelum waktu reservasi', error: true);
        return;
      }

      showLoadingDialog(context);
      final service = ref.read(reservationProvider);
      final tables = await service.getAvailableTables(
        peopleCount: _peopleCount,
        reservationDate: _selectedDate,
        reservationTime: _selectedTime,
      );

      hideLoadingDialog(context);

      setState(() {
        _availableTables = tables;
        _selectedTableId = tables.isNotEmpty ? tables.first['id'] : null;
      });

      if (tables.isEmpty) {
        showToast(context, 'Tidak ada meja yang tersedia untuk jumlah orang ini', error: true);
      }
    } catch (e) {
      hideLoadingDialog(context);
      showToast(context, 'Error: ${e.toString()}', error: true);
    }
  }

  Future<void> _submitReservation() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    if (_selectedTableId == null) {
      showToast(context, 'Silakan pilih meja terlebih dahulu', error: true);
      return;
    }

    try {
      showLoadingDialog(context);
      final service = ref.read(reservationProvider);
      
      await service.createReservation(
        userId: authState.user!.id,
        tableId: _selectedTableId!,
        reservationDate: _selectedDate,
        reservationTime: _selectedTime,
        peopleCount: _peopleCount,
      );

      hideLoadingDialog(context);
      
      if (!mounted) return;
      
      showToast(context, 'Reservasi berhasil dibuat! Menunggu konfirmasi admin');
      context.pop();
    } catch (e) {
      hideLoadingDialog(context);
      showToast(context, 'Gagal membuat reservasi: ${e.toString()}', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Reservasi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateTimePicker(),
                const SizedBox(height: 24),
                _buildPeopleCount(),
                const SizedBox(height: 24),
                _buildTableSelection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tanggal & Jam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _selectedDate.formattedDate(),
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: AppConstants.maxReservationDays)),
                    );
                    if (selected != null) {
                      setState(() {
                        _selectedDate = selected;
                        _availableTables = [];
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: InputBorder.none,
                  ),
                ),
                const Divider(height: 24),
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _selectedTime.formatTime(context),
                  ),
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (selected != null) {
                      setState(() {
                        _selectedTime = selected;
                        _availableTables = [];
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Jam',
                    prefixIcon: Icon(Icons.access_time),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleCount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jumlah Orang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  '$_peopleCount orang',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 32),
                      onPressed: () {
                        if (_peopleCount > 1) {
                          setState(() {
                            _peopleCount--;
                            _availableTables = [];
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 32),
                      onPressed: () {
                        setState(() {
                          _peopleCount++;
                          _availableTables = [];
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_availableTables.isEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _findAvailableTables,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cari Meja Tersedia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableSelection() {
    if (_availableTables.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Meja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _availableTables.length > 3
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableTables.length,
                  itemBuilder: (context, index) {
                    final table = _availableTables[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: TableCard(
                        table: table,
                        isSelected: _selectedTableId == table['id'],
                        onTap: () {
                          setState(() {
                            _selectedTableId = table['id'];
                          });
                        },
                      ),
                    );
                  },
                )
              : Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _availableTables.map((table) {
                    return TableCard(
                      table: table,
                      isSelected: _selectedTableId == table['id'],
                      onTap: () {
                        setState(() {
                          _selectedTableId = table['id'];
                        });
                      },
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _availableTables.isEmpty || _selectedTableId == null
            ? null
            : LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _availableTables.isEmpty || _selectedTableId == null
            ? null
            : [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _availableTables.isEmpty || _selectedTableId == null
            ? null
            : _submitReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: _availableTables.isEmpty || _selectedTableId == null
              ? Colors.grey[300]
              : Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Konfirmasi Reservasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}