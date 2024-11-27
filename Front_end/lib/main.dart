import 'package:flutter/material.dart';
import 'package:python_compiler/screen/compiler_screen.dart';

void main() {
  runApp(const PythonCompilerApp());
}

class PythonCompilerApp extends StatelessWidget {
  const PythonCompilerApp({super.key}); // Add the named key parameter

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Python Compiler',
      home: PythonCompilerScreen(),
    );
  }
}
