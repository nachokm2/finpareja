import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Datos extraídos de una boleta. Cualquier campo puede ser null si no se pudo
/// detectar; el usuario siempre revisa/corrige antes de guardar.
class ReceiptData {
  const ReceiptData({this.monto, this.fecha, this.comercio, required this.rawText});

  final double? monto;
  final DateTime? fecha;
  final String? comercio;
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
      rawText: text,
    );
  }

  // ── Monto ──────────────────────────────────────────────────────────────
  // Prioriza la línea que dice TOTAL (no SUBTOTAL); si no hay, toma el mayor
  // monto del documento (en una boleta el total suele ser el número más grande).
  double? _findTotal(List<String> lines, String text) {
    double? fromTotalLine;
    for (final line in lines) {
      final upper = line.toUpperCase();
      final esTotal = upper.contains('TOTAL') &&
          !upper.contains('SUBTOTAL') &&
          !upper.contains('SUB TOTAL');
      if (esTotal) {
        final amt = _largestAmountIn(line);
        if (amt != null) fromTotalLine = amt; // el último TOTAL suele ser el final
      }
    }
    if (fromTotalLine != null) return fromTotalLine;
    return _largestAmountIn(text);
  }

  /// Mayor monto encontrado en un texto. Ignora números muy pequeños (≤ 100)
  /// para no confundir cantidades, folios o RUT con el total.
  double? _largestAmountIn(String s) {
    final re = RegExp(r'\$?\s*\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d{4,}');
    double? best;
    for (final m in re.allMatches(s)) {
      final v = _toAmount(m.group(0)!);
      if (v != null && v > 100 && (best == null || v > best)) best = v;
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
