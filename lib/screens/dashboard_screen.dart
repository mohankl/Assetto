import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/tenant.dart';
import '../models/transaction.dart';
import '../providers/firebase_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.watch<FirebaseProvider>().firebaseService;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Asset>>(
              stream: firebaseService.getAssets(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final assets = snapshot.data ?? [];
                final totalAssets = assets.length;
                final availableAssets =
                    assets.where((a) => a.status == 'available').length;
                final rentedAssets =
                    assets.where((a) => a.status == 'rented').length;
                final maintenanceAssets =
                    assets.where((a) => a.status == 'maintenance').length;

                return _buildStatCard(
                  'Assets',
                  [
                    _buildStatItem('Total', totalAssets.toString()),
                    _buildStatItem('Available', availableAssets.toString()),
                    _buildStatItem('Rented', rentedAssets.toString()),
                    _buildStatItem('Maintenance', maintenanceAssets.toString()),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Tenant>>(
              stream: firebaseService.getTenants(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final tenants = snapshot.data ?? [];
                final activeTenants =
                    tenants.where((t) => t.status == 'active').length;
                final pastTenants =
                    tenants.where((t) => t.status == 'past').length;
                final pendingTenants =
                    tenants.where((t) => t.status == 'pending').length;

                return _buildStatCard(
                  'Tenants',
                  [
                    _buildStatItem('Total', tenants.length.toString()),
                    _buildStatItem('Active', activeTenants.toString()),
                    _buildStatItem('Past', pastTenants.toString()),
                    _buildStatItem('Pending', pendingTenants.toString()),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Transaction>>(
              stream: firebaseService.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final transactions = snapshot.data ?? [];
                final totalTransactions = transactions.length;
                final completedTransactions =
                    transactions.where((t) => t.status == 'completed').length;
                final pendingTransactions =
                    transactions.where((t) => t.status == 'pending').length;
                final failedTransactions =
                    transactions.where((t) => t.status == 'failed').length;

                return _buildStatCard(
                  'Transactions',
                  [
                    _buildStatItem('Total', totalTransactions.toString()),
                    _buildStatItem(
                        'Completed', completedTransactions.toString()),
                    _buildStatItem('Pending', pendingTransactions.toString()),
                    _buildStatItem('Failed', failedTransactions.toString()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, List<Widget> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: stats,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
