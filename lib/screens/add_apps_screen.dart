import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_style.dart';
import '../models/app_info.dart';
import '../providers/apps_provider.dart';

class AddAppsScreen extends StatefulWidget {
  const AddAppsScreen({super.key});

  @override
  State<AddAppsScreen> createState() => _AddAppsScreenState();
}

class _AddAppsScreenState extends State<AddAppsScreen> {
  final Set<String> _selected = {};
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      context.read<AppsProvider>().setSearchQuery(_searchCtrl.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppsProvider>().loadApps();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg,
      appBar: AppBar(
        backgroundColor: AppStyle.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppStyle.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Seleccionar Apps',
          style: GoogleFonts.inter(
            color: AppStyle.text,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: _hideSelected,
              child: Text(
                'Ocultar (${_selected.length})',
                style: GoogleFonts.inter(
                  color: AppStyle.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(color: AppStyle.text),
              decoration: InputDecoration(
                hintText: 'Buscar apps...',
                hintStyle: GoogleFonts.inter(color: AppStyle.muted),
                prefixIcon: const Icon(Icons.search, color: AppStyle.muted),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<AppsProvider>(
              builder: (_, provider, __) {
                if (provider.loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  );
                }
                final apps = provider.allApps
                    .where((a) => !a.isHidden)
                    .toList();
                if (apps.isEmpty) {
                  return Center(
                    child: Text(
                      'No se encontraron apps',
                      style: GoogleFonts.inter(color: AppStyle.muted),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: apps.length,
                  itemBuilder: (_, i) => _SelectableAppTile(
                    app: apps[i],
                    selected: _selected.contains(apps[i].packageName),
                    onToggle: () {
                      setState(() {
                        if (_selected.contains(apps[i].packageName)) {
                          _selected.remove(apps[i].packageName);
                        } else {
                          _selected.add(apps[i].packageName);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selected.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: _hideSelected,
                  icon: const Icon(Icons.visibility_off, color: Colors.white),
                  label: Text(
                    'Ocultar ${_selected.length} app${_selected.length > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyle.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _hideSelected() async {
    final provider = context.read<AppsProvider>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final count = _selected.length;
    final appsToHide = provider.allApps
        .where((a) => _selected.contains(a.packageName))
        .toList();
    var hiddenCount = 0;
    for (final app in appsToHide) {
      if (await provider.hideApp(app)) {
        hiddenCount++;
      }
    }
    if (mounted) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            hiddenCount == count
                ? '$hiddenCount app(s) ocultadas'
                : 'Android no permite ocultar estas apps sin Device/Profile Owner',
          ),
          backgroundColor: hiddenCount == count
              ? AppStyle.primary
              : AppStyle.danger,
        ),
      );
    }
  }
}

class _SelectableAppTile extends StatelessWidget {
  final AppInfo app;
  final bool selected;
  final VoidCallback onToggle;

  const _SelectableAppTile({
    required this.app,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? iconBytes;
    if (app.iconBase64 != null && app.iconBase64!.isNotEmpty) {
      try {
        iconBytes = base64Decode(app.iconBase64!);
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppStyle.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppStyle.primary : AppStyle.line,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: iconBytes != null
                  ? Image.memory(iconBytes, width: 44, height: 44)
                  : Container(
                      width: 44,
                      height: 44,
                      color: AppStyle.primarySoft,
                      child: const Icon(Icons.android, color: AppStyle.primary),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.appName,
                    style: GoogleFonts.inter(
                      color: AppStyle.text,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    app.packageName,
                    style: GoogleFonts.inter(
                      color: AppStyle.muted,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppStyle.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppStyle.primary : AppStyle.line,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
