import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facturacion_sistema/Widgets/factura_form.dart';
import 'package:flutter_facturacion_sistema/Screens/recibos_preview.dart';
import 'package:flutter_facturacion_sistema/Assets/Models/tipo_recibo.dart'; // Enum compartido
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';

class RecibosScreen extends StatefulWidget {
  const RecibosScreen({super.key});

  @override
  State<RecibosScreen> createState() => _RecibosScreenState();
}

class _RecibosScreenState extends State<RecibosScreen> {
  int currentIndex = 0;
  bool mostrarRecibo = false;

  // Datos del recibo
  String ciudad = '';
  String fecha = '';
  String nombre = '';
  String concepto = '';
  String valor = '';
  String valorTexto = '';
  TipoRecibo tipoSeleccionado = TipoRecibo.Ingreso; // Por defecto
  Uint8List? firmaEgreso; // ✅ Firma para egresos

  // ======== PEDIR FIRMA ========
  Future<Uint8List?> _pedirFirma() async {
  final SignatureController controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  Uint8List? firma;

  // Forzar orientación horizontal
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Mostrar firma en pantalla completa
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => WillPopScope(
      // Evitar cerrar con el botón atrás
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Firma del receptor'),
          automaticallyImplyLeading: false, // quitar botón atrás
        ),
        body: Center(
          child: Signature(
            controller: controller,
            width: double.infinity,
            height: double.infinity,
            backgroundColor: Colors.white,
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
              onPressed: controller.clear,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Borrar', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
              onPressed: () async {
                if (controller.isNotEmpty) {
                firma = await controller.toPngBytes();
                if (mounted) {
                  Navigator.of(context).pop();
                }
                } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se ha dibujado ninguna firma')),
                  );
                }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Volver a orientación vertical cuando se cierre la firma
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  return firma;
}

  // ======== MOSTRAR PREVIEW ========
      void mostrarPreview({
    required String ciudad,
    required String fecha,
    required String nombre,
    required String concepto,
    required String valor,
    required String valorTexto,
    required TipoRecibo tipo,
  }) async {
    Uint8List? firma;
    if (tipo == TipoRecibo.Egreso) {
      firma = await _pedirFirma();
      if (firma == null) return; // no continuar si no hay firma
    }
  
    setState(() {
      this.ciudad = ciudad;
      this.fecha = fecha;
      this.nombre = nombre;
      this.concepto = concepto;
      this.valor = valor; // mantener positivo para mostrar
      this.valorTexto = valorTexto;
      this.tipoSeleccionado = tipo;
      mostrarRecibo = true;
    });
  
    // Guardamos la firma en un campo temporal que luego ReciboPreview recibirá
    firmaEgreso = firma;
  }

  void editarDatos() {
    setState(() {
      mostrarRecibo = false;
      firmaEgreso = null; // Limpiamos firma al editar
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recibos KALEYMAN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: mostrarRecibo
            ? ReciboPreview(
                ciudad: ciudad,
                fecha: fecha,
                nombre: nombre,
                concepto: concepto,
                valor: valor,
                valorTexto: valorTexto,
                tipo: tipoSeleccionado,
                firma: firmaEgreso, // ✅ Pasamos la firma al preview
                onEditar: editarDatos,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Tipo de recibo: ', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      DropdownButton<TipoRecibo>(
                        value: tipoSeleccionado,
                        items: const [
                          DropdownMenuItem(
                            value: TipoRecibo.Ingreso,
                            child: Text('Ingreso'),
                          ),
                          DropdownMenuItem(
                            value: TipoRecibo.Egreso,
                            child: Text('Egreso'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              tipoSeleccionado = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FacturaForm(
                    onSubmit: ({
                      required ciudad,
                      required fecha,
                      required nombre,
                      required concepto,
                      required valor,
                      required valorTexto,
                    }) {
                      mostrarPreview(
                        ciudad: ciudad,
                        fecha: fecha,
                        nombre: nombre,
                        concepto: concepto,
                        valor: valor,
                        valorTexto: valorTexto,
                        tipo: tipoSeleccionado,
                      );
                    },
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          if (index == 1) {
            context.go('/archivos'); // Pantalla de archivos
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Crear Recibo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Archivos',
          ),
        ],
      ),
    );
  }
}
