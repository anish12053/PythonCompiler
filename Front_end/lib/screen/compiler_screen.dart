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
          _output = "Error: Server responded with status ${response.statusCode}.";
        });
      }
    } catch (e) {
      setState(() {
        _output = "Error: Unable to connect to the server. $e";
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
        title: const Text("Python Compiler"),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Python Code:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter your Python code here...",
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Input for Code (optional):",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter any input required for your code...",
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _runCode,
                            child: const Text("Run Code"),
                          ),
                          ElevatedButton(
                            onPressed: _clearInput,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text("Clear"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          color: Colors.grey.shade200,
                          child: SingleChildScrollView(
                            child: Text(
                              _output,
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
