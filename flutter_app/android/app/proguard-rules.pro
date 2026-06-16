# ML Kit Text Recognition: solo usamos el script latino. El plugin referencia
# los reconocedores de otros idiomas (chino, japonés, coreano, devanagari) que
# no incluimos; le decimos a R8 que ignore esas clases ausentes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
