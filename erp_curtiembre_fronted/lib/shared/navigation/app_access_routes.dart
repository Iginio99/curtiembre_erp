abstract final class AppAccessRoutes {
  static const inventoryMaster = 'INVENTARIO_MAESTROS';
  static const inventoryOperations = 'INVENTARIO_OPERACIONES';
  static const inventoryStock = 'INVENTARIO_STOCK';
  static const inventoryKardex = 'INVENTARIO_KARDEX';
  static const usersAdmin = 'USUARIOS_ADMIN';
  static const configurationAdmin = 'CONFIGURACION_ADMIN';
  static const productionOperate = 'PRODUCCION_OPERAR';
  static const financeOperate = 'FINANZAS_OPERAR';
  static const productionReports = 'PRODUCCION_REPORTES';
  static const financeReports = 'FINANZAS_REPORTES';

  static Set<String> forPermissions(Set<String> permissionCodes) {
    final routes = <String>{'/home', '/alertas'};
    if (permissionCodes.contains(usersAdmin)) {
      routes.add('/seguridad/usuarios');
    }
    if (permissionCodes.contains(configurationAdmin)) {
      routes.addAll({
        '/configuracion/areas',
        '/configuracion/parametros',
        '/configuracion/unidades-medida',
        '/configuracion/tipos-piel',
      });
    }
    if (permissionCodes.contains(inventoryMaster)) {
      routes.addAll({'/inventario/insumos', '/inventario/proveedores'});
    }
    if (permissionCodes.contains(inventoryStock)) {
      routes.add('/inventario/stock');
    }
    if (permissionCodes.contains(inventoryOperations)) {
      routes.addAll({
        '/inventario/compras',
        '/inventario/entradas',
        '/inventario/salidas',
        '/inventario/ajustes',
        '/inventario/fisico',
        '/produccion/solicitudes-insumos',
      });
    }
    if (permissionCodes.contains(productionOperate)) {
      routes.addAll({
        '/produccion/clientes',
        '/produccion/lotes',
        '/produccion/ordenes',
        '/produccion/personal',
        '/produccion/productos-terminados',
      });
    }
    if (permissionCodes.contains(productionReports)) {
      routes.add('/produccion/reportes');
    }
    if (permissionCodes.contains(inventoryKardex)) {
      routes.add('/inventario/kardex');
    }
    if (permissionCodes.contains(financeOperate)) {
      routes.addAll({
        '/finanzas/periodos',
        '/finanzas/indirectos',
        '/finanzas/mano-obra',
        '/finanzas/activos',
        '/finanzas/depreciaciones',
        '/finanzas/costos/procesos',
        '/finanzas/costos/ordenes',
        '/finanzas/precios',
        '/finanzas/rentabilidad',
      });
    }
    if (permissionCodes.contains(financeReports)) {
      routes.add('/finanzas/reportes');
    }
    return routes;
  }

  static bool canAccess(String path, Set<String> permissionCodes) {
    final routes = forPermissions(permissionCodes);
    return routes.any((route) => path == route || path.startsWith('$route/'));
  }

  static Set<String> forRole(String roleName) {
    const commonRoutes = {'/home', '/alertas'};
    final role = roleName.toUpperCase();

    if (role.contains('ADMIN')) {
      return {
        ...commonRoutes,
        '/seguridad/usuarios',
        '/inventario/stock',
        '/produccion/ordenes',
        '/finanzas/periodos',
        '/configuracion/areas',
      };
    }
    if (role.contains('LOG')) {
      return {...commonRoutes, '/inventario/stock'};
    }
    if (role.contains('PRODU')) {
      return {...commonRoutes, '/produccion/ordenes'};
    }
    if (role.contains('FINAN')) {
      return {...commonRoutes, '/finanzas/periodos'};
    }
    return commonRoutes;
  }
}
