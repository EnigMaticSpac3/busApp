// lib/screens/stop_detail_screen.dart
//
// Detalle de una parada: mini mapa + lista de buses con ETA real
// Adaptado de Transita V2 para busApp (backend real, sin favoritos).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../models/eta_parada_response.dart';
import '../theme/canal_colors.dart';
import '../theme/eta_utils.dart';
import '../widgets/live_badge.dart';
import '../widgets/connection_banner.dart';
import '../widgets/empty_state.dart';
import '../widgets/canal_vector_map.dart';

class StopDetailScreen extends StatefulWidget {
  final String paradaId;
  final String paradaNombre;
  final double lat;
  final double lon;

  const StopDetailScreen({
    super.key,
    required this.paradaId,
    required this.paradaNombre,
    required this.lat,
    required this.lon,
  });

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  late final ApiService _api;

  bool _loading = true;
  bool _offline = false;
  String? _error;
  List<BusEta> _buses = [];
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _cargarEta();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = context.read<ApiService>();
  }

  // ── Carga de datos ──────────────────────────────────────────────

  Future<void> _cargarEta() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _api.fetchEtaParada(widget.paradaId);
      if (!mounted) return;

      if (response == null) {
        setState(() {
          _offline = true;
          _loading = false;
        });
        return;
      }

      setState(() {
        _buses = response.buses;
        _lastUpdated = DateTime.now();
        _offline = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los datos. Intenta de nuevo.';
        _loading = false;
      });
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────

  /// Extrae el número de minutos del string ETA del backend (e.g. "3 min" → 3).
  int _parseEta(String etaStr) {
    final match = RegExp(r'(\d+)').firstMatch(etaStr);
    if (match != null) return int.parse(match.group(1)!);
    // Textos como "Llegando", "Menos de 1 min"
    return 0;
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final textSecondary =
        isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary;
    final textMuted =
        isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;

    return Scaffold(
      backgroundColor:
          isDark ? CanalColors.darkBackground : CanalColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            _buildHeader(isDark, textPrimary, textSecondary),

            // ── Mini mapa ──────────────────────────────────────────
            _buildMiniMap(isDark),

            // ── Próximos buses header ──────────────────────────────
            _buildBusesHeader(isDark, textPrimary, textMuted),

            // ── Offline banner ─────────────────────────────────────
            if (_offline)
              ConnectionBanner(
                lastUpdated: _lastUpdated != null
                    ? _formatTimeAgo(_lastUpdated!)
                    : 'desconocido',
                isDark: isDark,
                onRetry: _cargarEta,
              ),

            // ── Bus list ───────────────────────────────────────────
            Expanded(
              child: _buildBusList(isDark, textPrimary, textSecondary, textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────

  Widget _buildHeader(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  alignment: Alignment.center,
                  child: Icon(Icons.arrow_back_rounded, color: textPrimary),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          // Parada info
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CanalColors.primary,
                  border: Border.all(
                    color: isDark ? CanalColors.darkSurface : CanalColors.lightSurface,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.paradaNombre,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Parada ${widget.paradaId}',
                      style: TextStyle(fontSize: 13, color: textSecondary),
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

  // ── Mini mapa ─────────────────────────────────────────────────────

  Widget _buildMiniMap(bool isDark) {
    final stopPoint = LatLng(widget.lat, widget.lon);

    return SizedBox(
      height: 130,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CanalVectorMap(
          isDark: isDark,
          initialCenter: stopPoint,
          initialZoom: 15,
          children: [
            MarkerLayer(
              markers: [
                Marker(
                  point: stopPoint,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: CanalColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CanalColors.lightSurface,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_bus_rounded,
                          size: 10,
                          color: CanalColors.lightSurface,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          widget.paradaNombre,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: CanalColors.lightSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Buses header ──────────────────────────────────────────────────

  Widget _buildBusesHeader(bool isDark, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Próximos buses',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const Spacer(),
          if (_lastUpdated != null)
            Text(
              'Actualizado ${_formatTimeAgo(_lastUpdated!)}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: textMuted,
              ),
            ),
        ],
      ),
    );
  }

  // ── Bus list ──────────────────────────────────────────────────────

  Widget _buildBusList(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _cargarEta,
      );
    }

    if (_buses.isEmpty) {
      return EmptyState(
        icon: Icons.directions_bus_outlined,
        message: 'Sin buses programados para esta parada en este momento.',
        actionLabel: 'Reintentar',
        onAction: _cargarEta,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _buses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _buildBusCard(
        _buses[i],
        isDark,
        textPrimary,
        textSecondary,
        textMuted,
      ),
    );
  }

  // ── Bus card ──────────────────────────────────────────────────────

  Widget _buildBusCard(
    BusEta bus,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final etaNum = _parseEta(bus.eta);
    final etaCol = etaColor(etaNum);

    // Determinar si el bus está "en vivo" (eta bajo = probablemente GPS real)
    // o "programado" (eta alto = probablemente horario)
    final isLive = etaNum <= 15;

    return GestureDetector(
      onTap: () {},
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
            // ── Route badge ──
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CanalColors.routeColorForCode(bus.rutaCodigo),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  bus.rutaCodigo,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: CanalColors.routeTextColor(bus.rutaCodigo, isDark: isDark),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bus.rutaCodigo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLive)
                        LiveBadge(isDark: isDark)
                      else
                        ProgramadoBadge(isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Llegada en ',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      Text(
                        bus.eta,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: etaCol,
                        ),
                      ),
                      if (bus.distancia > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.place_outlined, size: 12, color: textMuted),
                        const SizedBox(width: 3),
                        Text(
                          _formatDistancia(bus.distancia),
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── Big ETA ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$etaNum',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: etaCol,
                  ),
                ),
                Text(
                  'min',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de formato ────────────────────────────────────────────

  String _formatDistancia(double metros) {
    if (metros < 1000) return '${metros.round()}m';
    return '${(metros / 1000).toStringAsFixed(1)}km';
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    return 'hace ${diff.inHours}h';
  }
}
