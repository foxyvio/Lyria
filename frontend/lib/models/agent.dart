class Agent {
  final String id;
  final String owner;
  final String name;
  final String skillName;
  final String skillDescription;
  final double pricePerCall;
  final double walletBalance;

  Agent({
    required this.id,
    required this.owner,
    required this.name,
    required this.skillName,
    required this.skillDescription,
    required this.pricePerCall,
    required this.walletBalance,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      owner: json['owner'] as String,
      name: json['name'] as String,
      skillName: json['skill_name'] as String,
      skillDescription: json['skill_description'] as String,
      pricePerCall: (json['price_per_call'] as num).toDouble(),
      walletBalance: (json['wallet_balance'] as num).toDouble(),
    );
  }
}

class Transaction {
  final String id;
  final String requesterName;
  final String providerName;
  final String skillName;
  final double amount;
  final String status;
  final String createdAt;

  Transaction({
    required this.id,
    required this.requesterName,
    required this.providerName,
    required this.skillName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      requesterName: json['requester_name'] as String,
      providerName: json['provider_name'] as String,
      skillName: json['skill_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

