import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboard;
  final List<TextInputFormatter> inputFormatters;
  final String? Function(String?)? validator; // ✅ validator opcional

  const InputField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboard = TextInputType.text,
    required this.inputFormatters,
    this.validator, // opcional
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboard,
        inputFormatters: widget.inputFormatters,
        validator: widget.validator, // ✅ usamos el validator pasado
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
