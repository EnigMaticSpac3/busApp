import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';

/// Ad placement service — defines where ads appear in the app.
/// This is the foundation for real ad SDK integration (AdMob, IronSource, etc).
/// Each placement has a type, priority, and frequency cap.
enum AdPlacementType { native, banner, interstitial, rewarded }

enum AdPlacementPriority { low, medium, high }

/// Defines a single ad placement in the app.
class AdPlacement {
  final String id;
  final AdPlacementType type;
  final AdPlacementPriority priority;
  final int frequencyCap; // max impressions per session
  final bool requiresConsent;
  final bool requiresOnline;

  const AdPlacement({
    required this.id,
    required this.type,
    this.priority = AdPlacementPriority.medium,
    this.frequencyCap = 1,
    this.requiresConsent = true,
    this.requiresOnline = true,
  });
}

/// Ad placement service — manages ad placements and frequency caps.
/// Wire this to a real ad SDK (AdMob, IronSource, Meta Audience Network).
class AdPlacementService extends ChangeNotifier {
  final Map<String, int> _impressions = {};
  bool _consentGiven = false;
  bool _isOnline = true;

  /// All defined ad placements in the app.
  /// NO ads on: map, ETA cards, search, GO mode, route detail, onboarding,
  /// empty states, connection banner, bottom-sheet peek.
  static const placements = <AdPlacement>[
    // ── Phase 2: Passive ads (low-friction) ──
    AdPlacement(
      id: 'route_list_bottom',
      type: AdPlacementType.banner,
      priority: AdPlacementPriority.low,
      frequencyCap: 1,
    ),
    AdPlacement(
      id: 'profile_community',
      type: AdPlacementType.native,
      priority: AdPlacementPriority.low,
      frequencyCap: 1,
    ),
    // ── Phase 3: Contextual ads (intent-based) ──
    AdPlacement(
      id: 'walking_segment',
      type: AdPlacementType.native,
      priority: AdPlacementPriority.medium,
      frequencyCap: 1,
      requiresOnline: true,
    ),
    AdPlacement(
      id: 'trip_complete',
      type: AdPlacementType.banner,
      priority: AdPlacementPriority.medium,
      frequencyCap: 2,
    ),
    // ── Phase 4: Premium ──
    AdPlacement(
      id: 'rewarded_extended_tracking',
      type: AdPlacementType.rewarded,
      priority: AdPlacementPriority.high,
      frequencyCap: 1,
      requiresConsent: false,
    ),
  ];

  bool get consentGiven => _consentGiven;
  bool get isOnline => _isOnline;

  void giveConsent() {
    _consentGiven = true;
    notifyListeners();
  }

  void setOnline(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  /// Check if a placement can show an ad right now.
  bool canShow(String placementId) {
    final placement = placements.where((p) => p.id == placementId).firstOrNull;
    if (placement == null) return false;
    if (placement.requiresConsent && !_consentGiven) return false;
    if (placement.requiresOnline && !_isOnline) return false;
    final count = _impressions[placementId] ?? 0;
    return count < placement.frequencyCap;
  }

  /// Record an impression for a placement.
  void recordImpression(String placementId) {
    _impressions[placementId] = (_impressions[placementId] ?? 0) + 1;
    notifyListeners();
  }

  /// Get current impression count for a placement.
  int impressionCount(String placementId) => _impressions[placementId] ?? 0;

  /// Reset all impressions (call on new session).
  void resetSession() {
    _impressions.clear();
    notifyListeners();
  }
}

/// Lightweight banner placeholder — shows where a real ad banner will appear.
/// Uses Canal palette styling. Replace with real ad SDK widget when integrated.
class AdBannerPlaceholder extends StatelessWidget {
  final String placementId;
  final bool isDark;

  const AdBannerPlaceholder({
    super.key,
    required this.placementId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? CanalColors.darkSurface2 : CanalColors.lightSurface2;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    final border = isDark ? CanalColors.darkBorder : CanalColors.lightBorder;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Text(
          'Publicidad',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ),
    );
  }
}

/// Lightweight native ad placeholder — shows where a real native ad will appear.
/// Matches RouteTile styling. Replace with real ad SDK widget when integrated.
class AdNativePlaceholder extends StatelessWidget {
  final String placementId;
  final bool isDark;

  const AdNativePlaceholder({
    super.key,
    required this.placementId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? CanalColors.darkSurface2 : CanalColors.lightSurface2;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    final border = isDark ? CanalColors.darkBorder : CanalColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: textMuted),
          const SizedBox(width: 6),
          Text(
            'Publicidad',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
