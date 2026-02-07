import 'dart:io'; 
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facturacion_sistema/Assets/Models/factura_model.dart';
import 'package:flutter_facturacion_sistema/Assets/Models/seleccion_empresa.dart';
import 'package:flutter_facturacion_sistema/Storage/factura_storage.dart';
import 'package:flutter_facturacion_sistema/Assets/Models/tipo_recibo.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../Widgets/factura_row.dart';

class ReciboPreview extends StatefulWidget {
  final String ciudad;
  final String fecha;
  final String nombre;
  final String concepto;
  final String valor;
  final String valorTexto;
  final TipoRecibo tipo;
  final Uint8List? firma; // ✅ Firma pasada desde RecibosScreen
  final VoidCallback onEditar;
  final SeleccionEmpresa empresa;

  const ReciboPreview({
    super.key,
    required this.ciudad,
    required this.fecha,
    required this.nombre,
    required this.concepto,
    required this.valor,
    required this.valorTexto,
    required this.tipo,
    required this.empresa,
    this.firma,
    required this.onEditar,
  });

  @override
  State<ReciboPreview> createState() => _ReciboPreviewState();
}

class _ReciboPreviewState extends State<ReciboPreview> {
  late final String numeroRecibo;

  @override
  void initState() {
    super.initState();
    numeroRecibo = _generarNumeroRecibo();
  }

  String _generarNumeroRecibo() {
    final random = Random();
    final numero = 100000 + random.nextInt(900000); // 6 dígitos
    final prefijo = widget.tipo == TipoRecibo.Ingreso ? 'RI' : 'RE';
    return '$prefijo-$numero';
  }

