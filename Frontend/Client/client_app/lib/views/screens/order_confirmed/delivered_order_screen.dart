import 'package:flutter/material.dart';
import 'package:teste_2/views/screens/home/home_screen.dart';

class DeliveredOrderScreen extends StatefulWidget {
  const DeliveredOrderScreen({super.key});

  @override
  State<DeliveredOrderScreen> createState() => _DeliveredOrderScreenState();
}

class _DeliveredOrderScreenState extends State<DeliveredOrderScreen> {
  int _selectedEmoji = -1;

  void _submitFeedback() {
    // Lógica para enviar o feedback
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Rate your experience',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEmoji(0, 'Angry', Icons.sentiment_very_dissatisfied, Colors.red),
                _buildEmoji(1, 'Upset', Icons.sentiment_dissatisfied, Colors.orange),
                _buildEmoji(2, 'Neutral', Icons.sentiment_neutral, Colors.yellow),
                _buildEmoji(3, 'Happy', Icons.sentiment_satisfied, Colors.lightGreen),
                _buildEmoji(4, 'Excited', Icons.sentiment_very_satisfied, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Thank you for your preference. Please leave your feedback above.',                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Navigate to Home', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmoji(int index, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmoji = index;
        });
      },
      child: Column(
        children: [
          Icon(
            icon,
            color: _selectedEmoji == index ? color : Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: _selectedEmoji == index ? color : Colors.grey,
              fontWeight: _selectedEmoji == index ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
