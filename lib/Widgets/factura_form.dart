import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facturacion_sistema/Assets/Models/numero_a_letras_co.dart';
import 'input_field.dart';
import 'package:intl/intl.dart';

class FacturaForm extends StatefulWidget {
  final void Function({
    required String ciudad,
    required String fecha,
    required String nombre,
    required String concepto,
    required String valor,
    required String valorTexto,
  }) onSubmit;

  const FacturaForm({super.key, required this.onSubmit});

  @override
  State<FacturaForm> createState() => _FacturaFormState();
}

class _FacturaFormState extends State<FacturaForm> {
  final _formKey = GlobalKey<FormState>();

  final fechaCtrl = TextEditingController();
  final nombreCtrl = TextEditingController();
  final conceptoCtrl = TextEditingController();
  final valorCtrl = TextEditingController();

  String? ciudadSeleccionada;

  final List<String> ciudades = [
    'Cúcuta, Norte de Santander',
  ];

  @override
  void initState() {
    super.initState();
    fechaCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    try {
      final parsed = DateFormat('dd/MM/yyyy').parse(fechaCtrl.text);
      initialDate = parsed;
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        fechaCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: ciudadSeleccionada,
            decoration: const InputDecoration(
              labelText: 'Ciudad',
              border: OutlineInputBorder(),
            ),
            items: ciudades
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            validator: (v) => v == null || v.isEmpty ? 'Seleccione una ciudad' : null,
            onChanged: (v) => setState(() => ciudadSeleccionada = v),
          ),

          const SizedBox(height: 12),

          // Fecha
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: InputField(
                controller: fechaCtrl,
                label: 'Fecha',
                inputFormatters: [], // <- obligatorio, lista vacía
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Nombre
          InputField(
            controller: nombreCtrl,
            label: 'Nombre',
            inputFormatters: [], // <- obligatorio
          ),

          const SizedBox(height: 12),

          // Concepto
          InputField(
            controller: conceptoCtrl,
            label: 'Concepto',
            inputFormatters: [], // <- obligatorio
          ),

          const SizedBox(height: 12),

          // Valor (solo números)
          InputField(
            controller: valorCtrl,
            label: 'Valor',
            keyboard: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingrese un valor';
              if (int.tryParse(v.replaceAll('.', '').replaceAll(',', '')) == null) {
                return 'Ingrese solo números válidos';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                String valorLimpio =
                    valorCtrl.text.replaceAll('.', '').replaceAll(',', '');
                int valorNumero = int.tryParse(valorLimpio) ?? 0;

                final valorFormateado =
                    NumberFormat('#,###', 'es_CO').format(valorNumero);

                widget.onSubmit(
                  ciudad: ciudadSeleccionada!,
                  fecha: fechaCtrl.text,
                  nombre: nombreCtrl.text,
                  concepto: conceptoCtrl.text,
                  valor: valorFormateado,
                  valorTexto:
                      '${NumeroALetrasCO.convertir(valorNumero).toUpperCase()} PESOS COLOMBIANOS',
                );
              }
            },
            child: const Text('Generar Recibo'),
          ),
        ],
      ),
    );
  }
}
