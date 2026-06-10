import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_style.dart';
import '../models/app_info.dart';
import '../providers/apps_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/liquid_glass.dart';
import 'settings_screen.dart';
import 'intruder_screen.dart';
import 'add_apps_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _introController;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppsProvider>().loadApps();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg,
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            _buildMainVault(),
            const SettingsScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMainVault() {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_HiddenAppsTab(), _FilesTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final animation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.08),
          end: Offset.zero,
        ).animate(animation),
        child: LiquidGlass(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'app-logo',
                child: Image.asset(
                  'logo_app.png',
                  width: 48,
                  height: 48,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.shield_outlined,
                    color: AppStyle.primary,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bóveda',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppStyle.text,
                    ),
                  ),
                  Text(
                    'Panel seguro',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppStyle.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IntruderScreen()),
                ),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppStyle.muted,
                ),
              ),
              IconButton(
                onPressed: () {
                  context.read<AuthProvider>().lock();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.lock_outlined, color: AppStyle.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppStyle.shadow,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppStyle.primary, Color(0xFF9B8FFF)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
        labelColor: Colors.white,
        unselectedLabelColor: AppStyle.muted,
        tabs: const [
          Tab(text: 'Apps Ocultas'),
          Tab(text: 'Mis Archivos'),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppStyle.line)),
      ),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppStyle.primary,
        unselectedItemColor: AppStyle.muted,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Herramientas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _HiddenAppsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppsProvider>(
      builder: (_, provider, __) {
        if (provider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppStyle.primary),
          );
        }

        final hidden = provider.hiddenApps;

        return Column(
          children: [
            // Acciones
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Agregar apps',
                      icon: Icons.add,
                      gradient: const LinearGradient(
                        colors: [AppStyle.primary, Color(0xFF9B8FFF)],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddAppsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Restaurar todo',
                      icon: Icons.restore,
                      gradient: LinearGradient(
                        colors: [AppStyle.primarySoft, Colors.white],
                      ),
                      onTap: hidden.isEmpty
                          ? null
                          : () async {
                              await provider.showAll();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Todas las apps restauradas'),
                                    backgroundColor: AppStyle.primary,
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),

            // Lista de apps ocultas
            Expanded(
              child: hidden.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: hidden.length,
                      itemBuilder: (_, i) => TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 260 + (i * 45)),
                        tween: Tween(begin: 0, end: 1),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: _AppTile(
                          app: hidden[i],
                          onRestore: () => provider.showApp(hidden[i]),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppStyle.shadow,
            ),
            child: const Icon(
              Icons.apps_outlined,
              color: AppStyle.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay apps ocultas',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppStyle.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca "Agregar apps" para ocultar\nlas apps que quieras',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppStyle.muted),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onRestore;

  const _AppTile({required this.app, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    Uint8List? iconBytes;
    if (app.iconBase64 != null && app.iconBase64!.isNotEmpty) {
      try {
        iconBytes = base64Decode(app.iconBase64!);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyle.line),
        boxShadow: AppStyle.shadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onLongPress: onRestore,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: iconBytes != null
                    ? Image.memory(
                        iconBytes,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: AppStyle.primarySoft,
                        child: const Icon(
                          Icons.android,
                          color: AppStyle.primary,
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                app.appName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppStyle.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              const Icon(Icons.lock_outline, color: AppStyle.primary, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppStyle.shadow,
            ),
            child: const Icon(
              Icons.folder_outlined,
              color: AppStyle.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Próximamente',
            style: GoogleFonts.inter(fontSize: 16, color: AppStyle.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Bóveda de archivos privados',
            style: GoogleFonts.inter(fontSize: 13, color: AppStyle.muted),
          ),
        ],
      ),
    );
  }
}