  // ======== CREAR PDF ========
  Future<pw.Document> _crearPdf() async {
    final pdf = pw.Document();

    final ttf = pw.Font.ttf(await rootBundle.load('lib/Assets/Fonts/Roboto-Regular.ttf'));
    String logoPath;

    switch (widget.empresa) {
      case SeleccionEmpresa.Latinoandes:
        logoPath = 'lib/Assets/Img/logo.png';
        break;
      case SeleccionEmpresa.Kaleyman:
        logoPath = 'lib/Assets/Img/logo.png';
        break;
    }
    
    final logoBytesData = await rootBundle.load(logoPath);
    final Uint8List logoBytes = logoBytesData.buffer.asUint8List();


    Uint8List firmaFinal;

    if (widget.tipo == TipoRecibo.Ingreso) {
      String firmaPath;
    
      if (widget.empresa == SeleccionEmpresa.Latinoandes) {
        firmaPath = 'lib/Assets/Img/firma.png';
      } else {
        firmaPath = 'lib/Assets/Img/firma.png';
      }
    
      final firmaData = await rootBundle.load(firmaPath);
      firmaFinal = firmaData.buffer.asUint8List();
    } else {
      // EGRESO → firma capturada (NO cambia)
      if (widget.firma != null) {
        firmaFinal = widget.firma!;
      } else {
        final firmaData = await rootBundle.load('lib/Assets/Img/firma_otrapersona.png');
        firmaFinal = firmaData.buffer.asUint8List();
      }
    }


    final titulo = widget.tipo == TipoRecibo.Ingreso
        ? 'RECIBO DE INGRESO'
        : 'RECIBO DE EGRESO';

    // Texto que cambia según tipo
    final pagadoTexto = widget.tipo == TipoRecibo.Ingreso ? 'Pagado por:' : 'Pagado a:';

    // Valor mostrado en PDF: siempre positivo
    final valorMostrado = widget.valor.startsWith('-') ? widget.valor.substring(1) : widget.valor;

    // --- Helpers para PDF ---
    pw.Widget _campoPdf(String titulo, String valor) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: pw.PdfColors.blue900,
            ),
          ),
          pw.Container(height: 1, color: pw.PdfColors.blue900),
          pw.SizedBox(height: 3),
          pw.Text(valor, style: pw.TextStyle(font: ttf, fontSize: 12)),
        ],
      );
    }

    pw.Widget _filaDoblePdf({
      required String titulo1,
      required String valor1,
      required String titulo2,
      required String valor2,
    }) {
      return pw.Row(
        children: [
          pw.Expanded(child: _campoPdf(titulo1, valor1)),
          pw.SizedBox(width: 15),
          pw.Expanded(child: _campoPdf(titulo2, valor2)),
        ],
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pw.PdfPageFormat(400, 530, marginLeft: 15, marginRight: 15, marginTop: 5),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo
              pw.Center(child: pw.Image(pw.MemoryImage(logoBytes), width: 140, height: 100)),
              pw.SizedBox(height: 13),
              // Título
              pw.Center(
                  child: pw.Text(titulo,
                      style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 5),
              // Número
              pw.Center(child: pw.Text('No. $numeroRecibo', style: pw.TextStyle(font: ttf, fontSize: 10))),
              pw.SizedBox(height: 15),

              // Ciudad | Fecha
              _filaDoblePdf(
                titulo1: 'Ciudad:',
                valor1: widget.ciudad,
                titulo2: 'Fecha:',
                valor2: widget.fecha,
              ),
              pw.SizedBox(height: 12),

              // Pagado por / a
              _campoPdf(pagadoTexto, widget.nombre),
              pw.SizedBox(height: 12),

              // Concepto
              _campoPdf('Por concepto de:', widget.concepto),
              pw.SizedBox(height: 12),

              // Valor | En letras
              _filaDoblePdf(
                titulo1: 'Valor:',
                valor1: '\$$valorMostrado',
                titulo2: 'En letras:',
                valor2: '${widget.valorTexto} COP',
              ),
              pw.SizedBox(height: 15),

              // Firma y sello
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Image(pw.MemoryImage(firmaFinal), width: 180, height: 80),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      widget.tipo == TipoRecibo.Ingreso ? 'Sello digital válido' : 'Firma del receptor',
                      style: pw.TextStyle(font: ttf, fontSize: 11),
                    ),
                    pw.Text(
                      'Documento generado electrónicamente',
                      style: pw.TextStyle(font: ttf, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // ======== GUARDAR RECIBO ========
  Future<void> _guardarRecibo() async {
    final pdf = await _crearPdf();
    final pdfBytes = await pdf.save();
    final fileName =
        '${widget.tipo == TipoRecibo.Ingreso ? 'ReciboIngreso' : 'ReciboEgreso'}_${numeroRecibo}_${widget.fecha.replaceAll('/', '-')}.pdf';

    // ===== Guardar en almacenamiento interno de la app =====
    final valorGuardado = widget.tipo == TipoRecibo.Egreso ? '-${widget.valor}' : widget.valor;
    await FacturaStorage.guardarArchivo(
      Factura(
        numero: numeroRecibo,
        ciudad: widget.ciudad,
        fecha: widget.fecha,
        nombre: widget.nombre,
        concepto: widget.concepto,
        valor: valorGuardado,
        valorTexto: widget.valorTexto,
        firma: widget.firma,
      ),
      widget.tipo == TipoRecibo.Ingreso ? 'Ingreso' : 'Egreso',
    );

    // ===== Compartir PDF (opcional) =====
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);

    // ===== Guardar también en Descargas si es Windows =====
    if (Platform.isWindows) {
      try {
        final downloadsDir = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
        if (!downloadsDir.existsSync()) downloadsDir.createSync(recursive: true);

        final filePath = '${downloadsDir.path}\\$fileName';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recibo guardado en la app y en: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recibo guardado en la app, pero no se pudo guardar en Descargas: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Android/iOS solo app
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.tipo == TipoRecibo.Ingreso ? 'Recibo de ingreso' : 'Recibo de egreso'} guardado correctamente en la app',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ======== ENVIAR PDF ========
  Future<void> _enviarPdf() async {
    final pdf = await _crearPdf();
    final fileName =
        '${widget.tipo == TipoRecibo.Ingreso ? 'ReciboIngreso' : 'ReciboEgreso'}_${numeroRecibo}_${widget.fecha.replaceAll('/', '-')}.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
  }

  // ======== IMPRIMIR PDF ========
  Future<void> _imprimirPdf() async {
    final pdf = await _crearPdf();
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final tipoTexto = widget.tipo == TipoRecibo.Ingreso ? 'INGRESO' : 'EGRESO';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECIBO DE $tipoTexto DIGITAL', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        FacturaRow(
          title: 'Empresa:',
          value: widget.empresa == SeleccionEmpresa.Latinoandes
              ? 'LATINOANDES'
              : 'KALEYMAN',
        ),
        const SizedBox(height: 15),
        FacturaRow(title: 'Recibo No:', value: numeroRecibo),
        const Divider(),
        FacturaRow(title: 'Ciudad:', value: widget.ciudad),
        const SizedBox(height: 15),
        FacturaRow(title: 'Fecha:', value: widget.fecha),
        const SizedBox(height: 15),
        FacturaRow(title: 'Nombre:', value: widget.nombre),
        const SizedBox(height: 15),
        FacturaRow(title: 'Concepto:', value: widget.concepto),
        const SizedBox(height: 15),
        FacturaRow(title: 'Valor:', value: '\$${widget.valor}'),
        const SizedBox(height: 15),
        FacturaRow(title: 'En letras:', value: widget.valorTexto),
        const SizedBox(height: 25),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(onPressed: _guardarRecibo, child: Text(Platform.isWindows ? 'Descargar' : 'Guardar')),
            ]),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(onPressed: _enviarPdf, child: const Text('Ver/Enviar')),
              const SizedBox(width: 20),
              ElevatedButton(onPressed: _imprimirPdf, child: const Text('Imprimir')),
            ]),
            const Divider(height: 40),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: widget.onEditar, child: const Text('Crear nuevo recibo')),
          ],
        ),
      ],
    );
  }
}
