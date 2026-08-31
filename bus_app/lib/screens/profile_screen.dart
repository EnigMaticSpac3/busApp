import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/canal_colors.dart';
import '../theme/living_theme.dart';

/// Pantalla de perfil simplificada para BusApp.
///
/// Diseñada para integrarse dentro del DraggableScrollableSheet
/// en HomeScreen (tab "Perfil"). Solo depende de [LivingTheme]
/// — sin providers complejos como Transita V2.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final textSecondary =
        isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary;
    final textMuted =
        isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        // ── Título ──
        Semantics(
          header: true,
          child: Text(
            'Perfil',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Sección: Ajustes ──
        _SectionHeader(label: 'Ajustes', color: textMuted),
        _buildThemeToggle(context, isDark),
        const SizedBox(height: 4),
        _InfoTile(
          label: 'Tema actual',
          value: context.watch<LivingTheme>().momentLabel,
          icon: context.watch<LivingTheme>().momentIcon,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        _InfoTile(
          label: 'Versión',
          value: '1.0.0',
          icon: Icons.info_outline_rounded,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 24),

        // ── Sección: Conductor ──
        _SectionHeader(label: 'Conductor', color: textMuted),
        _buildDriverAccess(context, isDark, textPrimary, textSecondary),
        const SizedBox(height: 24),

        // ── Sección: Acerca de ──
        _SectionHeader(label: 'Acerca de', color: textMuted),
        _buildAboutSection(context, isDark, textPrimary, textSecondary),
      ],
    );
  }

  // ── Theme Toggle ──

  Widget _buildThemeToggle(BuildContext context, bool isDark) {
    final livingTheme = context.watch<LivingTheme>();

    return Semantics(
      label: 'Cambiar tema: ${isDark ? "modo oscuro activado" : "modo claro activado"}',
      button: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CanalColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 20,
                color: CanalColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDark ? 'Modo oscuro' : 'Modo claro',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CanalColors.darkTextPrimary
                          : CanalColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    livingTheme.isManualOverride
                        ? 'Tema manual'
                        : 'Tema automático según hora',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: isDark
                          ? CanalColors.darkTextSecondary
                          : CanalColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              activeTrackColor: CanalColors.accent,
              onChanged: (_) => livingTheme.toggleDarkMode(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Driver Access ──

  Widget _buildDriverAccess(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Semantics(
      label: 'Acceso conductor: ingresa PIN para activar modo conductor',
      button: true,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/conductor-login'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CanalColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  size: 20,
                  color: CanalColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acceso Conductor',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Ingresa tu PIN para activar el modo GPS en tiempo real',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: isDark
                    ? CanalColors.darkTextMuted
                    : CanalColors.lightTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── About Section ──

  Widget _buildAboutSection(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Semantics(
      container: true,
      label: 'Acerca de San Antonio Bus Tracker',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CanalColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    size: 20,
                    color: CanalColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'San Antonio Bus Tracker',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'E598 \u00B7 San Antonio, Panam\u00E1',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Inter',
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Rastreo de buses en tiempo real con GPS, '
              'contribuci\u00F3n colaborativa de ETA y '
              'mapa vectorial interactivo.',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                height: 1.5,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers privados ──

/// Encabezado de secci\u00F3n con label en small caps.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

/// Fila de informaci\u00F3n gen\u00E9rica (label + valor + icono).
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textSecondary),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                color: textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
