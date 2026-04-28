// Conditional export — picks the platform-specific implementation of
// ZadPlantUmlView / ZadPlantUmlController. Mirrors the Mermaid view pair
// so the rest of the app stays platform-agnostic.
export 'zad_plantuml_view_mobile.dart'
    if (dart.library.html) 'zad_plantuml_view_web.dart';
