import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../../../widgets/custom_app_bar.dart';

class ManageTablesScreen extends ConsumerStatefulWidget {
  const ManageTablesScreen({super.key});

@override
ConsumerState<ManageTablesScreen> createState() =>
    _ManageTablesScreenState();
}

class _ManageTablesScreenState extends ConsumerState<ManageTablesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tableNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController(text: 'indoor');
  bool _isActive = true;
  int? _editingTableId;

  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      final service = ref.read(tableProvider);
      final tables = await service.getAllTables();
      
      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tables: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final service = ref.read(tableProvider);
      final tableData = {
        'table_number': _tableNumberController.text.trim(),
        'capacity': int.parse(_capacityController.text.trim()),
        'location': _locationController.text.trim(),
        'is_active': _isActive,
      };

      if (_editingTableId != null) {
        // Update existing table
        await service.updateTable(
          id: _editingTableId!,
          tableNumber: tableData['table_number'] as String,
          capacity: tableData['capacity'] as int,
          location: tableData['location'] as String,
          isActive: tableData['is_active'] as bool,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meja berhasil diperbarui')),
        );
      } else {
        // Insert new table
        await service.createTable(
          tableNumber: tableData['table_number'] as String,
          capacity: tableData['capacity'] as int,
          location: tableData['location'] as String,
          isActive: tableData['is_active'] as bool,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meja berhasil ditambahkan')),
        );
      }

      _clearForm();
      await _loadTables();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving table: ${e.toString()}')),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _editingTableId = null;
      _tableNumberController.clear();
      _capacityController.clear();
      _locationController.text = 'indoor';
      _isActive = true;
    });
  }

  void _editTable(Map<String, dynamic> table) {
    setState(() {
      _editingTableId = table['id'];
      _tableNumberController.text = table['table_number'].toString();
      _capacityController.text = table['capacity'].toString();
      _locationController.text = table['location'] ?? 'indoor';
      _isActive = table['is_active'] ?? true;
    });
  }

  Future<void> _deleteTable(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus meja ini?'),
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(tableProvider);
        await service.deleteTable(id);
        await _loadTables();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meja berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting table: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Manajemen Meja'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildForm(),
                const SizedBox(height: 16),
                Expanded(
                  child: _tables.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada meja',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tambahkan meja baru untuk memulai',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tables.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final table = _tables[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                              ),
                                        ),
                                        Switch(
                                          value: table['is_active'] ?? false,
                                          onChanged: (value) async {
                                            try {
                                              final service = ref.read(tableProvider);
                                              await service.updateTable(
                                                id: table['id'],
                                                tableNumber: table['table_number'].toString(),
                                                capacity: table['capacity'],
                                                location: table['location'] ?? 'indoor',
                                                isActive: value,
                                              );
                                              await _loadTables();
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Gagal mengubah status: ${e.toString()}')),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${table['capacity']} orang',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      (table['location'] as String?)?.capitalize() ?? '',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _editTable(table),
                                          child: const Text('Edit'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () => _deleteTable(table['id']),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _tableNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Meja',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Kapasitas (orang)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.trim().isEmpty) return 'Wajib diisi';
                    if (int.tryParse(v.trim()) == null) return 'Masukkan angka valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _locationController.text,
                  items: const [
                    DropdownMenuItem(value: 'indoor', child: Text('Indoor')),
                    DropdownMenuItem(value: 'outdoor', child: Text('Outdoor')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _locationController.text = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Lokasi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Status Aktif'),
                  subtitle: const Text('Meja dapat digunakan untuk reservasi'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveTable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _editingTableId != null ? 'Update Meja' : 'Tambah Meja',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_editingTableId != null)
                  TextButton(
                    onPressed: _clearForm,
                    child: const Text('Batal Edit'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}