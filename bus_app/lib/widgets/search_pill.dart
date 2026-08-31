import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';

/// Search pill flotante sobre el mapa (§07 enmienda v2.0.1 · reporte §2F).
/// Altura 52px (>=48dp §10), radius r-full, shadow-search. Lupa + placeholder
/// "¿A dónde vas?" o viaje dinámico "origen → destino". Acción secundaria
/// `tune` (filtros) con hit-area >=48dp + Semantics.
class SearchPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onFilter;
  final bool isDark;

  const SearchPill({
    super.key,
    required this.label,
    required this.onTap,
    required this.onFilter,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.14);
    final shadow = isDark
        ? const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))]
        : const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))];

    return Material(
      color: surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        borderRadius: BorderRadius.circular(9999),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.fromLTRB(20, 0, 4, 0),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: shadow,
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: textMuted,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Filtros y preferencias',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onFilter,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: Icon(Icons.tune_rounded, size: 20, color: textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
