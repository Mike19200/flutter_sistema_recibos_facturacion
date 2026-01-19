import 'package:flutter/material.dart';

class FacturaRow extends StatefulWidget {
  final String title;
  final String value;
  const FacturaRow({super.key, required this.title, required this.value});

  @override
  State<FacturaRow> createState() => _FacturaRowState();
}

class _FacturaRowState extends State<FacturaRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 16),
          children: [
            TextSpan(text: '${widget.title} ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: widget.value),
          ],
        ),
      ),
    );
  }
}
