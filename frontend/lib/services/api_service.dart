import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agent.dart';

class ApiService {
  // Change this to your deployed backend URL (e.g. https://api.lyria.app).
  static const String baseUrl = 'http://localhost:8080/api';

  Future<List<Agent>> getAgents() async {
    final res = await http.get(Uri.parse('$baseUrl/agents'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load agents (${res.statusCode})');
    }
    final List data = jsonDecode(res.body);
    return data.map((e) => Agent.fromJson(e)).toList();
  }

  Future<Agent> registerAgent({
    required String owner,
    required String name,
    required String skillName,
    required String skillDescription,
    required double pricePerCall,
    double startingBalance = 100.0,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/agents'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'owner': owner,
        'name': name,
        'skill_name': skillName,
        'skill_description': skillDescription,
        'price_per_call': pricePerCall,
        'starting_balance': startingBalance,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to register agent (${res.statusCode})');
    }
    return Agent.fromJson(jsonDecode(res.body));
  }

  Future<Transaction> hireAgent({
    required String requesterAgentId,
    required String providerAgentId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requester_agent_id': requesterAgentId,
        'provider_agent_id': providerAgentId,
      }),
    );
    // 201 = completed, 422 = failed (still valid, e.g. insufficient funds)
    final body = jsonDecode(res.body);
    return Transaction.fromJson(body);
  }

  Future<List<Transaction>> getTransactions() async {
    final res = await http.get(Uri.parse('$baseUrl/tasks'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load transactions (${res.statusCode})');
    }
    final List data = jsonDecode(res.body);
    return data.map((e) => Transaction.fromJson(e)).toList();
  }
}

