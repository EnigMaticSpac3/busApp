import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';
import '../widgets/status_chip.dart';
import '../widgets/ad_banner.dart';
import '../widgets/route_card.dart' show RouteItem;
import 'route_detail_v2_screen.dart';

class RouteListScreen extends StatefulWidget {
  final Map<String, int>? activeBuses; // route_code → number of active buses

  const RouteListScreen({super.key, this.activeBuses});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String? _selectedLetter;

  final _groups = <_LetterGroup>[
    _LetterGroup('S', 'Corredor Sur', CanalColors.routeS, [
      _RouteItem('S420', 'Corredor Sur-Albrook'),
      _RouteItem('S421', 'Corredor Sur-Felipillo-Pacora'),
      _RouteItem('S422', 'Corredor Sur-Felipillo-Pacora'),
      _RouteItem('S432', 'Corredor Sur-ZP 5 de Mayo'),
      _RouteItem('S440', 'Corredor Sur-ZP 5 de Mayo-Albrook'),
      _RouteItem('S441', 'Corredor Sur-Metro Nuevo Tocumen'),
      _RouteItem('S442', 'Corredor Sur-Vía Israel-ZP 5 Mayo'),
      _RouteItem('S447', 'Metro Nuevo Tocumen-Corredor Sur-Costa del Este'),
      _RouteItem('S480', 'Corredor Sur-Albrook'),
      _RouteItem('S481', 'Corredor Sur-ZP La Siesta'),
      _RouteItem('S482', 'Corredor Sur-ZP 5 de Mayo'),
      _RouteItem('S487', 'ZP La Siesta-Corredor Sur-Costa del Este'),
      _RouteItem('S510', 'Corredor Sur-Albrook'),
      _RouteItem('S511', 'Corredor Sur-Belén'),
      _RouteItem('S512', 'Corredor Sur-Belén'),
      _RouteItem('S520', 'Corredor Sur-Albrook'),
      _RouteItem('S530', 'Llano Bonito-Corredor Sur-ZP 5 Mayo'),
      _RouteItem('S542', 'Corredor Sur-ZP 5 de Mayo'),
      _RouteItem('S549', 'La Pagoda-Corredor Sur-ZP 5 Mayo'),
      _RouteItem('S562', 'Corredor Sur-Don Bosco'),
      _RouteItem('S569', 'Corredor Sur-ZP 5 de Mayo'),
      _RouteItem('S572', 'Versalles-Corredor Sur-ZP 5 Mayo'),
      _RouteItem('S662', 'ZP 5 Mayo-Corredor Sur-Costa del Este'),
      _RouteItem('S669', 'Costa del Este-Corredor Sur-ZP 5 Mayo'),
    ]),
    _LetterGroup('T', 'Corredor Norte', CanalColors.routeT, [
      _RouteItem('T020', 'Chilibre Interno-Autopista-Albrook'),
      _RouteItem('T021', 'Autopista-Chilibre Interno'),
      _RouteItem('T022', 'Autopista-ZP 5 de Mayo'),
      _RouteItem('T033', 'Chilibre-Autopista-Vía Centenario'),
      _RouteItem('T040', 'Entrada Alcalde Díaz-Autopista-Albrook'),
      _RouteItem('T060', 'Corredor Norte-Albrook'),
      _RouteItem('T080', 'ZP Chilibre-Autopista-Albrook'),
      _RouteItem('T098', 'Metro Villa Zaita-Corredor Norte-Ciudad Salud'),
      _RouteItem('T100', 'Santa Librada-Corredor Norte-Albrook'),
      _RouteItem('T120', 'Corredor Norte-Albrook'),
      _RouteItem('T140', 'Corredor Norte-Albrook'),
      _RouteItem('T143', 'Torrijos Carter-Corredor Norte-Vía Centenario'),
      _RouteItem('T149', 'San Isidro-Corredor Norte-Albrook'),
      _RouteItem('T160', 'Corredor Norte-Albrook'),
      _RouteItem('T176', 'Metro Nuevo Tocumen-Corredor Norte-Metro San Isidro'),
      _RouteItem('T443', 'Corredor Norte-El Dorado-CSS'),
      _RouteItem('T582', 'San Antonio-Corredor Norte-ZP 5 Mayo'),
    ]),
    _LetterGroup('K', 'Transístmica', CanalColors.routeK, [
      _RouteItem('K042', 'Transístmica-ZP 5 de Mayo'),
      _RouteItem('K100', 'Santa Librada-Transístmica-Calidonia'),
      _RouteItem('K120', 'Transístmica-Calidonia-Albrook'),
      _RouteItem('K140', 'Transístmica-Calidonia-Albrook'),
      _RouteItem('K160', 'Transístmica-Calidonia-Albrook'),
      _RouteItem('K181', 'Transístmica-Directo-Albrook'),
      _RouteItem('K189', 'Metro Los Andes-Transístmica-Calidonia'),
      _RouteItem('K530', 'Transístmica-Metro Cincuentenario'),
    ]),
    _LetterGroup('M', 'Ricardo J. Alfaro', CanalColors.routeM, [
      _RouteItem('M062', 'Av. Ricardo J. Alfaro-ZP 5 Mayo'),
      _RouteItem('M100', 'Sta Librada-Av.R.Alfaro-Calidonia'),
      _RouteItem('M120', 'Av. Ricardo J. Alfaro-Calidonia'),
      _RouteItem('M140', 'Av. Ricardo J. Alfaro-Calidonia'),
      _RouteItem('M181', 'Av. Ricardo J. Alfaro-Directo'),
      _RouteItem('M182', 'Metro Los Andes-Av.R.Alfaro-ZP 5 Mayo'),
      _RouteItem('M201', 'Av. Ricardo J. Alfaro-Directo'),
      _RouteItem('M481', 'Av. Ricardo J. Alfaro-Juan Pablo II'),
      _RouteItem('M502', 'Av. Ricardo J. Alfaro-ZP 5 Mayo'),
      _RouteItem('M530', 'Av. Ricardo J. Alfaro-Calidonia'),
      _RouteItem('M671', 'Albrook-Juan Pablo II-Av.R.Alfaro'),
      _RouteItem('M675', 'Av. Ricardo J. Alfaro-Parque Urraca'),
    ]),
    _LetterGroup('V', 'Vía España', CanalColors.routeV, [
      _RouteItem('V180', 'Vía España-Calidonia-Albrook'),
      _RouteItem('V201', 'Vía España-Directo'),
      _RouteItem('V442', 'Vía España-ZP 5 de Mayo'),
      _RouteItem('V502', 'Vía España-ZP 5 de Mayo'),
      _RouteItem('V531', 'Vía España-Directo-Albrook'),
      _RouteItem('V532', 'Metro Pedregal-Vía España-ZP 5 Mayo'),
      _RouteItem('V539', 'Metro Pedregal-Vía España-Calidonia'),
      _RouteItem('V560', 'Vía España-Calidonia-Albrook'),
    ]),
    _LetterGroup('I', 'Vía Israel', CanalColors.routeI, [
      _RouteItem('I182', 'ZP 5 Mayo-Vía Israel-12 Octubre'),
      _RouteItem('I532', 'ZP El Balboa-Vía Israel-ZP 5 Mayo'),
      _RouteItem('I672', 'ZP 5 Mayo-Vía Israel-Panamá Viejo'),
    ]),
    _LetterGroup('A', 'Panamá Norte', CanalColors.routeA, [
      _RouteItem('A096', 'Metro Villa Zaita-Panamá Norte-Metro Cerro Viento'),
    ]),
    _LetterGroup('F', 'Forestal', CanalColors.routeF, [
      _RouteItem('F030', 'Forestal-Albrook'),
    ]),
    _LetterGroup('C', 'Complementaria Centro', CanalColors.routeC, [
      _RouteItem('C640', 'Albrook-Cinta Costera-Panamá Viejo'),
      _RouteItem('C641', 'Albrook-Directo Cincuentenario'),
      _RouteItem('C642', 'ZP 5 Mayo-Vía Israel-Panamá Viejo'),
      _RouteItem('C678', 'Metro Cincuentenario-Ciudad Salud'),
      _RouteItem('C790', 'Albrook-Paraíso-Parque Summit'),
      _RouteItem('C800', 'Albrook-Parque Summit'),
      _RouteItem('C810', 'Albrook-Miraflores'),
      _RouteItem('C820', 'Albrook-Ciudad del Saber'),
      _RouteItem('C830', 'Albrook-Udelas'),
      _RouteItem('C842', 'ZP 5 Mayo-Teatro Balboa'),
      _RouteItem('C850', 'Metro Albrook-Amador'),
      _RouteItem('C862', 'ZP 5 Mayo-Chorrillo'),
      _RouteItem('C888', 'Metro I del Carmen-UdP-El Cangrejo'),
      _RouteItem('C898', 'Paitilla-Plaza Edison-Vía Brasil'),
      _RouteItem('C903', 'Metro Iglesia del Carmen-Camino Cruces'),
      _RouteItem('C908', 'CC El Dorado-Bethania-Av.La Paz'),
      _RouteItem('C918', 'ZP 5 Mayo-Av.R.Alfaro-Av.La Paz'),
      _RouteItem('C928', 'ZP 5 Mayo-Transístmica-Vía España'),
      _RouteItem('C938', 'ZP 5 Mayo-Vía España-Ernesto T Lefevre'),
      _RouteItem('C941', 'Albrook-Calle 50-Vía Porras-Vía España'),
      _RouteItem('C944', 'Metro San Miguelito-Monte Oscuro'),
      _RouteItem('C952', 'ZP 5 Mayo-Vía Israel-Multiplaza'),
      _RouteItem('C968', 'Metro Vía Argentina-Vía Brasil-Punta Pacífica'),
      _RouteItem('C970', 'Albrook-Ciudad Salud-Merca'),
      _RouteItem('C974', 'Gran Estación-Ciudad Salud-Merca'),
      _RouteItem('C982', 'ZP 5 Mayo-Puerta Sur-Casco Antiguo'),
    ]),
    _LetterGroup('E', 'Complementaria Este', CanalColors.routeE, [
      _RouteItem('E418', 'Metro Nuevo Tocumen-Montemadero'),
      _RouteItem('E436', 'Metro Cerro Viento-Pedregal-24 Dic'),
      _RouteItem('E444', '24 Dic-Metro Cincuentenario'),
      _RouteItem('E445', 'Metro Nuevo Tocumen-El Balboa'),
      _RouteItem('E458', 'Metro 24 de Diciembre-Interna'),
      _RouteItem('E468', 'Metro 24 de Diciembre-Nuevo Tocumen'),
      _RouteItem('E478', 'Metro 24 de Diciembre-Buena Vista'),
      _RouteItem('E484', 'ZP La Siesta-Metro Cincuentenario'),
      _RouteItem('E485', 'ZP La Siesta-El Balboa'),
      _RouteItem('E486', 'Metro Cerro Viento-Pedregal-ZP Siesta'),
      _RouteItem('E488', 'Metro 24 de Diciembre'),
      _RouteItem('E489', 'Metro Pedregal-Aeropuerto'),
      _RouteItem('E496', 'Mañanitas-Metro Pedregal'),
      _RouteItem('E504', 'Mañanitas-Metro Cincuentenario'),
      _RouteItem('E505', 'Mañanitas-El Balboa'),
      _RouteItem('E506', 'Metro Cerro Viento-Mañanitas'),
      _RouteItem('E516', 'ZP Metro Pedregal-Las Américas'),
      _RouteItem('E526', 'Metro Pedregal-La Pagoda'),
      _RouteItem('E537', 'Metro Pedregal-Llano Bonito-Costa del Este'),
      _RouteItem('E556', 'Metro Pedregal-San Joaquín'),
      _RouteItem('E566', 'Metro Cerro Viento-Pedregal-Don Bosco'),
      _RouteItem('E568', 'ZP Metro Pedregal-Caobos-Don Bosco'),
      _RouteItem('E598', 'Metro Cerro Viento-Praderas San Antonio'),
      _RouteItem('E606', 'ZP Metro Pedregal-Concepción-Metropark'),
      _RouteItem('E618', 'Metro Cerro Viento-Brisas del Golf'),
      _RouteItem('E619', 'Entrada Brisas del Golf-Las Trancas'),
      _RouteItem('E628', 'Metro El Crisol-San Pedro'),
      _RouteItem('E638', 'Metro El Crisol-Interna'),
      _RouteItem('E658', 'Metro Villa Lucre-Interna'),
      _RouteItem('E665', 'Metro Cincuentenario-Costa del Este'),
    ]),
    _LetterGroup('N', 'Complementaria Norte', CanalColors.routeN, [
      _RouteItem('N025', 'Metro Los Andes-Chilibre'),
      _RouteItem('N035', 'Metro Los Andes-Chilibre Interno'),
      _RouteItem('N037', 'Metro Villa Zaita-Chilibre Interno'),
      _RouteItem('N045', 'ZP Metro Los Andes-Entrada Alcalde Díaz'),
      _RouteItem('N047', 'Metro Villa Zaita-Entrada Alcalde Díaz'),
      _RouteItem('N048', 'La Cabima-Interna Alcalde Díaz'),
      _RouteItem('N065', 'Metro Los Andes-Ciudad Bolívar'),
      _RouteItem('N067', 'Metro Villa Zaita-Ciudad Bolívar'),
      _RouteItem('N105', 'Santa Librada-Directo-Metro Los Andes'),
      _RouteItem('N106', 'Santa Librada-Metro San Isidro'),
      _RouteItem('N109', 'Santa Librada-Metro Los Andes'),
      _RouteItem('N125', 'Directo-Metro Los Andes'),
      _RouteItem('N126', 'Metro San Isidro-Mano de Piedra'),
      _RouteItem('N129', 'Mano de Piedra-Metro Los Andes'),
      _RouteItem('N145', 'Directo-Metro Los Andes'),
      _RouteItem('N147', 'Torrijos Carter-Mano de Piedra-El Valle'),
      _RouteItem('N149', 'Torrijos Carter-Metro Los Andes'),
      _RouteItem('N154', 'Directo-Metro San Miguelito'),
      _RouteItem('N156', 'Metro San Isidro-El Poderoso'),
      _RouteItem('N165', 'Metro Los Andes-El Valle'),
      _RouteItem('N185', 'Metro Los Andes-Interna'),
      _RouteItem('N204', 'Veranillo-Gran Estación'),
      _RouteItem('N205', 'Veranillo-El Balboa'),
      _RouteItem('N208', 'Veranillo-Metro Cincuentenario-Paraíso'),
      _RouteItem('N209', 'Veranillo-Automotor-Metro Cincuentenario'),
    ]),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? CanalColors.darkTextPrimary : CanalColors.lightTextPrimary;
    final textMuted = isDark ? CanalColors.darkTextMuted : CanalColors.lightTextMuted;
    final bg = isDark ? CanalColors.darkBackground : CanalColors.lightBackground;
    final surface = isDark ? CanalColors.darkSurface : CanalColors.lightSurface;
    final border = isDark ? CanalColors.darkBorder : CanalColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Todas las rutas',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar ruta o destino...',
                hintStyle: TextStyle(color: textMuted),
                prefixIcon: Icon(Icons.search_rounded, color: textMuted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? CanalColors.darkBackground : CanalColors.lightBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildLetterChips(isDark, textPrimary, textMuted, border, surface),
          Expanded(child: _buildContent(isDark, textPrimary, textMuted, surface, border)),
        ],
      ),
    );
  }

  Widget _buildLetterChips(bool isDark, Color textPrimary, Color textMuted, Color border, Color surface) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('Todos', null, isDark, textPrimary, textMuted, border),
          const SizedBox(width: 6),
          ..._groups.map((g) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _buildChip(g.letter, g.color, isDark, textPrimary, textMuted, border),
          )),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color? color, bool isDark, Color textPrimary, Color textMuted, Color border) {
    final selected = label == 'Todos' ? _selectedLetter == null : _selectedLetter == label;
    final chipBg = selected
        ? (color ?? CanalColors.primary)
        : (isDark ? CanalColors.darkBackground : CanalColors.lightBackground);
    final chipBorder = selected ? (color ?? CanalColors.primary) : border;
    final textColor = selected ? Colors.white : (color ?? textPrimary);

    return GestureDetector(
      onTap: () => setState(() => _selectedLetter = label == 'Todos' ? null : label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: chipBorder, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null && !selected) ...[
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: label == 'Todos' ? 'Inter' : 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    final q = _searchController.text.toLowerCase().trim();

    if (q.isNotEmpty) return _buildSearchResults(q, isDark, textPrimary, textMuted, surface, border);
    if (_selectedLetter != null) return _buildFilteredGrid(isDark, textPrimary, textMuted, surface, border);
    return _buildAllGroups(isDark, textPrimary, textMuted, surface, border);
  }

  // ── Search results ──

  Widget _buildSearchResults(String q, bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    final results = <_LetterGroup>[];
    for (final g in _groups) {
      final matched = g.routes.where((r) => r.code.toLowerCase().contains(q) || r.name.toLowerCase().contains(q)).toList();
      if (matched.isNotEmpty) results.add(_LetterGroup(g.letter, g.axis, g.color, matched));
    }
    final total = results.fold(0, (sum, g) => sum + g.routes.length);

    if (total == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: textMuted),
            const SizedBox(height: 8),
            Text('Sin resultados', style: TextStyle(fontSize: 15, color: textMuted)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Text('$total resultados', style: TextStyle(fontSize: 12, color: textMuted)),
        const SizedBox(height: 10),
        ...results.map((g) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LetterBadge(letter: g.letter, color: g.color),
                const SizedBox(width: 8),
                Text('${g.routes.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            _buildRouteGrid(g.routes, g.color, isDark, surface, textPrimary, textMuted, border),
            const SizedBox(height: 12),
          ],
        )),
      ],
    );
  }

  // ── Filtered grid (letter selected) ──

  Widget _buildFilteredGrid(bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    final group = _groups.firstWhere((g) => g.letter == _selectedLetter);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Row(
          children: [
            _LetterBadge(letter: group.letter, color: group.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                group.axis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ),
            Text(
              '${group.routes.length}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildRouteGrid(group.routes, group.color, isDark, surface, textPrimary, textMuted, border),
      ],
    );
  }

  // ── All groups (collapsed sections) ──

  Widget _buildAllGroups(bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        ..._groups.map((g) => _buildCollapsibleGroup(g, isDark, textPrimary, textMuted, surface, border)),
        const SizedBox(height: 12),
        AdBanner(isDark: isDark, placementId: 'route_list_bottom'),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCollapsibleGroup(_LetterGroup group, bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    return _CollapsibleSection(
      group: group,
      isDark: isDark,
      textPrimary: textPrimary,
      textMuted: textMuted,
      surface: surface,
      border: border,
      onRouteTap: _navigateToDetail,
      activeBuses: widget.activeBuses,
    );
  }

  // ── Shared grid builder ──

  Widget _buildRouteGrid(List<_RouteItem> routes, Color color, bool isDark, Color surface, Color textPrimary, Color textMuted, Color border) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemCount: routes.length,
      itemBuilder: (context, i) => _RouteTile(
        route: routes[i],
        color: color,
        isDark: isDark,
        surface: surface,
        textPrimary: textPrimary,
        textMuted: textMuted,
        border: border,
        activeBuses: widget.activeBuses?[routes[i].code] ?? 0,
        onTap: () => _navigateToDetail(routes[i]),
      ),
    );
  }

  // ── Navigation ──

  void _navigateToDetail(_RouteItem route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailV2Screen(
          route: RouteItem(
            routeCode: route.code,
            destination: route.name,
            isLive: false,
            legs: [],
            durationMin: 15,
            nextEta: 5,
            nextStop: 'Parada más cercana',
            stopsPerLeg: [],
            status: StatusLevel.onTime,
            price: 'B/.0.25',
            stopsSummary: '',
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ──

class _LetterBadge extends StatelessWidget {
  final String letter;
  final Color color;
  const _LetterBadge({required this.letter, required this.color});

  @override
  Widget build(BuildContext context) {
    final textColor = color.computeLuminance() > 0.3
        ? CanalColors.lightTextPrimary
        : Colors.white;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
        ),
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  final _RouteItem route;
  final Color color;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textMuted;
  final Color border;
  final VoidCallback onTap;
  final int activeBuses;

  const _RouteTile({
    required this.route,
    required this.color,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
    required this.onTap,
    this.activeBuses = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      route.code,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CanalColors.routeTextColor(route.code, isDark: isDark),
                      ),
                    ),
                  ),
                  if (activeBuses > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                route.name,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  final _LetterGroup group;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color surface;
  final Color border;
  final void Function(_RouteItem) onRouteTap;
  final Map<String, int>? activeBuses;

  const _CollapsibleSection({
    required this.group,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.surface,
    required this.border,
    required this.onRouteTap,
    this.activeBuses,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    _LetterBadge(letter: g.letter, color: g.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.axis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.textPrimary)),
                          Text('${g.routes.length} rutas', style: TextStyle(fontSize: 11, color: widget.textMuted)),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: widget.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: _buildCollapsibleGrid(g, widget.isDark, widget.surface, widget.textPrimary, widget.textMuted, widget.border),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleGrid(_LetterGroup g, bool isDark, Color surface, Color textPrimary, Color textMuted, Color border) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemCount: g.routes.length,
      itemBuilder: (context, i) => _RouteTile(
        route: g.routes[i],
        color: g.color,
        isDark: isDark,
        surface: surface,
        textPrimary: textPrimary,
        textMuted: textMuted,
        border: border,
        activeBuses: widget.activeBuses?[g.routes[i].code] ?? 0,
        onTap: () => widget.onRouteTap(g.routes[i]),
      ),
    );
  }
}

class _LetterGroup {
  final String letter;
  final String axis;
  final Color color;
  final List<_RouteItem> routes;

  const _LetterGroup(this.letter, this.axis, this.color, this.routes);
}

class _RouteItem {
  final String code;
  final String name;

  const _RouteItem(this.code, this.name);
}
