import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/canal_colors.dart';
import '../theme/living_theme.dart';
import '../theme/favorites_provider.dart';
import '../theme/notifications_provider.dart';
import '../theme/settings_service.dart';
import '../theme/offline_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? CanalColors.darkTextPrimary
        : CanalColors.lightTextPrimary;
    final textSecondary = isDark
        ? CanalColors.darkTextSecondary
        : CanalColors.lightTextSecondary;
    final textMuted = isDark
        ? CanalColors.darkTextMuted
        : CanalColors.lightTextMuted;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Perfil',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader('Ajustes', textMuted),
            _buildThemeToggle(context, isDark),
            _buildCitymapperToggle(context, isDark),
            const SizedBox(height: 4),
            _buildInfoTile(
              'Tema actual',
              context.watch<LivingTheme>().momentLabel,
              context.watch<LivingTheme>().momentIcon,
              textPrimary,
              textSecondary,
            ),
            _buildInfoTile(
              'Versión',
              '1.0.0',
              Icons.info_outline_rounded,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Pantalla', textMuted),
            _buildSearchAlignmentSetting(context, isDark),
            const SizedBox(height: 24),
            _buildSectionHeader('Desarrollo', textMuted),
            _buildOfflineToggle(context, isDark),
            const SizedBox(height: 12),
            const SizedBox.shrink(),
            const SizedBox(height: 24),
            Consumer<FavoritesProvider>(
              builder: (_, favs, _) {
                final hasRoutes = favs.favoriteRoutes.isNotEmpty;
                final hasStops = favs.favoriteStops.isNotEmpty;
                if (!hasRoutes && !hasStops) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Guardados', textMuted),
                    if (hasRoutes) ...[
                      _buildSubHeader('Rutas', textMuted),
                      ...favs.favoriteRoutes.map(
                        (r) => _buildFavRouteItem(context, r, isDark),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (hasStops) ...[
                      _buildSubHeader('Paradas', textMuted),
                      ...favs.favoriteStops.map(
                        (s) => _buildFavStopItem(context, s, isDark),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            Consumer<NotificationsProvider>(
              builder: (_, notifs, _) {
                final items = notifs.items;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSectionHeader('Alertas', textMuted),
                        const Spacer(),
                        if (items.any((n) => !n.read))
                          GestureDetector(
                            onTap: () => notifs.markAllAsRead(),
                            child: Text(
                              'Leer todas',
                              style: TextStyle(
                                fontSize: 12,
                                color: CanalColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 32,
                                color: textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sin alertas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...items.map(
                        (n) => _buildNotificationItem(
                          n,
                          isDark,
                          textPrimary,
                          textSecondary,
                          textMuted,
                          notifs,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Modo Conductor', textMuted),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/conductor-login'),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
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
                      child: Icon(
                        Icons.directions_bus_rounded,
                        size: 20,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Eres conductor?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Activa el modo conductor para contribuir GPS',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Comunidad', textMuted),
            _buildCommunityCard(
              context,
              isDark,
              textPrimary,
              textSecondary,
              textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    return Container(
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
                  color: CanalColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  size: 20,
                  color: CanalColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ayudaste a 42 pasajeros este mes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Top 3 de tu línea (K480)',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CanalColors.liveGreen,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '4 viajes aportados · 96% de precisión',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _showRedeemSheet(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: CanalColors.secondary,
                side: BorderSide(
                  color: CanalColors.secondary.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Canjear B/.0.25 por crédito A2-20 o Yappy',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRedeemSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? CanalColors.darkSurface
          : CanalColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final tp = dark
            ? CanalColors.darkTextPrimary
            : CanalColors.lightTextPrimary;
        final ts = dark
            ? CanalColors.darkTextSecondary
            : CanalColors.lightTextSecondary;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canjear tu aporte',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tp,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Has contribuido 12 ETA este mes. Elige cómo recibir tu incentivo (demo):',
                  style: TextStyle(fontSize: 13, height: 1.5, color: ts),
                ),
                const SizedBox(height: 14),
                _redeemOption(
                  ctx,
                  Icons.credit_card_rounded,
                  'Crédito A2-20',
                  'B/.0.25 · se acredita al próximo viaje',
                ),
                const SizedBox(height: 8),
                _redeemOption(
                  ctx,
                  Icons.bolt_rounded,
                  'Yappy',
                  'B/.0.25 · transferencia inmediata',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _redeemOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tp = dark
        ? CanalColors.darkTextPrimary
        : CanalColors.lightTextPrimary;
    final ts = dark
        ? CanalColors.darkTextSecondary
        : CanalColors.lightTextSecondary;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title solicitado (demo)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: CanalColors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark
              ? CanalColors.darkBackground
              : CanalColors.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dark ? CanalColors.darkBorder : CanalColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CanalColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: CanalColors.secondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tp,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: ts)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: ts),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: textMuted,
        ),
      ),
    );
  }

  Widget _buildSearchAlignmentSetting(BuildContext context, bool isDark) {
    final settings = context.watch<SettingsService>();
    final current = settings.searchAlignment;
    final textPrimary = isDark
        ? CanalColors.darkTextPrimary
        : CanalColors.lightTextPrimary;
    final textSecondary = isDark
        ? CanalColors.darkTextSecondary
        : CanalColors.lightTextSecondary;

    return Container(
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
                  Icons.swap_horiz_rounded,
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
                      'Posición de búsqueda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Acomoda la barra a tu preferencia',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: SearchAlignment.values.map((alignment) {
              final isSelected = current == alignment;
              final label = switch (alignment) {
                SearchAlignment.left => 'Izquierda',
                SearchAlignment.center => 'Centro',
                SearchAlignment.right => 'Derecha',
              };
              return Expanded(
                child: GestureDetector(
                  onTap: () => settings.setSearchAlignment(alignment),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CanalColors.primary.withValues(alpha: 0.12)
                          : (isDark
                                ? CanalColors.darkBackground
                                : CanalColors.lightBackground),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? CanalColors.primary
                            : (isDark
                                  ? CanalColors.darkBorder
                                  : CanalColors.lightBorder),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? CanalColors.primary : textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineToggle(BuildContext context, bool isDark) {
    final offline = context.watch<OfflineProvider>();
    final textPrimary = isDark
        ? CanalColors.darkTextPrimary
        : CanalColors.lightTextPrimary;
    final textSecondary = isDark
        ? CanalColors.darkTextSecondary
        : CanalColors.lightTextSecondary;

    return Container(
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
              color: CanalColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              offline.offline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
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
                  'Modo sin conexión',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  offline.offline ? 'Demo: mostrando datos offline' : 'Demo: datos en vivo',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: offline.offline,
            activeTrackColor: CanalColors.accent,
            onChanged: (_) => offline.toggle(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(String label, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textMuted,
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, bool isDark) {
    final livingTheme = context.watch<LivingTheme>();

    return Container(
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
    );
  }

  Widget _buildCitymapperToggle(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 2),
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
                  color: CanalColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.explore_rounded,
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
                      'Experiencia Transita V2',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? CanalColors.darkTextPrimary
                            : CanalColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Mapa en vivo · rutas · progreso del viaje',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? CanalColors.darkTextSecondary
                            : CanalColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textSecondary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 14, color: textPrimary)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFavRouteItem(BuildContext context, String code, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CanalColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
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
    );
  }

  Widget _buildFavStopItem(BuildContext context, String name, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 16,
            color: CanalColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? CanalColors.darkTextPrimary
                    : CanalColors.lightTextPrimary,
              ),
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
    );
  }

  Widget _buildNotificationItem(
    NotificationItem item,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    NotificationsProvider notifs,
  ) {
    final iconColor = item.type == 'disruption'
        ? CanalColors.error
        : (item.type == 'arrival'
              ? CanalColors.secondary
              : CanalColors.primary);

    return GestureDetector(
      onTap: () => notifs.markAsRead(item.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: item.read
              ? (isDark ? CanalColors.darkSurface : CanalColors.lightSurface)
              : (isDark
                    ? CanalColors.darkSurface
                    : CanalColors.lightBackground),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.type == 'disruption'
                    ? Icons.warning_rounded
                    : Icons.notifications_rounded,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: item.read ? FontWeight.w500 : FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(item.time),
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }
}
