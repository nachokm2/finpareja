import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Datos extraídos de una boleta. Cualquier campo puede ser null si no se pudo
/// detectar; el usuario siempre revisa/corrige antes de guardar.
class ReceiptData {
  const ReceiptData({
    this.monto,
    this.fecha,
    this.comercio,
    this.categoriaSugerida,
    this.candidates = const [],
    required this.rawText,
  });

  final double? monto; // mejor estimación del total
  final DateTime? fecha;
  final String? comercio;
  final String? categoriaSugerida; // nombre de categoría sugerido por keywords
  final List<double> candidates; // todos los montos detectados (mayor a menor)
  final String rawText;

  bool get isEmpty => monto == null && fecha == null && comercio == null;
}

/// Escanea una boleta con la cámara y extrae los datos con OCR on-device
/// (Google ML Kit). No requiere internet ni credenciales.
class ReceiptScanner {
  /// Toma una foto con la cámara y devuelve los datos detectados.
  /// Devuelve null si el usuario cancela la cámara.
  Future<ReceiptData?> scanFromCamera() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (file == null) return null;
    return _process(file.path);
  }

  /// Variante desde galería (por si la boleta ya está fotografiada).
  Future<ReceiptData?> scanFromGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return null;
    return _process(file.path);
  }

  Future<ReceiptData> _process(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      return _parse(result.text);
    } finally {
      await recognizer.close();
    }
  }

  ReceiptData _parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return ReceiptData(
      monto: _findTotal(lines, text),
      fecha: _findDate(text),
      comercio: _findMerchant(lines),
      categoriaSugerida: _suggestCategory(text),
      candidates: _allAmounts(text),
      rawText: text,
    );
  }

  // ── Categoría sugerida ───────────────────────────────────────────────────
  // Mapea palabras clave del texto a una categoría de gasto del sistema.
  // El orden importa: la primera coincidencia gana.
  static const Map<String, List<String>> _categoryKeywords = {
    'Restaurantes': [
      'pasteler', 'panaderia', 'cafe', 'cafeteria', 'restaurant', 'sushi',
      'pizza', 'burger', 'mcdonald', 'kfc', 'doggis', 'heladeria', 'comida',
    ],
    'Alimentación': [
      'supermercado', 'jumbo', 'lider', 'tottus', 'unimarc', 'santa isabel',
      'acuenta', 'mayorista', 'almacen', 'minimarket', 'verduleria', 'carniceria',
    ],
    'Transporte': [
      'bencina', 'combustible', 'copec', 'shell', 'petrobras', 'aramco',
      'estacionamiento', 'parking', 'uber', 'cabify', 'didi', 'peaje',
      'autopista', 'automotriz', 'neumatico', 'lubricentro',
    ],
    'Salud': [
      'farmacia', 'cruz verde', 'salcobrand', 'ahumada', 'clinica', 'hospital',
      'dental', 'dentista', 'optica', 'laboratorio',
    ],
    'Servicios básicos': [
      'enel', 'cge', 'aguas andinas', 'movistar', 'entel', 'claro', 'vtr',
      'internet',
    ],
    'Tecnología': ['pc factory', 'spdigital', 'computacion', 'electronica'],
    'Ropa y calzado': [
      'falabella', 'ripley', 'hites', 'calzado', 'zapatos', 'vestuario', 'zara',
    ],
    'Entretenimiento': [
      'cine', 'cinemark', 'cinepolis', 'netflix', 'spotify', 'teatro',
    ],
    'Mascotas': ['veterinaria', 'mascota', 'petshop'],
    'Cuidado personal': ['peluqueria', 'barberia', 'spa', 'manicure'],
    'Deporte': ['gimnasio', 'sportlife', 'smartfit'],
    'Vivienda': ['sodimac', 'easy', 'construmart', 'ferreteria', 'homecenter'],
    'Viajes': ['latam', 'jetsmart', 'sky airline', 'hotel', 'hostal', 'turismo'],
  };

  String? _suggestCategory(String text) {
    final t = _normalize(text);
    for (final entry in _categoryKeywords.entries) {
      for (final kw in entry.value) {
        if (t.contains(kw)) return entry.key;
      }
    }
    return null;
  }

  /// Minúsculas sin acentos, para comparar palabras clave de forma robusta.
  String _normalize(String s) {
    s = s.toLowerCase();
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    for (var i = 0; i < from.length; i++) {
      s = s.replaceAll(from[i], to[i]);
    }
    return s;
  }

  // Monto "con formato de dinero": con signo $ o con separador de miles. Así NO
  // confundimos RUT, folios, números de tarjeta, comprobantes o AID con el total.
  static final RegExp _moneyRe =
      RegExp(r'\$\s?\d[\d.,]*|\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?');

  /// Montos con formato de dinero, de mayor a menor (para el selector manual).
  List<double> _allAmounts(String text) {
    final set = <double>{};
    for (final m in _moneyRe.allMatches(text)) {
      final v = _toAmount(m.group(0)!);
      if (v != null && v >= 100 && v <= 99999999) set.add(v);
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  // ── Monto ──────────────────────────────────────────────────────────────
  // Prioriza la línea TOTAL (no SUBTOTAL), luego MONTO. La palabra puede venir
  // cortada por el OCR (ej. "To tal"), por eso comparamos sin espacios. Si no
  // hay ninguna, usa el mayor monto con formato de dinero del documento.
  double? _findTotal(List<String> lines, String text) {
    double? fromTotal;
    double? fromMonto;
    for (final line in lines) {
      final norm = line.toUpperCase().replaceAll(' ', '');
      if (norm.contains('SUBTOTAL')) continue;
      if (norm.contains('TOTAL')) {
        final amt = _amountInKeywordLine(line);
        if (amt != null) fromTotal = amt; // el último TOTAL suele ser el final
      } else if (norm.contains('MONTO')) {
        final amt = _amountInKeywordLine(line);
        if (amt != null) fromMonto = amt;
      }
    }
    return fromTotal ?? fromMonto ?? _largestMoneyIn(text);
  }

  /// Monto en una línea con TOTAL/MONTO: primero con formato de dinero; si no
  /// hay, el mayor número de 3+ dígitos (la palabra clave ya da el contexto).
  double? _amountInKeywordLine(String line) {
    final money = _largestMoneyIn(line);
    if (money != null) return money;
    double? best;
    for (final m in RegExp(r'\d{3,}').allMatches(line)) {
      final v = double.tryParse(m.group(0)!);
      if (v != null && v >= 100 && (best == null || v > best)) best = v;
    }
    return best;
  }

  /// Mayor monto con formato de dinero ($ o separador de miles) del texto.
  double? _largestMoneyIn(String s) {
    double? best;
    for (final m in _moneyRe.allMatches(s)) {
      final v = _toAmount(m.group(0)!);
      if (v != null && v >= 100 && (best == null || v > best)) best = v;
    }
    return best;
  }

  /// Convierte un texto monetario chileno a número. En CLP el punto es separador
  /// de miles ("12.500" → 12500); la coma se trata como decimal si aparece.
  double? _toAmount(String raw) {
    var t = raw.replaceAll(RegExp(r'[^\d.,]'), '');
    if (t.isEmpty) return null;
    if (t.contains('.') && t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.'); // . miles, , decimales
    } else if (t.contains(',')) {
      t = t.replaceAll(',', '.');
    } else {
      t = t.replaceAll('.', ''); // solo puntos → miles
    }
    return double.tryParse(t);
  }

  // ── Fecha ──────────────────────────────────────────────────────────────
  DateTime? _findDate(String text) {
    final re = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})');
    final m = re.firstMatch(text);
    if (m == null) return null;
    final d = int.tryParse(m.group(1)!) ?? 1;
    final mo = int.tryParse(m.group(2)!) ?? 1;
    var y = int.tryParse(m.group(3)!) ?? DateTime.now().year;
    if (y < 100) y += 2000;
    if (d > 31 || mo > 12 || d < 1 || mo < 1) return null;
    try {
      final date = DateTime(y, mo, d);
      // Descarta fechas futuras improbables (error de lectura).
      if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) return null;
      return date;
    } catch (_) {
      return null;
    }
  }

  // ── Comercio ───────────────────────────────────────────────────────────
  // Toma la primera línea "con sentido" descartando marcas de terminal de pago
  // (Getnet/Transbank) y texto de encabezado (boleta, rut, total, dirección…).
  static const List<String> _merchantSkip = [
    'getnet', 'transbank', 'redcompra', 'red compra', 'boleta', 'factura',
    'valido', 'como', 'rut', 'iva', 'total', 'monto', 'subtotal', 'tarjeta',
    'visa', 'mastercard', 'debito', 'credito', 'aid', 'aprobacion',
    'comprobante', 'copia', 'comercio', 'cliente', 'fecha', 'hora', 'www',
    'http', 'giro', 'direccion',
  ];

  String? _findMerchant(List<String> lines) {
    for (final line in lines.take(8)) {
      final norm = _normalize(line);
      final letras =
          line.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚáéíóúÑñ ]'), '').trim();
      if (letras.length < 4) continue;
      if (_merchantSkip.any((k) => norm.contains(k))) continue;
      return letras.length > 40 ? letras.substring(0, 40) : letras;
    }
    return null;
  }
}
