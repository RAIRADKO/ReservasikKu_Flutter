import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/constants.dart';
import '../../../common/extensions.dart';
import '../../../common/utils.dart';
import '../../../common/app_theme.dart';
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
    extends ConsumerState<CreateReservationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now().replacing(hour: 18, minute: 0);
  int _peopleCount = 2;
  int _requiredCapacity = 2;
  List<Map<String, dynamic>> _availableTables = [];
  int? _selectedTableId;
  bool _isSearching = false;
  bool _hasCheckedTables = false;
  bool _showTableList = false;
  String? _tableCheckMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _requiredCapacity = _calculateRequiredCapacity(_peopleCount);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Calculate required capacity based on people count
  int _calculateRequiredCapacity(int peopleCount) {
    // If even number → capacity is the same
    // If odd number → round up (1 → 2, 3 → 4, 5 → 6, etc.)
    if (peopleCount.isOdd) {
      return peopleCount + 1;
    }
    return peopleCount;
  }

  // Check available tables automatically when people count changes
  Future<void> _checkAvailableTables() async {
    if (!mounted) return;

    // Calculate required capacity
    final capacity = _calculateRequiredCapacity(_peopleCount);
    setState(() {
      _requiredCapacity = capacity;
      _hasCheckedTables = false;
      _availableTables = [];
      _selectedTableId = null;
      _showTableList = false;
      _tableCheckMessage = null;
    });

    // Check if date and time are set
    if (_selectedDate == null || _selectedTime == null) {
      return;
    }

    try {
      final service = ref.read(reservationProvider);
      final tables = await service.getAvailableTables(
        peopleCount: _peopleCount,
        reservationDate: _selectedDate,
        reservationTime: _selectedTime,
      );

      if (!mounted) return;

      setState(() {
        _hasCheckedTables = true;
        _availableTables = tables;
        if (tables.isEmpty) {
          _tableCheckMessage = 'Tidak ada meja yang sesuai untuk jumlah orang ini.';
        } else {
          _tableCheckMessage = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasCheckedTables = true;
        _tableCheckMessage = 'Error: ${e.toString()}';
      });
    }
  }

  // Show table selection dialog or navigate to table list
  void _showTableSelection() {
    if (_availableTables.isEmpty) {
      showToast(context, 'Tidak ada meja yang sesuai untuk jumlah orang ini.', error: true);
      return;
    }

    // Show the table list
    setState(() {
      _showTableList = true;
    });
    
    // Show message that tables are available
    showToast(context, '${_availableTables.length} meja tersedia! Pilih meja di bawah.');
  }

  Future<void> _findAvailableTables() async {
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    if (authState.user == null) {
      showToast(context, 'Anda harus login terlebih dahulu', error: true);
      context.pop();
      return;
    }

    try {
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

      setState(() => _isSearching = true);
      
      final service = ref.read(reservationProvider);
      final tables = await service.getAvailableTables(
        peopleCount: _peopleCount,
        reservationDate: _selectedDate,
        reservationTime: _selectedTime,
      );

      setState(() {
        _availableTables = tables;
        _selectedTableId = tables.isNotEmpty ? tables.first['id'] : null;
        _isSearching = false;
        _hasCheckedTables = true;
        if (tables.isEmpty) {
          _tableCheckMessage = 'Tidak ada meja yang sesuai untuk jumlah orang ini.';
        } else {
          _tableCheckMessage = null;
        }
      });

      if (tables.isEmpty) {
        showToast(context, 'Tidak ada meja yang sesuai untuk jumlah orang ini.', error: true);
      } else {
        showToast(context, '${tables.length} meja tersedia!');
      }
    } catch (e) {
      setState(() => _isSearching = false);
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
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildDateTimeSection(),
                    const SizedBox(height: 24),
                    _buildPeopleCountSection(),
                    const SizedBox(height: 24),
                    if (_showTableList && _availableTables.isNotEmpty && _hasCheckedTables) ...[
                      _buildTableSelectionSection(),
                      const SizedBox(height: 24),
                    ],
                    _buildSubmitButton(),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        title: const Text(
          'Buat Reservasi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.lightBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesan Meja Favorit',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih tanggal, waktu, dan meja yang sesuai',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tanggal & Waktu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: AppConstants.maxReservationDays),
                      ),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppTheme.primaryBlue,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (selected != null) {
                      setState(() {
                        _selectedDate = selected;
                        _availableTables = [];
                        _hasCheckedTables = false;
                        _showTableList = false;
                        _tableCheckMessage = null;
                      });
                      // Re-check tables after date change
                      _checkAvailableTables();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal Reservasi',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedDate.formattedDate(),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.primaryBlue,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final selected = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppTheme.primaryBlue,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (selected != null) {
                      setState(() {
                        _selectedTime = selected;
                        _availableTables = [];
                        _hasCheckedTables = false;
                        _showTableList = false;
                        _tableCheckMessage = null;
                      });
                      // Re-check tables after time change
                      _checkAvailableTables();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waktu Reservasi',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedTime.formatTime(context),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.primaryBlue,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPeopleCountSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Jumlah Tamu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCounterButton(
                    icon: Icons.remove,
                    onPressed: _peopleCount > 1
                        ? () {
                            setState(() {
                              _peopleCount--;
                            });
                            _checkAvailableTables();
                          }
                        : null,
                  ),
                  const SizedBox(width: 32),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          '$_peopleCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'orang',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  _buildCounterButton(
                    icon: Icons.add,
                    onPressed: () {
                      setState(() {
                        _peopleCount++;
                      });
                      _checkAvailableTables();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Show capacity info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kapasitas meja yang dibutuhkan: $_requiredCapacity orang',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Show message if no tables found
          if (_hasCheckedTables && _tableCheckMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _tableCheckMessage!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Show "Pilih Meja" button when tables are available
          if (_hasCheckedTables && _availableTables.isNotEmpty)
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSearching ? null : _showTableSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSearching
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.table_restaurant, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Pilih Meja',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? AppTheme.primaryBlue : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableSelectionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.table_restaurant,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pilih Meja',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  '${_availableTables.length} tersedia',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availableTables.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final table = _availableTables[index];
                return TableCard(
                  table: table,
                  isSelected: _selectedTableId == table['id'],
                  onTap: () {
                    setState(() {
                      _selectedTableId = table['id'];
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _availableTables.isNotEmpty && _selectedTableId != null;
    
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: canSubmit ? AppTheme.primaryGradient : null,
        color: canSubmit ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
        boxShadow: canSubmit
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: canSubmit ? _submitReservation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: canSubmit ? Colors.white : Colors.grey[500],
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Konfirmasi Reservasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: canSubmit ? Colors.white : Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}