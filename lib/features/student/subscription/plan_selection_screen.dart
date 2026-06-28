import 'package:flutter/material.dart';
import 'payment_gateway_screen.dart';

class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = [
      {
        'name': 'Monthly Pass',
        'price': '\$9.99',
        'period': '/ month',
        'features': ['Access to all videos', 'Unlimited doubt asks', 'Practice worksheets', 'Email support'],
        'color': Colors.blue,
      },
      {
        'name': 'Yearly Premium',
        'price': '\$79.99',
        'period': '/ year',
        'features': ['Everything in Monthly', 'One-on-one video calls', 'Mock exam papers', 'Priority support', 'Save 33%'],
        'color': Colors.amber,
        'popular': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Unlock Premium Learning',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get unlimited access to top teachers and study guides',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ...plans.map((plan) {
              final isPopular = plan['popular'] == true;
              final color = plan['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPopular ? color : Colors.grey.withValues(alpha: 0.3),
                    width: isPopular ? 2 : 1,
                  ),
                  boxShadow: isPopular
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ]
                      : null,
                ),
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isPopular) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'BEST VALUE',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          plan['name'] as String,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              plan['price'] as String,
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              plan['period'] as String,
                              style: const TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        ...List.generate(
                          (plan['features'] as List).length,
                          (idx) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: color, size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    (plan['features'] as List)[idx] as String,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentGatewayScreen(
                                  planName: plan['name'] as String,
                                  planPrice: plan['price'] as String,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Subscribe Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
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
