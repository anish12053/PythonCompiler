import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PythonCompilerScreen extends StatefulWidget {
  const PythonCompilerScreen({super.key});

  @override
  PythonCompilerScreenState createState() => PythonCompilerScreenState();
}

class PythonCompilerScreenState extends State<PythonCompilerScreen> {
  final _codeController = TextEditingController();
  final _inputController = TextEditingController();
  String _output = "";
  String sessionId = ''; // To store session ID

  Future<void> _runCode() async {
    final url = Uri.parse('http://192.168.1.6:5001/execute'); // Replace with your Flask server's IP
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': _codeController.text,
          'session_id': sessionId.isEmpty ? null : sessionId, // Send session ID if it exists
          'user_input': _inputController.text, // Send user input from the input field
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _output = data['error'] ?? data['result'] ?? 'No Output';
          sessionId = data['session_id']; // Store session ID for future requests
        });
      } else {
        setState(() {
          _output = "Error: Could not connect to the server.";
        });
      }
    } catch (e) {
      setState(() {
        _output = "Error: $e";
      });
    }
  }

  void _clearInput() {
    _codeController.clear();
    _inputController.clear();
    setState(() {
      _output = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Python Compiler'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter Python code here...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter Input',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _runCode,
                  child: const Text('Run'),
                ),
                ElevatedButton(
                  onPressed: _clearInput,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Output",style: TextStyle(
              fontSize: 20,
            ),),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _output,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
