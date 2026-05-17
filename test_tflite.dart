import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  try {
    print('Testing model.tflite...');
    var interpreter = Interpreter.fromFile(File('assets/models/model.tflite'));
    print('Success! Model loaded.');
    print('Inputs: ${interpreter.getInputTensors()}');
    print('Outputs: ${interpreter.getOutputTensors()}');
  } catch (e) {
    print('Failed to load model: $e');
  }
}
