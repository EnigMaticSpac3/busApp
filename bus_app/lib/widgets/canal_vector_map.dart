import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../theme/canal_colors.dart';
import '../theme/canal_map_styles.dart';

/// Mapa base vectorial de Transita: tiles OpenMapTiles de OpenFreeMap
/// (sin API key, CORS abierto) renderizados en el dispositivo con un estilo
/// MapLibre propio en la paleta Canal (Day / Sunset).
///
/// Usa flutter_map_vector_tiles (compatible con flutter_map v8).
class CanalVectorMap extends StatefulWidget {
  const CanalVectorMap({
    super.key,
    required this.isDark,
    this.mapController,
    this.initialCenter = const LatLng(9.051, -79.447),
    this.initialZoom = 12.5,
    this.minZoom = 4,
    this.maxZoom = 18,
    this.children = const [],
    this.onMapEvent,
  });

  final bool isDark;
  final MapController? mapController;
  final LatLng initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final List<Widget> children;
  final void Function(MapEvent)? onMapEvent;

  static const _tileJsonUrl = 'https://tiles.openfreemap.org/planet';

  static const fallbackTileUrlTemplate =
      'https://tiles.openfreemap.org/planet/20260802_080001_pt/{z}/{x}/{y}.pbf';

  static const tileMaximumZoom = 14;

  @visibleForTesting
  static Future<String> resolveTileUrlTemplate({http.Client? client}) async {
    try {
      final ownsClient = client == null;
      final c = client ?? http.Client();
      try {
        final res = await c
            .get(Uri.parse(_tileJsonUrl))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final tiles = (data['tiles'] as List?)?.cast<String>();
          if (tiles != null && tiles.isNotEmpty) {
            return tiles.first;
          }
        }
      } finally {
        if (ownsClient) c.close();
      }
    } catch (_) {}
    return fallbackTileUrlTemplate;
  }

  @override
  State<CanalVectorMap> createState() => _CanalVectorMapState();
}

class _CanalVectorMapState extends State<CanalVectorMap> {
  String _tileUrlTemplate = CanalVectorMap.fallbackTileUrlTemplate;
  vt.Theme? _dayTheme;
  vt.Theme? _sunsetTheme;
  vt.TileProviders? _dayProviders;
  vt.TileProviders? _sunsetProviders;

  @override
  void initState() {
    super.initState();
    _resolveTileUrlTemplate();
  }

  void _buildThemes() {
    _dayTheme = _buildTheme(CanalMapStyles.day);
    _sunsetTheme = _buildTheme(CanalMapStyles.sunset);
    _dayProviders = _buildProviders();
    _sunsetProviders = _buildProviders();
  }

  vt.Theme _buildTheme(String rawJson) {
    final data = jsonDecode(rawJson) as Map<String, dynamic>;
    return vt.ThemeReader().read(data);
  }

  vt.TileProviders _buildProviders() {
    return vt.TileProviders({
      'openmaptiles': vt.NetworkVectorTileProvider(
        urlTemplate: _tileUrlTemplate,
        maximumZoom: CanalVectorMap.tileMaximumZoom,
      ),
    });
  }

  Future<void> _resolveTileUrlTemplate() async {
    final template = await CanalVectorMap.resolveTileUrlTemplate();
    if (!mounted || template == _tileUrlTemplate) return;
    setState(() {
      _tileUrlTemplate = template;
      _buildThemes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.isDark ? _sunsetTheme : _dayTheme;
    final providers = widget.isDark ? _sunsetProviders : _dayProviders;
    final placeholderColor = widget.isDark
        ? CanalColors.darkBackground
        : CanalColors.lightBackground;

    if (theme == null || providers == null) {
      return ColoredBox(color: placeholderColor);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: placeholderColor),
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: widget.minZoom,
            maxZoom: widget.maxZoom,
            onMapEvent: widget.onMapEvent,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
              rotationThreshold: 20.0,
            ),
          ),
          children: [
            vt.VectorTileLayer(
              theme: theme,
              tileProviders: providers,
            ),
            ...widget.children,
          ],
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: _MapAttribution(isDark: widget.isDark),
          ),
        ),
      ],
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg =
        isDark ? CanalColors.darkTextSecondary : CanalColors.lightTextSecondary;
    final bg = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;

    return Semantics(
      label: 'Datos de mapa: OpenMapTiles y OpenStreetMap',
      child: Container(
        margin: const EdgeInsets.only(left: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? CanalColors.darkBorder : CanalColors.lightBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          '© OpenMapTiles · © OpenStreetMap',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: fg.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
