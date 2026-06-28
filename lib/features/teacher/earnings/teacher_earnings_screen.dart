import 'package:flutter/material.dart';

class TeacherEarningsScreen extends StatefulWidget {
  const TeacherEarningsScreen({super.key});

  @override
  State<TeacherEarningsScreen> createState() => _TeacherEarningsScreenState();
}

class _TeacherEarningsScreenState extends State<TeacherEarningsScreen> {
  double _walletBalance = 1420.50;
  final _withdrawAmountController = TextEditingController();

  final List<Map<String, String>> _transactions = [
    {'title': 'Student Subscription Share', 'amount': '+\$29.99', 'date': '09 June 2026', 'type': 'Income'},
    {'title': 'Student Course Purchase', 'amount': '+\$9.99', 'date': '08 June 2026', 'type': 'Income'},
    {'title': 'Wallet Payout (Bank Transfer)', 'amount': '-\$500.00', 'date': '01 June 2026', 'type': 'Withdrawal'},
    {'title': 'Student Subscription Share', 'amount': '+\$29.99', 'date': '28 May 2026', 'type': 'Income'},
  ];

  void _requestWithdrawal() {
    final amtText = _withdrawAmountController.text;
    if (amtText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount to withdraw')),
      );
      return;
    }

    final amt = double.tryParse(amtText);
    if (amt == null || amt <= 0 || amt > _walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid withdrawal amount entered')),
      );
      return;
    }

    setState(() {
      _walletBalance -= amt;
      _transactions.insert(0, {
        'title': 'Wallet Payout Pending',
        'amount': '-\$${amt.toStringAsFixed(2)}',
        'date': 'Just now',
        'type': 'Withdrawal',
      });
    });

    _withdrawAmountController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdrawal Requested'),
        content: Text('Your payout request of \$$amtText is processing and will be sent to your bank account in 2-3 business days.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Okay'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Payout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wallet Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_walletBalance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lifetime Earnings:', style: TextStyle(color: Colors.white70)),
                      Text('\$4,890.00', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Withdraw Form
            const Text('Request Bank Payout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _withdrawAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Withdraw Amount (\$)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _requestWithdrawal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Transaction History
            const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._transactions.map((tx) {
              final isIncome = tx['type'] == 'Income';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(tx['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(tx['date']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Text(
                    tx['amount']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
