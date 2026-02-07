import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facturacion_sistema/Assets/Models/seleccion_empresa.dart';
import 'package:flutter_facturacion_sistema/Widgets/factura_form.dart';
import 'package:flutter_facturacion_sistema/Screens/recibos_preview.dart';
import 'package:flutter_facturacion_sistema/Assets/Models/tipo_recibo.dart'; // Enum compartido
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import 'package:window_size/window_size.dart';

const Size desktopNormalSize = Size(600, 1000);
const Size desktopFirmaSize = Size(1000, 800);

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
  TipoRecibo tipoSeleccionado = TipoRecibo.Ingreso; 
  SeleccionEmpresa empresaSeleccionada = SeleccionEmpresa.Kaleyman; // default
  Uint8List? firmaEgreso; // ✅ Firma para egresos

  // ======== PEDIR FIRMA ========
  Future<Uint8List?> _pedirFirma() async {
  final SignatureController controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  Uint8List? firma;

  final bool isDesktop =
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  // 🖥 Desktop → cambiar ventana a 900x900
  if (isDesktop) {
    setWindowMinSize(desktopFirmaSize);
    setWindowMaxSize(desktopFirmaSize);
    setWindowFrame(
      Rect.fromLTWH(100, 100, desktopFirmaSize.width, desktopFirmaSize.height),
    );
  } 
  // 📱 Móvil → forzar horizontal
  else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Mostrar diálogo de firma
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Firma del receptor'),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(6),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) {
              // comienza la captura de puntero
            },
            onPointerUp: (_) {
              // finaliza la captura
            },
            child: MouseRegion(
              //cursor: SystemMouseCursors.none, // 👻 ocultar cursor
              child: SizedBox.expand(
                child: Signature(
                  controller: controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
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
                    if (mounted) Navigator.of(context).pop();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se ha dibujado ninguna firma'),
                        ),
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

  // 🔙 Restaurar tamaño y orientación
  if (isDesktop) {
    setWindowMinSize(desktopNormalSize);
    setWindowMaxSize(desktopNormalSize);
    setWindowFrame(
      Rect.fromLTWH(100, 100, desktopNormalSize.width, desktopNormalSize.height),
    );
  } else {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

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
        title: const Text('Recibos KALEYMAN - LATINOANDES'),
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
                empresa: empresaSeleccionada, // 👈 NUEVO
                firma: firmaEgreso,
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
                      const SizedBox(width: 10),
                      const Text('Empresa: ', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      DropdownButton<SeleccionEmpresa>(
                        value: empresaSeleccionada,
                        items: const [
                          DropdownMenuItem(
                            value: SeleccionEmpresa.Latinoandes,
                            child: Text('LATINOANDES'),
                          ),
                          DropdownMenuItem(
                            value: SeleccionEmpresa.Kaleyman,
                            child: Text('KALEYMAN'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              empresaSeleccionada = value;
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
