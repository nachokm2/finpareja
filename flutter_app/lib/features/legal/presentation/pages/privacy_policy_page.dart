import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';

/// Política de privacidad de FinPareja.
///
/// Cumple con la Ley 19.628 sobre Protección de la Vida Privada (Chile):
/// identifica al responsable, los datos tratados, su finalidad, el plazo de
/// conservación y los derechos ARCO del titular (acceso, rectificación,
/// cancelación y oposición).
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _ultimaActualizacion = '15 de junio de 2026';
  static const _contacto = 'privacidad@finpareja.cl';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Política de privacidad')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Última actualización: $_ultimaActualizacion',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(height: 16),
              _Section(
                titulo: '1. Quiénes somos',
                cuerpo:
                    'FinPareja es una aplicación de gestión financiera personal y '
                    'compartida. Somos responsables del tratamiento de tus datos '
                    'personales conforme a la Ley 19.628 sobre Protección de la '
                    'Vida Privada.',
              ),
              _Section(
                titulo: '2. Qué datos recolectamos',
                cuerpo:
                    '• Datos de cuenta: nombre, correo electrónico y, opcionalmente, '
                    'teléfono.\n'
                    '• Datos financieros que tú ingresas: transacciones, '
                    'presupuestos, metas, deudas e inversiones.\n'
                    '• Datos técnicos mínimos para seguridad: fecha y origen de '
                    'inicio de sesión.\n\n'
                    'No solicitamos ni almacenamos credenciales de tus bancos.',
              ),
              _Section(
                titulo: '3. Para qué usamos tus datos',
                cuerpo:
                    'Usamos tus datos únicamente para entregarte el servicio: '
                    'calcular balances, dividir gastos con tu pareja, mostrar '
                    'reportes y enviarte alertas de presupuesto. No vendemos ni '
                    'cedemos tus datos a terceros con fines publicitarios.',
              ),
              _Section(
                titulo: '4. Cómo protegemos tu información',
                cuerpo:
                    'Tus contraseñas se almacenan cifradas (hash) y nunca en texto '
                    'plano. La comunicación con nuestros servidores viaja cifrada '
                    '(HTTPS). Las acciones sensibles quedan en un registro de '
                    'auditoría inmutable para tu seguridad.',
              ),
              _Section(
                titulo: '5. Por cuánto tiempo conservamos tus datos',
                cuerpo:
                    'Conservamos tus datos mientras tu cuenta esté activa. Si '
                    'solicitas la eliminación de tu cuenta, borramos tus datos '
                    'personales salvo aquellos que debamos conservar por '
                    'obligación legal.',
              ),
              _Section(
                titulo: '6. Tus derechos (ARCO)',
                cuerpo:
                    'Tienes derecho a Acceder, Rectificar, Cancelar (eliminar) y '
                    'Oponerte al tratamiento de tus datos personales. Para '
                    'ejercerlos, escríbenos a $_contacto y responderemos en los '
                    'plazos que establece la ley.',
              ),
              _Section(
                titulo: '7. Contacto',
                cuerpo:
                    'Ante cualquier duda sobre esta política o el tratamiento de '
                    'tus datos, contáctanos en $_contacto.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.titulo, required this.cuerpo});

  final String titulo;
  final String cuerpo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cuerpo,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
