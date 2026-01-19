import 'package:flutter/material.dart';
import 'package:flutter_facturacion_sistema/Assets/Models/factura_model.dart';
import 'package:flutter_facturacion_sistema/Storage/factura_storage.dart' hide Factura;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ArchivosScreen extends StatefulWidget {
  const ArchivosScreen({super.key});

  @override
  State<ArchivosScreen> createState() => _ArchivosScreenState();
}

class _ArchivosScreenState extends State<ArchivosScreen> {
  List<Factura> archivos = [];
  List<Factura> archivosFiltrados = [];
  String carpetaSeleccionada = 'Ingreso';

  final List<String> carpetas = ['Ingreso', 'Egreso', 'Facturas'];

  @override
  void initState() {
    super.initState();
    _cargarArchivos();
  }

  Future<void> _cargarArchivos() async {
    // Dependiendo de la carpeta seleccionada, se obtienen los archivos
    List<Factura> data;
    if (carpetaSeleccionada == 'Ingreso') {
      data = await FacturaStorage.obtenerRecibosIngreso();
    } else if (carpetaSeleccionada == 'Egreso') {
      data = await FacturaStorage.obtenerRecibosEgreso();
    } else {
      data = await FacturaStorage.obtenerFacturas();
    }

    setState(() {
      archivos = data;
      archivosFiltrados = data;
    });
  }

  void _buscar(String query) {
    setState(() {
      archivosFiltrados = archivos
          .where((f) => f.numero.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

    Future<void> _abrirArchivo(Factura archivo) async {
    final pdf = pw.Document();
  
    final ttf = pw.Font.ttf(
      await rootBundle.load('lib/Assets/Fonts/Roboto-Regular.ttf'),
    );
  
    final logoBytesData =
        await rootBundle.load('lib/Assets/Img/logo.png');
    final Uint8List logoBytes = logoBytesData.buffer.asUint8List();
  
    // ====== FIRMA ======
    Uint8List firmaFinal;
    if (archivo.firma != null) {
      firmaFinal = archivo.firma!; // Usar la firma guardada
    } else {
      // Por defecto
      final ByteData firmaData =
          await rootBundle.load('lib/Assets/Img/firma.png');
      firmaFinal = firmaData.buffer.asUint8List();
    }

  
    // ====== VALOR POSITIVO ======
    final valorMostrado = archivo.valor.startsWith('-')
        ? archivo.valor.substring(1)
        : archivo.valor;
  
    late final String titulo;

    if (carpetaSeleccionada == 'Ingreso') {
      titulo = 'RECIBO DE INGRESO DIGITAL';
    } else if (carpetaSeleccionada == 'Egreso') {
      titulo = 'RECIBO DE EGRESO DIGITAL';
    } else {
      titulo = 'FACTURA DIGITAL';
    }
  
    final pagadoTexto = carpetaSeleccionada == 'Egreso'
        ? 'Pagado a:'
        : 'Pagado por:';
  
    pdf.addPage(
    pw.Page(
      pageFormat: pw.PdfPageFormat(450, 550, marginAll: 10),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 10),
            // Logo
            pw.Center(
              child: pw.Image(pw.MemoryImage(logoBytes), width: 140, height: 100),
            ),
            pw.SizedBox(height: 10),
            // Título
            pw.Center(
              child: pw.Text(
                titulo,
                style: pw.TextStyle(
                    font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            // Número de archivo
            pw.Center(
              child: pw.Text(
                'No. ${archivo.numero}',
                style: pw.TextStyle(font: ttf, fontSize: 15),
              ),
            ),
            pw.SizedBox(height: 15),
  
            // Primera fila: Ciudad | Fecha
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Ciudad:',
                        style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900),
                      ),
                      pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 2),
                        height: 1,
                        color: PdfColors.blue900,
                      ),
                      pw.Text(archivo.ciudad, style: pw.TextStyle(font: ttf, fontSize: 12)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Fecha:',
                        style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900),
                      ),
                      pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 2),
                        height: 1,
                        color: PdfColors.blue900,
                      ),
                      pw.Text(archivo.fecha, style: pw.TextStyle(font: ttf, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
  
            // Segunda fila: Pagado por
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  pagadoTexto,
                  style: pw.TextStyle(
                      font: ttf,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900),
                ),
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 2),
                  height: 1,
                  color: PdfColors.blue900,
                ),
                pw.Text(archivo.nombre, style: pw.TextStyle(font: ttf, fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 10),
  
            // Tercera fila: Por concepto
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Por concepto de:',
                  style: pw.TextStyle(
                      font: ttf,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900),
                ),
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 2),
                  height: 1,
                  color: PdfColors.blue900,
                ),
                pw.Text(archivo.concepto, style: pw.TextStyle(font: ttf, fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 10),
  
            // Cuarta fila: Valor | En letras
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Valor:',
                        style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900),
                      ),
                      pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 2),
                        height: 1,
                        color: PdfColors.blue900,
                      ),
                      pw.Text('\$$valorMostrado', style: pw.TextStyle(font: ttf, fontSize: 12)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'En letras:',
                        style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900),
                      ),
                      pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 2),
                        height: 1,
                        color: PdfColors.blue900,
                      ),
                      pw.Text('${archivo.valorTexto} COP',
                          style: pw.TextStyle(font: ttf, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
  
            // Firma y sello
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Image(pw.MemoryImage(firmaFinal), width: 200, height: 100),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    carpetaSeleccionada == 'Egreso'
                        ? 'Firma del receptor'
                        : 'Sello digital válido',
                    style: pw.TextStyle(
                        font: ttf, fontSize: 10, color: PdfColors.blue900),
                  ),
                  pw.Text(
                    'Documento generado electrónicamente',
                    style: pw.TextStyle(
                        font: ttf, fontSize: 10, color: PdfColors.blue900),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );


  
    final fileName =
        '${carpetaSeleccionada}_${archivo.numero}_${archivo.fecha.replaceAll('/', '-')}.pdf';
  
    await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
  }


  pw.Widget _buildRowPdf(String title, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(title,
                style:
                    pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _confirmarBorrar(Factura archivo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Borrar ${carpetaSeleccionada}'),
          content: Text(
              '¿Estás seguro de que quieres borrar ${archivo.numero}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FacturaStorage.borrarArchivo(
                    archivo.numero, carpetaSeleccionada);
                Navigator.of(context).pop();
                _cargarArchivos();
              },
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
        title: const Text('Archivos'),
      ),
      body: Column(
        children: [
          // Selector de carpeta
          Padding(
            padding: const EdgeInsets.all(10),
            child: DropdownButtonFormField<String>(
              value: carpetaSeleccionada,
              items: carpetas
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    carpetaSeleccionada = value;
                  });
                  _cargarArchivos();
                }
              },
              decoration: const InputDecoration(
                labelText: 'Seleccionar carpeta',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Buscador
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por número',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _buscar,
            ),
          ),
          // Lista de archivos
          Expanded(
            child: ListView.builder(
              itemCount: archivosFiltrados.length,
              itemBuilder: (_, index) {
                final archivo = archivosFiltrados[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Slidable(
                    key: Key(archivo.numero),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) => _confirmarBorrar(archivo),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Borrar',
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                    child: Card(
                      child: ListTile(
                        title: Text(archivo.numero),
                        subtitle: Text('${archivo.nombre} • ${archivo.fecha}'),
                        trailing: Text('\$${archivo.valor}'),
                        onTap: () => _abrirArchivo(archivo),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}