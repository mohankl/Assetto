import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tenant.dart';
import '../providers/firebase_provider.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  DateTime _leaseStartDate = DateTime.now();
  DateTime _leaseEndDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _monthlyRentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _leaseStartDate : _leaseEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null &&
        picked != (isStartDate ? _leaseStartDate : _leaseEndDate)) {
      setState(() {
        if (isStartDate) {
          _leaseStartDate = picked;
        } else {
          _leaseEndDate = picked;
        }
      });
    }
  }

  Future<void> _addTenant(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final firebaseService = context.read<FirebaseProvider>().firebaseService;
      final tenant = Tenant(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        monthlyRent: double.parse(_monthlyRentController.text),
        leaseStartDate: _leaseStartDate,
        leaseEndDate: _leaseEndDate,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await firebaseService.createTenant(tenant);
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _monthlyRentController.clear();
        setState(() {
          _leaseStartDate = DateTime.now();
          _leaseEndDate = DateTime.now().add(const Duration(days: 365));
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding tenant: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.watch<FirebaseProvider>().firebaseService;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenants'),
      ),
      body: StreamBuilder<List<Tenant>>(
        stream: firebaseService.getTenants(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tenants = snapshot.data ?? [];

          return ListView.builder(
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              return ListTile(
                title: Text(tenant.name),
                subtitle: Text(tenant.email),
                trailing: Text('\$${tenant.monthlyRent.toStringAsFixed(2)}'),
                onTap: () {
                  // TODO: Navigate to tenant details screen
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add New Tenant'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _monthlyRentController,
                      decoration:
                          const InputDecoration(labelText: 'Monthly Rent'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a monthly rent amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    ListTile(
                      title: const Text('Lease Start Date'),
                      subtitle: Text(_leaseStartDate.toString().split(' ')[0]),
                      onTap: () => _selectDate(context, true),
                    ),
                    ListTile(
                      title: const Text('Lease End Date'),
                      subtitle: Text(_leaseEndDate.toString().split(' ')[0]),
                      onTap: () => _selectDate(context, false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addTenant(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
