import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_style.dart';
import '../native_bridges/app_hider_bridge.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Bóveda', icon: Icons.lock),
              const SizedBox(height: 12),
              _buildSecuritySection(),
              const SizedBox(height: 24),
              _sectionTitle('Android', icon: Icons.android),
              const SizedBox(height: 12),
              _buildAndroidSection(),
              const SizedBox(height: 24),
              _sectionTitle('Apariencia', icon: Icons.palette_outlined),
              const SizedBox(height: 12),
              _buildAppearanceSection(),
              const SizedBox(height: 24),
              _sectionTitle(
                'Acceso Invisible',
                icon: Icons.visibility_off_outlined,
              ),
              const SizedBox(height: 12),
              _buildAccessSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: AppStyle.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppStyle.primary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        return _SettingsCard(
          children: [
            _SettingsTile(
              icon: Icons.dialpad,
              label: 'Cambiar PIN',
              onTap: () => _showChangePinDialog(context, auth),
            ),
            _divider(),
            _SettingsTile(
              icon: Icons.warning_amber_rounded,
              label: 'PIN de Pánico',
              subtitle: 'Muestra bóveda falsa vacía',
              onTap: () => _showChangePanicPinDialog(context, auth),
            ),
            _divider(),
            FutureBuilder<bool>(
              future: auth.isBiometricEnabled(),
              builder: (_, snap) {
                final enabled = snap.data ?? false;
                return _SettingsTile(
                  icon: Icons.fingerprint,
                  label: 'Biometría',
                  subtitle: 'Huella / Face ID',
                  trailing: Switch(
                    value: enabled,
                    onChanged: (v) async {
                      await auth.setBiometricEnabled(v);
                      setState(() {});
                    },
                    activeColor: AppStyle.primary,
                  ),
                );
              },
            ),
            _divider(),
            Consumer<SettingsProvider>(
              builder: (_, settings, __) {
                return _SettingsTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'Foto de Intrusos',
                  subtitle: 'Capturar foto en intentos fallidos',
                  trailing: Switch(
                    value: settings.cameraIntruder,
                    onChanged: settings.setCameraIntruder,
                    activeColor: AppStyle.primary,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAndroidSection() {
    return Consumer<SettingsProvider>(
      builder: (_, settings, __) {
        return _SettingsCard(
          children: [
            _SettingsTile(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Administrador del Dispositivo',
              subtitle: settings.deviceAdmin
                  ? '✓ Activo — Protección completa'
                  : 'Inactivo — Toca para activar',
              subtitleColor: settings.deviceAdmin
                  ? AppStyle.success
                  : Colors.orange,
              trailing: settings.deviceAdmin
                  ? const Icon(
                      Icons.verified,
                      color: AppStyle.success,
                      size: 20,
                    )
                  : const Icon(Icons.chevron_right, color: AppStyle.muted),
              onTap: settings.deviceAdmin
                  ? null
                  : () async {
                      await settings.requestDeviceAdmin();
                      setState(() {});
                    },
            ),
            _divider(),
            _SettingsTile(
              icon: Icons.refresh,
              label: 'Verificar permisos',
              onTap: () async {
                await settings.refreshDeviceAdmin();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        settings.deviceAdmin
                            ? 'Device Admin: Activo'
                            : 'Device Admin: Inactivo',
                      ),
                      backgroundColor: AppStyle.primary,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppearanceSection() {
    return Consumer<SettingsProvider>(
      builder: (_, settings, __) {
        return _SettingsCard(
          children: [
            _SettingsTile(
              icon: Icons.calculate_outlined,
              label: 'Ícono del Lanzador',
              subtitle: 'Cambia la apariencia en el cajón de apps',
              onTap: () => _showAliasDialog(context, settings),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccessSection() {
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (_, auth, settings, __) {
        return _SettingsCard(
          children: [
            _AccessSwitchTile(
              icon: Icons.pin_outlined,
              label: 'PIN en calculadora',
              subtitle: 'Escribir PIN y tocar =',
              value: settings.accessPin,
              onChanged: (v) => settings.setAccessMethod('pin', v),
            ),
            _divider(),
            _AccessSwitchTile(
              icon: Icons.gesture,
              label: 'Patrón',
              subtitle: 'Ingreso por patrón de 9 puntos',
              value: settings.accessPattern,
              onChanged: (v) => settings.setAccessMethod('pattern', v),
            ),
            _divider(),
            _AccessSwitchTile(
              icon: Icons.fingerprint,
              label: 'Biometría',
              subtitle: 'Huella o credencial del dispositivo',
              value: settings.accessBiometric,
              onChanged: (v) async {
                await settings.setAccessMethod('biometric', v);
                await auth.setBiometricEnabled(v);
              },
            ),
            _divider(),
            _AccessSwitchTile(
              icon: Icons.phone_android_outlined,
              label: 'Teléfono',
              subtitle: 'Marca *#*#0000#*#*',
              value: settings.accessPhone,
              onChanged: (v) => settings.setAccessMethod('phone', v),
              onTap: () => _showDialCodeDialog(context, auth),
            ),
            _divider(),
            _AccessSwitchTile(
              icon: Icons.link,
              label: 'Deep Link',
              subtitle: 'boveda://open',
              value: settings.accessDeepLink,
              onChanged: (v) => settings.setAccessMethod('deep_link', v),
            ),
            _divider(),
            _AccessSwitchTile(
              icon: Icons.widgets_outlined,
              label: 'Widget invisible',
              subtitle: 'Widget 1x1 transparente',
              value: settings.accessWidget,
              onChanged: (v) => settings.setAccessMethod('widget', v),
            ),
            _divider(),
            _AccessSwitchTile(
              icon: Icons.space_dashboard_outlined,
              label: 'Ajustes rápidos',
              subtitle: 'Tile “Ahorro de datos”',
              value: settings.accessQuickTile,
              onChanged: (v) => settings.setAccessMethod('quick_tile', v),
              onTap: AppHiderBridge.requestQuickTile,
            ),
            _divider(),
            _AccessSwitchTile(
              icon: Icons.notifications_active_outlined,
              label: 'Notificación falsa',
              subtitle: 'Tres toques rápidos para entrar',
              value: settings.accessNotification,
              onChanged: (v) => settings.setAccessMethod('notification', v),
            ),
          ],
        );
      },
    );
  }

  Widget _divider() => Divider(color: AppStyle.line, height: 1, indent: 56);

  void _showChangePinDialog(BuildContext ctx, AuthProvider auth) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => _PinDialog(
        title: 'Nuevo PIN',
        controller: ctrl,
        onConfirm: () async {
          final nav = Navigator.of(ctx);
          await auth.setupPin(ctrl.text);
          nav.pop();
        },
      ),
    );
  }

  void _showChangePanicPinDialog(BuildContext ctx, AuthProvider auth) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => _PinDialog(
        title: 'PIN de Pánico',
        controller: ctrl,
        onConfirm: () async {
          final nav = Navigator.of(ctx);
          await auth.setupPanicPin(ctrl.text);
          nav.pop();
        },
      ),
    );
  }

  void _showDialCodeDialog(BuildContext ctx, AuthProvider auth) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => _PinDialog(
        title: 'Código de Llamada',
        hint: '*#*#0000#*#*',
        controller: ctrl,
        onConfirm: () async {
          final nav = Navigator.of(ctx);
          await auth.setDialCode(ctrl.text);
          nav.pop();
        },
      ),
    );
  }

  void _showAliasDialog(BuildContext ctx, SettingsProvider settings) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Ícono del Lanzador',
          style: GoogleFonts.inter(color: AppStyle.text, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AliasOption(
              label: 'Calculadora (disfraz)',
              selected: settings.launcherAlias == 'calculator',
              onTap: () {
                settings.setLauncherAlias('calculator');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _AliasOption(
              label: 'Bóveda (original)',
              selected: settings.launcherAlias == 'vault',
              onTap: () {
                settings.setLauncherAlias('vault');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AliasOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AliasOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppStyle.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppStyle.primary : AppStyle.line,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: AppStyle.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: AppStyle.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyle.line),
        boxShadow: AppStyle.shadow,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppStyle.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppStyle.primary, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: AppStyle.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: subtitleColor ?? AppStyle.muted,
              ),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppStyle.muted)
              : null),
      onTap: onTap,
    );
  }
}

class _AccessSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;

  const _AccessSwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      label: label,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppStyle.primary,
      ),
    );
  }
}

class _PinDialog extends StatelessWidget {
  final String title;
  final String? hint;
  final TextEditingController controller;
  final VoidCallback onConfirm;

  const _PinDialog({
    required this.title,
    this.hint,
    required this.controller,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: AppStyle.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: title != 'Código de Llamada',
        style: GoogleFonts.inter(
          color: AppStyle.text,
          fontSize: 20,
          letterSpacing: 4,
        ),
        decoration: InputDecoration(
          hintText: hint ?? '••••••',
          hintStyle: GoogleFonts.inter(color: AppStyle.muted, letterSpacing: 4),
          filled: true,
          fillColor: AppStyle.bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(color: AppStyle.muted),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyle.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Guardar',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
