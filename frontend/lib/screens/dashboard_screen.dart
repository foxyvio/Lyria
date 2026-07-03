import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<Agent> _agents = [];
  List<Transaction> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final agents = await _api.getAgents();
      final txs = await _api.getTransactions();
      setState(() {
        _agents = agents;
        _transactions = txs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showRegisterDialog() {
    final ownerCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final skillCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '1.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register New Agent'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ownerCtrl, decoration: const InputDecoration(labelText: 'Owner')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Agent Name')),
              TextField(controller: skillCtrl, decoration: const InputDecoration(labelText: 'Skill Name')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Skill Description')),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price per call'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _api.registerAgent(
                  owner: ownerCtrl.text,
                  name: nameCtrl.text,
                  skillName: skillCtrl.text,
                  skillDescription: descCtrl.text,
                  pricePerCall: double.tryParse(priceCtrl.text) ?? 1.0,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _refresh();
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  void _hireAgent(Agent provider) {
    if (_agents.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 2 agents to simulate a hire.')),
      );
      return;
    }
    final requester = _agents.firstWhere((a) => a.id != provider.id);
    _api
        .hireAgent(requesterAgentId: requester.id, providerAgentId: provider.id)
        .then((tx) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tx.status} — ${requester.name} -> ${provider.name}')),
      );
      _refresh();
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyria — Agent Economy Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Agents'),
            Tab(text: 'Marketplace'),
            Tab(text: 'Transactions'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Agent'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAgentsList(),
                    _buildMarketplace(),
                    _buildTransactions(),
                  ],
                ),
    );
  }

  Widget _buildAgentsList() {
    if (_agents.isEmpty) {
      return const Center(child: Text('No agents yet. Tap "New Agent" to register one.'));
    }
    return ListView.builder(
      itemCount: _agents.length,
      itemBuilder: (ctx, i) {
        final a = _agents[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.smart_toy)),
            title: Text('${a.name} (${a.owner})'),
            subtitle: Text('${a.skillName} — \$${a.pricePerCall}/call'),
            trailing: Text('\$${a.walletBalance.toStringAsFixed(2)}'),
          ),
        );
      },
    );
  }

  Widget _buildMarketplace() {
    if (_agents.isEmpty) {
      return const Center(child: Text('No skills listed yet.'));
    }
    return ListView.builder(
      itemCount: _agents.length,
      itemBuilder: (ctx, i) {
        final a = _agents[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.storefront),
            title: Text(a.skillName),
            subtitle: Text('${a.skillDescription}\nSold by ${a.name}'),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: () => _hireAgent(a),
              child: Text('Hire \$${a.pricePerCall}'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactions() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions yet.'));
    }
    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (ctx, i) {
        final t = _transactions[i];
        final ok = t.status == 'completed';
        return ListTile(
          leading: Icon(ok ? Icons.check_circle : Icons.error, color: ok ? Colors.green : Colors.red),
          title: Text('${t.requesterName} -> ${t.providerName} (${t.skillName})'),
          subtitle: Text(t.status),
          trailing: Text('\$${t.amount.toStringAsFixed(2)}'),
        );
      },
    );
  }
}

