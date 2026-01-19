class NumeroALetrasCO {
  static String convertir(int numero) {
    if (numero == 0) return 'cero';

    final unidades = [
      '',
      'uno',
      'dos',
      'tres',
      'cuatro',
      'cinco',
      'seis',
      'siete',
      'ocho',
      'nueve'
    ];

    final decenas = [
      '',
      'diez',
      'veinte',
      'treinta',
      'cuarenta',
      'cincuenta',
      'sesenta',
      'setenta',
      'ochenta',
      'noventa'
    ];

    final especiales = {
      11: 'once',
      12: 'doce',
      13: 'trece',
      14: 'catorce',
      15: 'quince',
      16: 'dieciséis',
      17: 'diecisiete',
      18: 'dieciocho',
      19: 'diecinueve',
    };

    final centenasTexto = {
      1: 'ciento',
      2: 'doscientos',
      3: 'trescientos',
      4: 'cuatrocientos',
      5: 'quinientos',
      6: 'seiscientos',
      7: 'setecientos',
      8: 'ochocientos',
      9: 'novecientos',
    };

    String texto = '';

    // MILLONES
    if (numero >= 1000000) {
      int millones = numero ~/ 1000000;
      texto += millones == 1
          ? 'un millón '
          : '${convertir(millones)} millones ';
      numero %= 1000000;
    }

    // MILES
    if (numero >= 1000) {
      int miles = numero ~/ 1000;
      texto += miles == 1
          ? 'mil '
          : '${convertir(miles)} mil ';
      numero %= 1000;
    }

    // CENTENAS
    if (numero >= 100) {
      int centenas = numero ~/ 100;
      texto += numero == 100
          ? 'cien '
          : '${centenasTexto[centenas]} ';
      numero %= 100;
    }

    // DECENAS ESPECIALES
    if (numero >= 11 && numero <= 19) {
      texto += '${especiales[numero]}';
      return texto.trim();
    }

    // DECENAS
    if (numero >= 10) {
      int dec = numero ~/ 10;
      int uni = numero % 10;
      texto += decenas[dec];
      if (uni > 0) texto += ' y ${unidades[uni]}';
      return texto.trim();
    }

    // UNIDADES
    if (numero > 0) {
      texto += unidades[numero];
    }

    return texto.trim();
  }
}
