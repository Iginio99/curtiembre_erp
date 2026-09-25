import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_breakpoints.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_radius.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.title,
    required this.currentPath,
    required this.userName,
    required this.roleName,
    required this.onSignOut,
    this.breadcrumbs = const [],
    this.alertCount,
    this.accessibleRoutes = const {},
  });

  final Widget child;
  final String title;
  final String currentPath;
  final String userName;
  final String roleName;
  final VoidCallback onSignOut;
  final List<String> breadcrumbs;
  final int? alertCount;
  final Set<String> accessibleRoutes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= AppBreakpoints.tablet;
        final compactSidebar = constraints.maxWidth < 1180;

        return Scaffold(
          drawer: isMobile
              ? Drawer(
                  child: SafeArea(
                    child: _Sidebar(
                      currentPath: currentPath,
                      compact: false,
                      onSignOut: onSignOut,
                      accessibleRoutes: accessibleRoutes,
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (!isMobile)
                  SizedBox(
                    width: compactSidebar ? 76 : 252,
                    child: _Sidebar(
                      currentPath: currentPath,
                      compact: compactSidebar,
                      onSignOut: onSignOut,
                      accessibleRoutes: accessibleRoutes,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _Topbar(
                        title: title,
                        breadcrumbs: breadcrumbs,
                        compact: isMobile,
                        userName: userName,
                        roleName: roleName,
                        alertCount: alertCount,
                        onSignOut: onSignOut,
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isMobile
              ? _MobileNavigation(
                  currentPath: currentPath,
                  accessibleRoutes: accessibleRoutes,
                )
              : null,
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.currentPath,
    required this.compact,
    required this.onSignOut,
    required this.accessibleRoutes,
  });

  final String currentPath;
  final bool compact;
  final VoidCallback onSignOut;
  final Set<String> accessibleRoutes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? AppSpacing.md : AppSpacing.lg,
              AppSpacing.lg,
              compact ? AppSpacing.md : AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: compact
                ? const Tooltip(
                    message: 'CITEccal Trujillo',
                    child: _BrandMark(),
                  )
                : const _BrandLockup(),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpacing.sm : AppSpacing.md,
              ),
              children: [
                for (final item in _navigationItems.where(
                  (item) =>
                      !item.route.startsWith('/inventario/') &&
                      !item.route.startsWith('/seguridad/') &&
                      !item.route.startsWith('/configuracion/') &&
                      !item.route.startsWith('/produccion/') &&
                      !item.route.startsWith('/finanzas/') &&
                      accessibleRoutes.contains(item.route),
                ))
                  _SidebarItem(
                    item: item,
                    selected: item.matches(currentPath),
                    compact: compact,
                  ),
                _InventoryNavigationGroup(
                  currentPath: currentPath,
                  compact: compact,
                  accessibleRoutes: accessibleRoutes,
                ),
                for (final group in _moduleNavigationGroups)
                  _ModuleNavigationGroup(
                    group: group,
                    currentPath: currentPath,
                    compact: compact,
                    accessibleRoutes: accessibleRoutes,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
            child: Column(
              children: [
                _SidebarItem(
                  item: const _NavigationItem(
                    label: 'Ayuda',
                    icon: Icons.help_outline_rounded,
                    route: '/home',
                  ),
                  selected: false,
                  compact: compact,
                ),
                _SidebarItem(
                  item: const _NavigationItem(
                    label: 'Cerrar sesión',
                    icon: Icons.logout_rounded,
                    route: '',
                  ),
                  selected: false,
                  compact: compact,
                  onTap: onSignOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryNavigationGroup extends StatelessWidget {
  const _InventoryNavigationGroup({
    required this.currentPath,
    required this.compact,
    required this.accessibleRoutes,
  });

  final String currentPath;
  final bool compact;
  final Set<String> accessibleRoutes;

  @override
  Widget build(BuildContext context) {
    final items = _inventoryNavigationItems
        .where((item) => accessibleRoutes.contains(item.route))
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    if (compact) {
      return Column(
        children: [
          for (final item in items)
            _SidebarItem(
              item: item,
              selected: item.matches(currentPath),
              compact: true,
            ),
        ],
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: currentPath.startsWith('/inventario/'),
        maintainState: true,
        dense: true,
        visualDensity: VisualDensity.compact,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        leading: const Icon(Icons.inventory_2_outlined),
        title: const Text('Inventario'),
        childrenPadding: const EdgeInsets.only(left: AppSpacing.lg),
        children: [
          for (final item in items)
            _SidebarItem(
              item: item,
              selected: item.matches(currentPath),
              compact: false,
            ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Icon(
        Icons.factory_outlined,
        color: Theme.of(context).colorScheme.onPrimary,
        size: 20,
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const _BrandMark(),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CITEccal Trujillo', style: theme.textTheme.titleSmall),
              Text(
                'ERP Curtiembre',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleNavigationGroup extends StatelessWidget {
  const _ModuleNavigationGroup({
    required this.group,
    required this.currentPath,
    required this.compact,
    required this.accessibleRoutes,
  });
  final _NavigationGroup group;
  final String currentPath;
  final bool compact;
  final Set<String> accessibleRoutes;
  @override
  Widget build(BuildContext context) {
    final items = group.items
        .where((item) => accessibleRoutes.contains(item.route))
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    if (compact) {
      return Column(
        children: [
          for (final item in items)
            _SidebarItem(
              item: item,
              selected: item.matches(currentPath),
              compact: true,
            ),
        ],
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: currentPath.startsWith(group.prefix),
        maintainState: true,
        dense: true,
        visualDensity: VisualDensity.compact,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        leading: Icon(group.icon),
        title: Text(group.label),
        childrenPadding: const EdgeInsets.only(left: AppSpacing.lg),
        children: [
          for (final item in items)
            _SidebarItem(
              item: item,
              selected: item.matches(currentPath),
              compact: false,
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.compact,
    this.onTap,
  });

  final _NavigationItem item;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final child = ListTile(
      dense: true,
      minLeadingWidth: 22,
      leading: Icon(item.icon, size: 20),
      title: compact ? null : Text(item.label),
      iconColor: selected ? colors.primary : colors.onSurfaceVariant,
      textColor: selected ? colors.primary : colors.onSurface,
      selected: selected,
      selectedTileColor: colors.primaryContainer.withValues(alpha: 0.45),
      selectedColor: colors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.sm,
      ),
      onTap: onTap ?? () => context.go(item.route),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: compact ? Tooltip(message: item.label, child: child) : child,
    );
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.title,
    required this.breadcrumbs,
    required this.compact,
    required this.userName,
    required this.roleName,
    required this.alertCount,
    required this.onSignOut,
  });

  final String title;
  final List<String> breadcrumbs;
  final bool compact;
  final String userName;
  final String roleName;
  final int? alertCount;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final initials = userName.trim().isEmpty
        ? 'U'
        : userName.trim().substring(0, 1).toUpperCase();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          if (compact)
            IconButton(
              tooltip: 'Abrir navegación',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          if (compact) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: compact
                ? Text(title, style: theme.textTheme.titleMedium)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (breadcrumbs.isNotEmpty)
                        Text(
                          breadcrumbs.join('  ›  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      Text(title, style: theme.textTheme.titleMedium),
                    ],
                  ),
          ),
          _AlertButton(count: alertCount),
          AnimatedBuilder(
            animation: getIt<ThemeModeController>(),
            builder: (context, _) {
              final controller = getIt<ThemeModeController>();
              return IconButton(
                tooltip: controller.isDarkMode ? 'Modo claro' : 'Modo oscuro',
                onPressed: controller.toggleLightDark,
                icon: Icon(
                  controller.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              );
            },
          ),
          PopupMenuButton<void>(
            tooltip: 'Perfil y sesión',
            offset: const Offset(0, 48),
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: theme.textTheme.titleSmall),
                    Text(roleName, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<void>(
                onTap: onSignOut,
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Cerrar sesión'),
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text(initials, style: theme.textTheme.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertButton extends StatelessWidget {
  const _AlertButton({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Alertas',
          onPressed: () => context.go('/alertas'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (count != null && count! > 0)
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({
    required this.currentPath,
    required this.accessibleRoutes,
  });

  final String currentPath;
  final Set<String> accessibleRoutes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = [
      (label: 'Inicio', icon: Icons.home_outlined, route: '/home'),
      (
        label: 'Operaciones',
        icon: Icons.build_outlined,
        route: '/produccion/ordenes',
      ),
      (
        label: 'Inventario',
        icon: Icons.inventory_2_outlined,
        route: '/inventario/stock',
      ),
      (
        label: 'Reportes',
        icon: Icons.bar_chart_outlined,
        route: '/produccion/reportes',
      ),
    ].where((item) => accessibleRoutes.contains(item.route)).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: _MobileNavigationItem(
                  label: item.label,
                  icon: item.icon,
                  active:
                      currentPath == item.route ||
                      currentPath.startsWith('${item.route}/'),
                  onTap: () => context.go(item.route),
                ),
              ),
            Expanded(
              child: _MobileNavigationItem(
                label: 'Más',
                icon: Icons.more_horiz_rounded,
                active: false,
                onTap: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavigationItem extends StatelessWidget {
  const _MobileNavigationItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = active ? colors.primary : colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: foreground),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  bool matches(String path) =>
      route == '/home' ? path == route : path.startsWith(route);
}

class _NavigationGroup {
  const _NavigationGroup(this.label, this.icon, this.prefix, this.items);
  final String label;
  final IconData icon;
  final String prefix;
  final List<_NavigationItem> items;
}

const _moduleNavigationGroups = [
  _NavigationGroup('Seguridad', Icons.shield_outlined, '/seguridad/', [
    _NavigationItem(
      label: 'Usuarios',
      icon: Icons.people_outline,
      route: '/seguridad/usuarios',
    ),
  ]),
  _NavigationGroup(
    'Configuración',
    Icons.settings_outlined,
    '/configuracion/',
    [
      _NavigationItem(
        label: 'Áreas',
        icon: Icons.account_tree_outlined,
        route: '/configuracion/areas',
      ),
      _NavigationItem(
        label: 'Parámetros',
        icon: Icons.tune_rounded,
        route: '/configuracion/parametros',
      ),
      _NavigationItem(
        label: 'Unidades',
        icon: Icons.straighten_outlined,
        route: '/configuracion/unidades-medida',
      ),
      _NavigationItem(
        label: 'Tipos de piel',
        icon: Icons.style_outlined,
        route: '/configuracion/tipos-piel',
      ),
    ],
  ),
  _NavigationGroup('Producción', Icons.factory_outlined, '/produccion/', [
    _NavigationItem(
      label: 'Clientes',
      icon: Icons.people_outline,
      route: '/produccion/clientes',
    ),
    _NavigationItem(
      label: 'Lotes',
      icon: Icons.layers_outlined,
      route: '/produccion/lotes',
    ),
    _NavigationItem(
      label: 'Órdenes',
      icon: Icons.assignment_outlined,
      route: '/produccion/ordenes',
    ),
    _NavigationItem(
      label: 'Productos terminados',
      icon: Icons.inventory_2_outlined,
      route: '/produccion/productos-terminados',
    ),
    _NavigationItem(
      label: 'Reportes',
      icon: Icons.bar_chart_outlined,
      route: '/produccion/reportes',
    ),
  ]),
  _NavigationGroup('Finanzas', Icons.payments_outlined, '/finanzas/', [
    _NavigationItem(
      label: 'Períodos',
      icon: Icons.calendar_month_outlined,
      route: '/finanzas/periodos',
    ),
    _NavigationItem(
      label: 'Indirectos',
      icon: Icons.receipt_long_outlined,
      route: '/finanzas/indirectos',
    ),
    _NavigationItem(
      label: 'Mano de obra',
      icon: Icons.groups_outlined,
      route: '/finanzas/mano-obra',
    ),
    _NavigationItem(
      label: 'Activos',
      icon: Icons.account_balance_outlined,
      route: '/finanzas/activos',
    ),
    _NavigationItem(
      label: 'Depreciaciones',
      icon: Icons.trending_down_outlined,
      route: '/finanzas/depreciaciones',
    ),
    _NavigationItem(
      label: 'Costos por proceso',
      icon: Icons.analytics_outlined,
      route: '/finanzas/costos/procesos',
    ),
    _NavigationItem(
      label: 'Costos por orden',
      icon: Icons.request_quote_outlined,
      route: '/finanzas/costos/ordenes',
    ),
    _NavigationItem(
      label: 'Precios',
      icon: Icons.sell_outlined,
      route: '/finanzas/precios',
    ),
    _NavigationItem(
      label: 'Rentabilidad',
      icon: Icons.insights_outlined,
      route: '/finanzas/rentabilidad',
    ),
    _NavigationItem(
      label: 'Reportes',
      icon: Icons.bar_chart_outlined,
      route: '/finanzas/reportes',
    ),
  ]),
];

const _navigationItems = [
  _NavigationItem(
    label: 'Inicio',
    icon: Icons.grid_view_rounded,
    route: '/home',
  ),
  _NavigationItem(
    label: 'Alertas',
    icon: Icons.warning_amber_rounded,
    route: '/alertas',
  ),
  _NavigationItem(
    label: 'Seguridad',
    icon: Icons.shield_outlined,
    route: '/seguridad/usuarios',
  ),
  _NavigationItem(
    label: 'Producción',
    icon: Icons.factory_outlined,
    route: '/produccion/ordenes',
  ),
  _NavigationItem(
    label: 'Finanzas',
    icon: Icons.payments_outlined,
    route: '/finanzas/periodos',
  ),
  _NavigationItem(
    label: 'Configuración',
    icon: Icons.settings_outlined,
    route: '/configuracion/areas',
  ),
];

const _inventoryNavigationItems = [
  _NavigationItem(
    label: 'Stock actual',
    icon: Icons.inventory_2_outlined,
    route: '/inventario/stock',
  ),
  _NavigationItem(
    label: 'Insumos',
    icon: Icons.category_outlined,
    route: '/inventario/insumos',
  ),
  _NavigationItem(
    label: 'Proveedores',
    icon: Icons.local_shipping_outlined,
    route: '/inventario/proveedores',
  ),
  _NavigationItem(
    label: 'Compras',
    icon: Icons.shopping_cart_outlined,
    route: '/inventario/compras',
  ),
  _NavigationItem(
    label: 'Entradas',
    icon: Icons.move_to_inbox_outlined,
    route: '/inventario/entradas',
  ),
  _NavigationItem(
    label: 'Salidas',
    icon: Icons.outbox_outlined,
    route: '/inventario/salidas',
  ),
  _NavigationItem(
    label: 'Solicitudes SOL',
    icon: Icons.assignment_turned_in_outlined,
    route: '/produccion/solicitudes-insumos',
  ),
  _NavigationItem(
    label: 'Ajustes',
    icon: Icons.tune_rounded,
    route: '/inventario/ajustes',
  ),
  _NavigationItem(
    label: 'Inventario físico',
    icon: Icons.fact_check_outlined,
    route: '/inventario/fisico',
  ),
  _NavigationItem(
    label: 'Kardex',
    icon: Icons.swap_horiz_rounded,
    route: '/inventario/kardex',
  ),
];
