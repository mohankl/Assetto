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
                color: _getStatusColor(transaction.status).withOpacity(0.1),
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
    String selectedType = 'rent';
    String selectedStatus = 'pending';

    final dataProvider = context.read<DataProvider>();
    final assets = dataProvider.assets;
    String selectedAssetId = assets.first.id;
    String? selectedTenantId;

    final tenants = dataProvider.tenants
        .where((tenant) => tenant.assetId == selectedAssetId)
        .toList();

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
                              child: Text(asset.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedAssetId = value;
                          selectedTenantId = null;
                        });
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Property is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedTenantId,
                    decoration: const InputDecoration(labelText: 'Tenant'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No tenant'),
                      ),
                      ...tenants.map(
                        (tenant) => DropdownMenuItem(
                          value: tenant.id,
                          child: Text(tenant.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      selectedTenantId = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ['rent', 'deposit', 'maintenance', 'other']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
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

    final tenants = dataProvider.tenants
        .where((tenant) => tenant.assetId == selectedAssetId)
        .toList();

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
                              child: Text(asset.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedAssetId = value;
                          selectedTenantId = null;
                        });
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Property is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedTenantId,
                    decoration: const InputDecoration(labelText: 'Tenant'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No tenant'),
                      ),
                      ...tenants.map(
                        (tenant) => DropdownMenuItem(
                          value: tenant.id,
                          child: Text(tenant.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      selectedTenantId = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ['rent', 'deposit', 'maintenance', 'other']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
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
                    'asset_id': selectedAssetId,
                    'tenant_id': selectedTenantId,
                    'amount': double.parse(amountController.text),
                    'type': selectedType,
                    'status': selectedStatus,
                    'description': descriptionController.text,
                    'date': selectedDate.millisecondsSinceEpoch,
                  };
                  dataProvider.updateTransaction(
                      transaction.id, transactionData);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, Transaction transaction) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
            'Are you sure you want to delete this ${transaction.type} transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DataProvider>().deleteTransaction(transaction.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
