import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../models/tenant.dart';
import '../models/asset.dart';
import '../models/transaction.dart';

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

    // Find unpaid tenants and their pending transactions
    final Map<String, List<dynamic>> unpaidTenantsWithTransactions = {};
    final Map<String, double> accumulatedPendingAmounts = {};

    for (final tenant in tenants) {
      if (tenant.assetId.isEmpty) continue;

      final pendingTransactions = transactions.where((t) {
        final transactionDate = DateTime.fromMillisecondsSinceEpoch(t.date);
        return t.tenantId == tenant.id &&
            t.type.toLowerCase() == 'rent' &&
            transactionDate
                .isBefore(DateTime(month.year, month.month + 1, 1)) &&
            t.status.toLowerCase() == 'pending';
      }).toList();

      if (pendingTransactions.isNotEmpty) {
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

        final accumulatedAmount =
            pendingTransactions.fold(0.0, (sum, t) => sum + t.amount);
        accumulatedPendingAmounts[tenant.id] = accumulatedAmount;

        if (!unpaidTenantsWithTransactions.containsKey(asset.address)) {
          unpaidTenantsWithTransactions[asset.address] = [];
        }
        unpaidTenantsWithTransactions[asset.address]!.add({
          'tenant': tenant,
          'asset': asset,
          'transactions': pendingTransactions,
          'accumulatedAmount': accumulatedAmount,
        });
      }
    }

    return {
      'occupiedUnits': occupiedUnits,
      'totalUnits': totalUnits,
      'occupancyRate': occupancyRate,
      'upcomingLeaseEnds': upcomingLeaseEnds,
      'unpaidTenantsWithTransactions': unpaidTenantsWithTransactions,
      'accumulatedPendingAmounts': accumulatedPendingAmounts,
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
    final stats = _getMonthlyStatistics(month);

    final unpaidTenantsWithTransactions =
        stats['unpaidTenantsWithTransactions'] as Map<String, List<dynamic>>;
    final totalIncome = stats['totalIncome'] as double;
    final totalExpenses = stats['totalExpenses'] as double;
    final netIncome = stats['netIncome'] as double;
    final occupiedUnits = stats['occupiedUnits'] as int;
    final totalUnits = stats['totalUnits'] as int;
    final occupancyRate = stats['occupancyRate'] as String;
    final upcomingLeaseEnds = stats['upcomingLeaseEnds'] as int;
    final expectedCashFlow = stats['expectedCashFlow'] as double;
    final pendingIncome = expectedCashFlow - totalIncome;

    // Calculate total accumulated unpaid amount
    final totalUnpaidAmount =
        unpaidTenantsWithTransactions.values.fold<double>(0.0, (sum, list) {
      return sum +
          list.fold<double>(0.0, (innerSum, tenantData) {
            return innerSum + (tenantData['accumulatedAmount'] as double);
          });
    });

    developer.log(
        'Dashboard Statistics for ${DateFormat('MMMM yyyy').format(month)}:');
    developer.log('Expected Income: $expectedCashFlow');
    developer.log('Total Income: $totalIncome');
    developer.log('Pending Income: $pendingIncome');
    developer.log('Total Expenses: $totalExpenses');
    developer.log('Net Income: $netIncome');
    developer.log('Total Transactions: ${stats['monthlyTransactions'].length}');

    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            'Monthly Financial Summary',
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
              Row(
                children: [
                  Expanded(
                    child: _buildStatRow(
                      'Unpaid Tenants',
                      '${unpaidTenantsWithTransactions.values.fold(0, (sum, list) => sum + list.length)}',
                      Icons.money_off,
                      color: unpaidTenantsWithTransactions.isNotEmpty
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  if (unpaidTenantsWithTransactions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currencyFormat.format(totalUnpaidAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
              if (unpaidTenantsWithTransactions.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                ...unpaidTenantsWithTransactions.keys.map((address) {
                  final tenantsList =
                      unpaidTenantsWithTransactions[address] as List<dynamic>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${tenantsList.length} unpaid',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.only(left: 16.0),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Colors.red.withAlpha(100),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Column(
                          children: tenantsList.map((tenantData) {
                            final tenant = tenantData['tenant'] as Tenant;
                            final asset = tenantData['asset'] as Asset;
                            final transactions =
                                tenantData['transactions'] as List;
                            final accumulatedAmount =
                                tenantData['accumulatedAmount'] as double;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              tenant.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              currencyFormat
                                                  .format(accumulatedAmount),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Unit ${asset.unitNumber}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...transactions.map((transaction) {
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                left: 16.0, bottom: 4.0),
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.orange.withAlpha(10),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  DateFormat('MMM yyyy').format(
                                                    DateTime
                                                        .fromMillisecondsSinceEpoch(
                                                            transaction.date),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  currencyFormat.format(
                                                      transaction.amount),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? Colors.teal,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: color ?? Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildTenantsList(BuildContext context) {
    final tenants = context.read<DataProvider>().tenants;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Tenants',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              final asset = context.read<DataProvider>().assets.firstWhere(
                    (a) => a.id == tenant.assetId,
                    orElse: () => Asset(
                      id: '',
                      name: 'Unknown Asset',
                      address: 'Unknown Location',
                      type: 'residential',
                      status: 'active',
                      unitNumber: '',
                      rentAmount: 0.0,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                      updatedAt: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(tenant.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.name),
                      Text(asset.address),
                      Text('Phone: ${tenant.phone}'),
                    ],
                  ),
                  trailing: Text(
                    '₹${asset.rentAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsList(BuildContext context) {
    final assets = context.read<DataProvider>().assets;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                Icons.business,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Assets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(asset.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.address),
                      Text('Type: ${asset.type.capitalize()}'),
                      Text('Status: ${asset.status.capitalize()}'),
                    ],
                  ),
                  trailing: Text(
                    '₹${asset.rentAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    final transactions = context.read<DataProvider>().transactions;

    // Group transactions by month and year
    final Map<String, List<Transaction>> groupedTransactions = {};
    for (final transaction in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.date);
      final monthYear = '${_getMonthName(date.month)} ${date.year}';
      if (!groupedTransactions.containsKey(monthYear)) {
        groupedTransactions[monthYear] = [];
      }
      groupedTransactions[monthYear]!.add(transaction);
    }

    // Sort months in descending order
    final sortedMonths = groupedTransactions.keys.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse('1 ${a.split(' ')[0]} ${a.split(' ')[1]}');
        final dateB = DateTime.parse('1 ${b.split(' ')[0]} ${b.split(' ')[1]}');
        return dateB.compareTo(dateA);
      });

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                Icons.receipt,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedMonths.length,
            itemBuilder: (context, monthIndex) {
              final monthYear = sortedMonths[monthIndex];
              final monthTransactions = groupedTransactions[monthYear]!;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        monthYear,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        '${monthTransactions.length} transactions',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          TabBar(
                            tabs: const [
                              Tab(text: 'Completed'),
                              Tab(text: 'Pending'),
                            ],
                            labelColor: Theme.of(context).primaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Theme.of(context).primaryColor,
                          ),
                          SizedBox(
                            height: 300,
                            child: TabBarView(
                              children: [
                                _buildMonthTransactionsList(
                                  context,
                                  monthTransactions,
                                  'completed',
                                ),
                                _buildMonthTransactionsList(
                                  context,
                                  monthTransactions,
                                  'pending',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthTransactionsList(
    BuildContext context,
    List<Transaction> transactions,
    String status,
  ) {
    final filteredTransactions = transactions
        .where((transaction) => transaction.status.toLowerCase() == status)
        .toList();

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Text(
          'No ${status.capitalize()} transactions',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // Group transactions by asset location
    final Map<String, List<Transaction>> locationGroups = {};
    for (final transaction in filteredTransactions) {
      final asset = context.read<DataProvider>().assets.firstWhere(
            (a) => a.id == transaction.assetId,
            orElse: () => Asset(
              id: '',
              name: 'Unknown Asset',
              address: 'Unknown Location',
              type: 'residential',
              status: 'active',
              unitNumber: '',
              rentAmount: 0.0,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      final location = asset.address;
      if (!locationGroups.containsKey(location)) {
        locationGroups[location] = [];
      }
      locationGroups[location]!.add(transaction);
    }

    return ListView.builder(
      itemCount: locationGroups.length,
      itemBuilder: (context, index) {
        final location = locationGroups.keys.elementAt(index);
        final locationTransactions = locationGroups[location]!;

        return ExpansionTile(
          title: Text(
            location,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          children: locationTransactions.map((transaction) {
            final tenant = context.read<DataProvider>().tenants.firstWhere(
                  (t) => t.id == transaction.tenantId,
                  orElse: () => Tenant(
                    id: '',
                    name: 'Unknown Tenant',
                    remarks: '',
                    phone: '',
                    aadharNumber: '',
                    aadharImage: '',
                    assetId: '',
                    assetName: '',
                    leaseStart: DateTime.now().millisecondsSinceEpoch,
                    leaseEnd: DateTime.now().millisecondsSinceEpoch,
                    advanceAmount: 0,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  ),
                );

            return ListTile(
              title: Text(
                '${transaction.type.capitalize()} - ${tenant.name}',
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                DateFormat('dd MMM').format(
                  DateTime.fromMillisecondsSinceEpoch(transaction.date),
                ),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                '₹${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color:
                      transaction.type == 'income' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2024, month));
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
