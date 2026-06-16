package cl.finpareja.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (en vez de FlutterActivity) es requisito del plugin
// local_auth para mostrar el diálogo de biometría del sistema en Android.
class MainActivity: FlutterFragmentActivity()
