import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer' as developer;

class TestAssetData extends StatefulWidget {
  const TestAssetData({super.key});

  @override
  State<TestAssetData> createState() => _TestAssetDataState();
}

class _TestAssetDataState extends State<TestAssetData> {
  List<Map<String, dynamic>> assets = [];
  String error = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('assets').get();

      if (!snapshot.exists) {
        setState(() {
          error = 'No assets found in database';
          isLoading = false;
        });
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> assetsList = [];

      data.forEach((key, value) {
        if (value is Map) {
          final asset = Map<String, dynamic>.from(value);
          asset['id'] = key;
          assetsList.add(asset);

          // Log asset details for debugging
          developer.log('Asset ID: $key');
          developer.log('Unit Number: ${asset['unit_number']}');
          developer.log('Asset Data: $asset');
        }
      });

      setState(() {
        assets = assetsList;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log('Error fetching assets: $e\n$stackTrace');
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Data Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAssets,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(error, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAssets,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Total Assets: ${assets.length}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    ...assets.map((asset) => Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(
                                'Unit Number: ${asset['unit_number'] ?? 'NULL'}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${asset['id']}'),
                                Text('Name: ${asset['name'] ?? 'NULL'}'),
                                Text('Type: ${asset['type'] ?? 'NULL'}'),
                                Text('Status: ${asset['status'] ?? 'NULL'}'),
                                Text(
                                    'Created At: ${asset['created_at'] ?? 'NULL'}'),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
    );
  }
}
