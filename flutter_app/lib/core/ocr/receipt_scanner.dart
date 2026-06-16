import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Datos extraídos de una boleta. Cualquier campo puede ser null si no se pudo
/// detectar; el usuario siempre revisa/corrige antes de guardar.
class ReceiptData {
  const ReceiptData({
    this.monto,
    this.fecha,
    this.comercio,
    this.candidates = const [],
    required this.rawText,
  });

  final double? monto; // mejor estimación del total
  final DateTime? fecha;
  final String? comercio;
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
      candidates: _allAmounts(text),
      rawText: text,
    );
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
  // Heurística simple: la primera línea "con sentido" (letras, sin ser un
  // encabezado de monto/fecha) suele ser el nombre del local.
  String? _findMerchant(List<String> lines) {
    for (final line in lines.take(5)) {
      final letras = line.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚáéíóúÑñ ]'), '').trim();
      if (letras.length >= 3 &&
          !line.toUpperCase().contains('BOLETA') &&
          !line.toUpperCase().contains('FACTURA')) {
        // Limita el largo para que sea una descripción razonable.
        return letras.length > 40 ? letras.substring(0, 40) : letras;
      }
    }
    return null;
  }
}
