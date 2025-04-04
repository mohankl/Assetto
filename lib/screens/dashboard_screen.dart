import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../models/tenant.dart';
import '../models/asset.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<DateTime> _months = [];

  @override
  void initState() {
    super.initState();
    // Initialize data when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().initialize();
    });

    // Initialize the past 3 months
    final now = DateTime.now();
    for (int i = 0; i < 3; i++) {
      _months.add(DateTime(now.year, now.month - i, 1));
    }

    // Initialize tab controller
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await context.read<DataProvider>().initialize();
  }

  // Get statistics for a specific month
  Map<String, dynamic> _getMonthlyStatistics(DateTime month) {
    final dataProvider = context.read<DataProvider>();
    final assets = dataProvider.assets;
    final tenants = dataProvider.tenants;
    final transactions = dataProvider.transactions;

    // Calculate statistics for the specific month
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

    // Find unpaid tenants for the specific month
    final unpaidTenants = dataProvider.tenants.where((tenant) {
      // Get all rent transactions for this tenant in the specific month
      final rentTransactions = dataProvider.transactions.where((t) =>
          t.tenantId == tenant.id &&
          t.type.toLowerCase() == 'rent' &&
          t.status.toLowerCase() == 'completed' &&
          DateTime.fromMillisecondsSinceEpoch(t.date).year == month.year &&
          DateTime.fromMillisecondsSinceEpoch(t.date).month == month.month);

      // Tenant is unpaid if they have no completed rent transactions this month
      // and they are currently assigned to an asset
      return rentTransactions.isEmpty && tenant.assetId.isNotEmpty;
    }).toList();

    // Group unpaid tenants by asset ID to avoid duplicates
    final Map<String, List<Tenant>> unpaidTenantsByAsset = {};
    for (final tenant in unpaidTenants) {
      final asset = assets.firstWhere(
        (asset) => asset.id == tenant.assetId,
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
      if (!unpaidTenantsByAsset.containsKey(asset.address)) {
        unpaidTenantsByAsset[asset.address] = [];
      }
      unpaidTenantsByAsset[asset.address]!.add(tenant);
    }

    // Calculate income and expenses for the specific month
    final monthlyTransactions = transactions.where((t) {
      final transactionDate = DateTime.fromMillisecondsSinceEpoch(t.date);
      return transactionDate.year == month.year &&
          transactionDate.month == month.month;
    }).toList();

    final totalIncome = monthlyTransactions
        .where((t) => t.type.toLowerCase() == 'rent')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpenses = monthlyTransactions
        .where((t) => t.type.toLowerCase() == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final netIncome = totalIncome - totalExpenses;

    // Calculate expected cash flow (sum of all property rent amounts)
    final expectedCashFlow =
        assets.fold(0.0, (sum, asset) => sum + asset.rentAmount);

    final pendingIncome = expectedCashFlow - totalIncome;

    return {
      'occupiedUnits': occupiedUnits,
      'totalUnits': totalUnits,
      'occupancyRate': occupancyRate,
      'upcomingLeaseEnds': upcomingLeaseEnds,
      'unpaidTenants': unpaidTenants,
      'unpaidTenantsByAsset': unpaidTenantsByAsset,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netIncome': netIncome,
      'monthlyTransactions': monthlyTransactions,
      'expectedCashFlow': expectedCashFlow,
    };
  }

  // Build dashboard content for a specific month
  Widget _buildMonthlyDashboard(DateTime month) {
    final dataProvider = context.watch<DataProvider>();
    final assets = dataProvider.assets;
    final stats = _getMonthlyStatistics(month);

    final unpaidTenants = stats['unpaidTenants'] as List;
    final totalIncome = stats['totalIncome'] as double;
    final totalExpenses = stats['totalExpenses'] as double;
    final netIncome = stats['netIncome'] as double;
    final occupiedUnits = stats['occupiedUnits'] as int;
    final totalUnits = stats['totalUnits'] as int;
    final occupancyRate = stats['occupancyRate'] as String;
    final upcomingLeaseEnds = stats['upcomingLeaseEnds'] as int;
    final expectedCashFlow = stats['expectedCashFlow'] as double;
    final pendingIncome = expectedCashFlow - totalIncome;

    developer.log(
        'Dashboard Statistics for ${DateFormat('MMMM yyyy').format(month)}:');
    developer.log('Expected Income: $expectedCashFlow');
    developer.log('Total Income: $totalIncome');
    developer.log('Pending Income: $pendingIncome');
    developer.log('Total Expenses: $totalExpenses');
    developer.log('Net Income: $netIncome');
    developer.log('Total Transactions: ${stats['monthlyTransactions'].length}');

    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            'Financial Summary',
            [
              _buildStatRow(
                'Expected Income',
                currencyFormat.format(expectedCashFlow),
                Icons.account_balance_wallet,
                color: Colors.teal,
              ),
              _buildStatRow(
                'Total Income',
                currencyFormat.format(totalIncome),
                Icons.arrow_upward,
                color: Colors.green,
              ),
              _buildStatRow(
                'Pending Income',
                currencyFormat.format(pendingIncome),
                Icons.pending_actions,
                color: Colors.orange,
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
                'Unpaid Tenants',
                unpaidTenants.length.toString(),
                Icons.money_off,
                color: unpaidTenants.isNotEmpty ? Colors.red : Colors.green,
              ),
              if (unpaidTenants.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                // Group unpaid tenants by property
                ...stats['unpaidTenantsByAsset'].keys.map((address) {
                  final assetUnpaidTenants =
                      stats['unpaidTenantsByAsset'][address] as List<Tenant>;
                  final asset = assets.firstWhere(
                    (a) => a.address == address,
                    orElse: () => Asset(
                      id: '',
                      name: 'Unknown Property',
                      address: address,
                      type: 'Unknown',
                      status: 'Unknown',
                      unitNumber: '',
                      rentAmount: 0.0,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                      updatedAt: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property header with unpaid count
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.home,
                                size: 20, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withAlpha(77),
                                ),
                              ),
                              child: Text(
                                '${assetUnpaidTenants.length} unpaid',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // List of unpaid tenants for this property
                      Container(
                        margin: const EdgeInsets.only(left: 16.0),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Colors.teal.withAlpha(100),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Column(
                          children: assetUnpaidTenants.map((tenant) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, bottom: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.person,
                                      size: 16, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tenant.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Unit ${asset.unitNumber}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
              ],
              const SizedBox(height: 16),
              _buildStatRow(
                'Upcoming Lease Ends',
                upcomingLeaseEnds.toString(),
                Icons.warning,
                color: upcomingLeaseEnds > 0 ? Colors.orange : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        title: const Text('Asset Overview by Month'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          indicatorColor: Colors.teal,
          tabs: _months.map((month) {
            return Tab(
              text: DateFormat('MMM yyyy').format(month),
            );
          }).toList(),
        ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal,
                            side: const BorderSide(color: Colors.teal),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: _months.map((month) {
                      return _buildMonthlyDashboard(month);
                    }).toList(),
                  ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.teal, width: 1),
      ),
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
                color: Colors.teal,
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
    final displayColor = color ?? Colors.teal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: displayColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: displayColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
