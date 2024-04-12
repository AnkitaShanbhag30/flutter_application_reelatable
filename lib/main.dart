import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reelatable',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          background: Color(0xFF070D35),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Reelatable'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  String _responseText = '';

  Future<void> _sendDataToBackend([String? movieName]) async {
    movieName ??= _textController.text;
    var url = Uri.parse('http://flask-reelatable-service.default.svc.cluster.local:5000/api');
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'movieName': movieName}),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Set the state to update the response text on UI
      setState(() {
        _responseText = json.decode(response.body)['message'] ?? 'No response';
      });
    } catch (e) {
      print('Error sending data to backend: $e');
      setState(() {
        _responseText = 'Error sending data to backend: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Color(0xFF773A7E),
        foregroundColor: Color(0xFFF2DBAF),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 300),
        color: Color(0xFF070D35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Enter a movie that you like',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              onSubmitted: _sendDataToBackend,
              decoration: InputDecoration(
                fillColor: Color(0xFFF2DBAF),
                filled: true,
                border: OutlineInputBorder(),
                labelText: 'Search',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _sendDataToBackend(),
              child: const Text('Add'),
            ),
            const SizedBox(height: 20),
            Text(
              _responseText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
