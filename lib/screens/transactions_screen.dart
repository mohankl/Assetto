import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../models/transaction.dart';
import '../models/tenant.dart';
import '../models/asset.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        child: const Icon(Icons.add),
      ),
      body: dataProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dataProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${dataProvider.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => dataProvider.initialize(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => dataProvider.initialize(),
                  child: ListView.builder(
                    itemCount: dataProvider.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = dataProvider.transactions[index];
                      return _buildTransactionCard(context, transaction);
                    },
                  ),
                ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Transaction transaction) {
    final dataProvider = context.read<DataProvider>();
    final asset = dataProvider.assets.firstWhere(
      (asset) => asset.id == transaction.assetId,
      orElse: () => Asset(
        id: '',
        name: 'Unknown Property',
        address: 'No address provided',
        type: 'Unknown',
        status: 'Unknown',
        unitNumber: '',
        rentAmount: 0.0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    final tenant = transaction.tenantId != null
        ? dataProvider.tenants.firstWhere(
            (t) => t.id == transaction.tenantId,
            orElse: () => Tenant.empty(),
          )
        : null;

    final dateFormat = DateFormat('MMM d, y');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(
              currencyFormat.format(transaction.amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: transaction.amount >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status).withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction.status,
                style: TextStyle(
                  color: _getStatusColor(transaction.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.home, size: 16),
                const SizedBox(width: 8),
                Text(asset.name),
              ],
            ),
            if (tenant != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 8),
                  Text(tenant.name),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.description, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(transaction.description)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(dateFormat.format(
                    DateTime.fromMillisecondsSinceEpoch(transaction.date))),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value, transaction),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleMenuAction(
      BuildContext context, String action, Transaction transaction) {
    switch (action) {
      case 'edit':
        _showEditTransactionDialog(context, transaction);
        break;
      case 'delete':
        _showDeleteConfirmationDialog(context, transaction);
        break;
    }
  }

  Future<void> _showAddTransactionDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'advance';
    String selectedStatus = 'pending';

    final dataProvider = context.read<DataProvider>();
    final assets = dataProvider.assets;
    String selectedAssetId = assets.first.id;
    String? selectedTenantId;

    // Get tenants for the selected asset
    final tenants = dataProvider.tenants
        .where((tenant) => tenant.assetId == selectedAssetId)
        .toList();

    // Create tenant dropdown items
    final List<DropdownMenuItem<String?>> tenantItems = [
      const DropdownMenuItem(
        value: null,
        child: Text('No tenant'),
      ),
      ...tenants.map(
        (tenant) => DropdownMenuItem<String?>(
          value: tenant.id,
          child: Text(tenant.name),
        ),
      ),
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Amount is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedAssetId,
                    decoration: const InputDecoration(labelText: 'Property'),
                    items: assets
                        .map((asset) => DropdownMenuItem(
                              value: asset.id,
                              child: Text(
                                  '${asset.name} - Unit ${asset.unitNumber}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedAssetId = value;
                          // Reset tenant selection when asset changes
                          selectedTenantId = null;
                          // Update tenant items list
                          final updatedTenants = dataProvider.tenants
                              .where((tenant) => tenant.assetId == value)
                              .toList();
                          tenantItems.clear();
                          tenantItems.add(
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No tenant'),
                            ),
                          );
                          tenantItems.addAll(
                            updatedTenants.map(
                              (tenant) => DropdownMenuItem<String?>(
                                value: tenant.id,
                                child: Text(tenant.name),
                              ),
                            ),
                          );
                        });
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Property is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: selectedTenantId,
                    decoration: const InputDecoration(labelText: 'Tenant'),
                    items: tenantItems,
                    onChanged: (value) {
                      selectedTenantId = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'advance',
                        child: Text('Advance'),
                      ),
                      DropdownMenuItem(
                        value: 'expense',
                        child: Text('Expense'),
                      ),
                      DropdownMenuItem(
                        value: 'rent',
                        child: Text('Rent'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        selectedType = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ['pending', 'completed', 'cancelled']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedStatus = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('MMM d, y').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final transactionData = {
                    'amount': double.parse(amountController.text),
                    'asset_id': selectedAssetId,
                    'tenant_id': selectedTenantId,
                    'type': selectedType,
                    'status': selectedStatus,
                    'description': descriptionController.text,
                    'date': selectedDate.millisecondsSinceEpoch,
                  };
                  dataProvider.addTransaction(transactionData);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditTransactionDialog(
      BuildContext context, Transaction transaction) async {
    final formKey = GlobalKey<FormState>();
    final amountController =
        TextEditingController(text: transaction.amount.toString());
    final descriptionController =
        TextEditingController(text: transaction.description);
    DateTime selectedDate =
        DateTime.fromMillisecondsSinceEpoch(transaction.date);
    String selectedType = transaction.type;
    String selectedStatus = transaction.status;

    final dataProvider = context.read<DataProvider>();
    final assets = dataProvider.assets;
    String selectedAssetId = transaction.assetId;
    String? selectedTenantId = transaction.tenantId;

    // Ensure we have at least one asset
    if (assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assets available. Please add an asset first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get tenants for the selected asset
    final tenants = dataProvider.tenants
        .where((tenant) => tenant.assetId == selectedAssetId)
        .toList();

    // Create tenant dropdown items
    final List<DropdownMenuItem<String?>> tenantItems = [
      const DropdownMenuItem(
        value: null,
        child: Text('No tenant'),
      ),
      ...tenants.map(
        (tenant) => DropdownMenuItem<String?>(
          value: tenant.id,
          child: Text(tenant.name),
        ),
      ),
    ];

    // If the current tenant is not in the list, add it
    if (selectedTenantId != null &&
        !tenants.any((t) => t.id == selectedTenantId)) {
      final currentTenant = dataProvider.tenants.firstWhere(
          (t) => t.id == selectedTenantId,
          orElse: () => Tenant.empty());
      if (currentTenant.id.isNotEmpty) {
        tenantItems.add(
          DropdownMenuItem<String?>(
            value: currentTenant.id,
            child: Text(currentTenant.name),
          ),
        );
      }
    }

    // If no tenants are available for the selected asset, reset tenant selection
    if (tenants.isEmpty && selectedTenantId != null) {
      selectedTenantId = null;
    }

    try {
      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Edit Transaction'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Amount is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedAssetId,
                      decoration: const InputDecoration(labelText: 'Property'),
                      items: assets
                          .map((asset) => DropdownMenuItem(
                                value: asset.id,
                                child: Text(
                                    '${asset.name} - Unit ${asset.unitNumber}'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedAssetId = value;
                            selectedTenantId = null;
                            final updatedTenants = dataProvider.tenants
                                .where((tenant) => tenant.assetId == value)
                                .toList();
                            tenantItems.clear();
                            tenantItems.add(
                              const DropdownMenuItem(
                                value: null,
                                child: Text('No tenant'),
                              ),
                            );
                            tenantItems.addAll(
                              updatedTenants.map(
                                (tenant) => DropdownMenuItem<String?>(
                                  value: tenant.id,
                                  child: Text(tenant.name),
                                ),
                              ),
                            );
                          });
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Property is required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: selectedTenantId,
                      decoration: const InputDecoration(labelText: 'Tenant'),
                      items: tenantItems,
                      onChanged: (value) {
                        setState(() {
                          selectedTenantId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'advance',
                          child: Text('Advance'),
                        ),
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Expense'),
                        ),
                        DropdownMenuItem(
                          value: 'rent',
                          child: Text('Rent'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['pending', 'completed', 'cancelled']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          selectedStatus = value;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Date'),
                      subtitle:
                          Text(DateFormat('MMM d, y').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    try {
                      final transactionData = {
                        'asset_id': selectedAssetId,
                        'tenant_id': selectedTenantId,
                        'amount': double.parse(amountController.text),
                        'type': selectedType,
                        'status': selectedStatus,
                        'description': descriptionController.text,
                        'date': selectedDate.millisecondsSinceEpoch,
                      };
                      await dataProvider.updateTransaction(
                          transaction.id, transactionData);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaction updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating transaction: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, Transaction transaction) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text(
              'Are you sure you want to delete this ${transaction.type} transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (result == true && context.mounted) {
        try {
          await context.read<DataProvider>().deleteTransaction(transaction.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting transaction: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
