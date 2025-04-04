import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().initialize();
    });
  }

  Future<void> _refreshData() async {
    await context.read<DataProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final assets = dataProvider.assets;
    final tenants = dataProvider.tenants;
    final transactions = dataProvider.transactions;

    // Calculate statistics
    final occupiedUnits = assets
        .where((asset) => asset.status.toLowerCase() == 'occupied')
        .length;
    final totalUnits = assets.length;
    final occupancyRate = totalUnits > 0
        ? (occupiedUnits / totalUnits * 100).toStringAsFixed(1)
        : '0';

    final upcomingLeaseEnds = tenants
        .where(
          (tenant) =>
              tenant.leaseEnd != null &&
              DateTime.fromMillisecondsSinceEpoch(tenant.leaseEnd!)
                  .isBefore(DateTime.now().add(const Duration(days: 30))),
        )
        .length;

    final totalIncome = transactions
        .where((t) => t.type.toLowerCase() == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpenses = transactions
        .where((t) => t.type.toLowerCase() == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final netIncome = totalIncome - totalExpenses;

    developer.log('Dashboard Statistics:');
    developer.log('Total Income: $totalIncome');
    developer.log('Total Expenses: $totalExpenses');
    developer.log('Net Income: $netIncome');
    developer.log('Total Transactions: ${transactions.length}');

    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: dataProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : dataProvider.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${dataProvider.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(
                          'Properties Overview',
                          [
                            _buildStatRow(
                              'Total Properties',
                              totalUnits.toString(),
                              Icons.home,
                            ),
                            _buildStatRow(
                              'Occupancy Rate',
                              '$occupancyRate%',
                              Icons.percent,
                            ),
                            _buildStatRow(
                              'Occupied Units',
                              occupiedUnits.toString(),
                              Icons.people,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCard(
                          'Financial Summary',
                          [
                            _buildStatRow(
                              'Total Income',
                              currencyFormat.format(totalIncome),
                              Icons.arrow_upward,
                              color: Colors.green,
                            ),
                            _buildStatRow(
                              'Total Expenses',
                              currencyFormat.format(totalExpenses),
                              Icons.arrow_downward,
                              color: Colors.red,
                            ),
                            _buildStatRow(
                              'Net Income',
                              currencyFormat.format(netIncome),
                              Icons.account_balance,
                              color: netIncome >= 0 ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryCard(
                          'Alerts',
                          [
                            _buildStatRow(
                              'Upcoming Lease Ends',
                              upcomingLeaseEnds.toString(),
                              Icons.warning,
                              color: upcomingLeaseEnds > 0
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
