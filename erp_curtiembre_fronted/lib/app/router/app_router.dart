import 'dart:async';

import 'package:erp_curtiembre_fronted/app/theme_preview_page.dart';
import 'package:erp_curtiembre_fronted/core/di/service_locator.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_spacing.dart';
import 'package:erp_curtiembre_fronted/features/alerts/presentation/cubit/alerts_cubit.dart';
import 'package:erp_curtiembre_fronted/features/alerts/presentation/pages/alerts_page.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_state.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_state.dart';
import 'package:erp_curtiembre_fronted/shared/navigation/app_access_routes.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/change_password_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/pages/change_password_page.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/pages/login_page.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/presentation/cubit/areas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/presentation/pages/areas_page.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/presentation/cubit/system_parameters_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/presentation/pages/system_parameters_page.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/presentation/cubit/skin_types_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/presentation/pages/skin_types_page.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/presentation/cubit/units_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/presentation/pages/units_page.dart';
import 'package:erp_curtiembre_fronted/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/presentation/cubit/activos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/presentation/pages/activos_page.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/cubit/costos_orden_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/cubit/costos_proceso_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/pages/costos_orden_page.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/pages/costos_proceso_page.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/presentation/cubit/depreciaciones_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/presentation/pages/depreciaciones_page.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/presentation/cubit/indirectos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/presentation/pages/indirectos_page.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/presentation/cubit/mano_obra_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/presentation/pages/mano_obra_page.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/presentation/cubit/periodos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/presentation/pages/periodos_page.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/finanzas_reportes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/precio_sugerido_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/rentabilidad_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/pages/finanzas_reportes_page.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/pages/precio_sugerido_page.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/pages/rentabilidad_page.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/cubit/compras_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/pages/compras_page.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/presentation/cubit/entradas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/presentation/pages/entradas_page.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/cubit/inventario_fisico_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/pages/inventario_fisico_page.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/presentation/cubit/insumos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/presentation/pages/insumos_page.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/cubit/kardex_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/pages/kardex_page.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/presentation/cubit/proveedores_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/presentation/pages/proveedores_page.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/presentation/cubit/salidas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/presentation/pages/salidas_page.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/presentation/cubit/stock_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/presentation/pages/stock_page.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/presentation/cubit/ajustes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/presentation/pages/ajustes_page.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/presentation/cubit/clientes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/presentation/pages/clientes_page.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/presentation/cubit/lotes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/presentation/pages/lotes_page.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/cubit/ordenes_produccion_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/pages/ordenes_produccion_page.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/pages/personal_empresa_page.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/presentation/cubit/produccion_reportes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/presentation/pages/produccion_reportes_page.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/presentation/cubit/solicitudes_insumos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/presentation/pages/solicitudes_insumos_page.dart';
import 'package:erp_curtiembre_fronted/features/production/productos_terminados/presentation/cubit/productos_terminados_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/productos_terminados/presentation/pages/productos_terminados_page.dart';
import 'package:erp_curtiembre_fronted/features/users/presentation/cubit/users_cubit.dart';
import 'package:erp_curtiembre_fronted/features/users/presentation/pages/users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter(AuthCubit authCubit, SecurityAccessCubit securityAccessCubit)
    : router = GoRouter(
        initialLocation: _splashPath,
        refreshListenable: _GoRouterAuthRefresh(
          authCubit.stream,
          securityAccessCubit.stream,
        ),
        redirect: (context, state) {
          final status = authCubit.state.status;
          final location = state.matchedLocation;
          final session = authCubit.state.session;

          if (status == AuthStatus.checking) {
            return location == _splashPath ? null : _splashPath;
          }

          if (status == AuthStatus.unauthenticated) {
            return location == _loginPath ? null : _loginPath;
          }

          if (status == AuthStatus.authenticated &&
              session?.debeCambiarPassword == true &&
              location != _changePasswordPath) {
            return _changePasswordPath;
          }

          if (status == AuthStatus.authenticated &&
              session?.debeCambiarPassword == false &&
              location == _changePasswordPath) {
            return _homePath;
          }

          if (status == AuthStatus.authenticated &&
              (location == _loginPath || location == _splashPath)) {
            return _homePath;
          }

          final accessState = securityAccessCubit.state;
          if (status == AuthStatus.authenticated &&
              accessState.status == SecurityAccessStatus.success &&
              !AppAccessRoutes.canAccess(
                location,
                accessState.snapshot?.userPermissionCodes.toSet() ?? const {},
              )) {
            return _homePath;
          }

          return null;
        },
        routes: [
          GoRoute(
            path: _splashPath,
            builder: (context, state) => const _SplashPage(),
          ),
          GoRoute(
            path: _loginPath,
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: _changePasswordPath,
            builder: (context, state) => BlocProvider<ChangePasswordCubit>(
              create: (_) => getIt<ChangePasswordCubit>(),
              child: const ChangePasswordPage(),
            ),
          ),
          GoRoute(
            path: _homePath,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: _alertsPath,
            builder: (context, state) => BlocProvider<AlertsCubit>(
              create: (_) => getIt<AlertsCubit>()..initialize(),
              child: const AlertsPage(),
            ),
          ),
          GoRoute(
            path: _usersPath,
            builder: (context, state) => BlocProvider<UsersCubit>(
              create: (_) => getIt<UsersCubit>()..initialize(),
              child: const UsersPage(),
            ),
          ),
          GoRoute(
            path: _areasPath,
            builder: (context, state) => BlocProvider<AreasCubit>(
              create: (_) => getIt<AreasCubit>()..initialize(),
              child: const AreasPage(),
            ),
          ),
          GoRoute(
            path: _systemParametersPath,
            builder: (context, state) => BlocProvider<SystemParametersCubit>(
              create: (_) => getIt<SystemParametersCubit>()..initialize(),
              child: const SystemParametersPage(),
            ),
          ),
          GoRoute(
            path: _unitsPath,
            builder: (context, state) => BlocProvider<UnitsCubit>(
              create: (_) => getIt<UnitsCubit>()..initialize(),
              child: const UnitsPage(),
            ),
          ),
          GoRoute(
            path: _skinTypesPath,
            builder: (context, state) => BlocProvider<SkinTypesCubit>(
              create: (_) => getIt<SkinTypesCubit>()..initialize(),
              child: const SkinTypesPage(),
            ),
          ),
          GoRoute(
            path: _insumosPath,
            builder: (context, state) => BlocProvider<InsumosCubit>(
              create: (_) => getIt<InsumosCubit>()..initialize(),
              child: const InsumosPage(),
            ),
          ),
          GoRoute(
            path: _proveedoresPath,
            builder: (context, state) => BlocProvider<ProveedoresCubit>(
              create: (_) => getIt<ProveedoresCubit>()..initialize(),
              child: const ProveedoresPage(),
            ),
          ),
          GoRoute(
            path: _comprasPath,
            builder: (context, state) => BlocProvider<ComprasCubit>(
              create: (_) => getIt<ComprasCubit>()..initialize(),
              child: const ComprasPage(),
            ),
          ),
          GoRoute(
            path: _entradasPath,
            builder: (context, state) => BlocProvider<EntradasCubit>(
              create: (_) => getIt<EntradasCubit>()..initialize(),
              child: const EntradasPage(),
            ),
          ),
          GoRoute(
            path: _stockPath,
            builder: (context, state) => BlocProvider<StockCubit>(
              create: (_) => getIt<StockCubit>()..initialize(),
              child: const StockPage(),
            ),
          ),
          GoRoute(
            path: _finanzasPeriodosPath,
            builder: (context, state) => BlocProvider<PeriodosCubit>(
              create: (_) => getIt<PeriodosCubit>()..initialize(),
              child: const PeriodosPage(),
            ),
          ),
          GoRoute(
            path: _finanzasIndirectosPath,
            builder: (context, state) => BlocProvider<IndirectosCubit>(
              create: (_) => getIt<IndirectosCubit>()..initialize(),
              child: const IndirectosPage(),
            ),
          ),
          GoRoute(
            path: _finanzasManoObraPath,
            builder: (context, state) => BlocProvider<ManoObraCubit>(
              create: (_) => getIt<ManoObraCubit>()..initialize(),
              child: const ManoObraPage(),
            ),
          ),
          GoRoute(
            path: _finanzasActivosPath,
            builder: (context, state) => BlocProvider<ActivosCubit>(
              create: (_) => getIt<ActivosCubit>()..initialize(),
              child: const ActivosPage(),
            ),
          ),
          GoRoute(
            path: _finanzasDepreciacionesPath,
            builder: (context, state) => BlocProvider<DepreciacionesCubit>(
              create: (_) => getIt<DepreciacionesCubit>()..initialize(),
              child: const DepreciacionesPage(),
            ),
          ),
          GoRoute(
            path: _finanzasCostosProcesoPath,
            builder: (context, state) => BlocProvider<CostosProcesoCubit>(
              create: (_) => getIt<CostosProcesoCubit>()..initialize(),
              child: const CostosProcesoPage(),
            ),
          ),
          GoRoute(
            path: _finanzasCostosOrdenPath,
            builder: (context, state) => BlocProvider<CostosOrdenCubit>(
              create: (_) => getIt<CostosOrdenCubit>()..initialize(),
              child: const CostosOrdenPage(),
            ),
          ),
          GoRoute(
            path: _finanzasPreciosPath,
            builder: (context, state) => BlocProvider<PrecioSugeridoCubit>(
              create: (_) => getIt<PrecioSugeridoCubit>()..initialize(),
              child: const PrecioSugeridoPage(),
            ),
          ),
          GoRoute(
            path: _finanzasRentabilidadPath,
            builder: (context, state) => BlocProvider<RentabilidadCubit>(
              create: (_) => getIt<RentabilidadCubit>()..initialize(),
              child: const RentabilidadPage(),
            ),
          ),
          GoRoute(
            path: _finanzasReportesPath,
            builder: (context, state) => BlocProvider<FinanzasReportesCubit>(
              create: (_) => getIt<FinanzasReportesCubit>()..initialize(),
              child: const FinanzasReportesPage(),
            ),
          ),
          GoRoute(
            path: _inventarioFisicoPath,
            builder: (context, state) => BlocProvider<InventarioFisicoCubit>(
              create: (_) => getIt<InventarioFisicoCubit>()..initialize(),
              child: const InventarioFisicoPage(),
            ),
          ),
          GoRoute(
            path: _salidasPath,
            builder: (context, state) => BlocProvider<SalidasCubit>(
              create: (_) => getIt<SalidasCubit>()..initialize(),
              child: const SalidasPage(),
            ),
          ),
          GoRoute(
            path: _ajustesPath,
            builder: (context, state) => BlocProvider<AjustesCubit>(
              create: (_) => getIt<AjustesCubit>()..initialize(),
              child: const AjustesPage(),
            ),
          ),
          GoRoute(
            path: _kardexPath,
            builder: (context, state) => BlocProvider<KardexCubit>(
              create: (_) => getIt<KardexCubit>()..initialize(),
              child: const KardexPage(),
            ),
          ),
          GoRoute(
            path: _produccionClientesPath,
            builder: (context, state) => BlocProvider<ClientesCubit>(
              create: (_) => getIt<ClientesCubit>()..initialize(),
              child: const ClientesPage(),
            ),
          ),
          GoRoute(
            path: _produccionLotesPath,
            builder: (context, state) => BlocProvider<LotesCubit>(
              create: (_) => getIt<LotesCubit>()..initialize(),
              child: const LotesPage(),
            ),
          ),
          GoRoute(
            path: _produccionOrdenesPath,
            builder: (context, state) => BlocProvider<OrdenesProduccionCubit>(
              create: (_) => getIt<OrdenesProduccionCubit>()..initialize(),
              child: const OrdenesProduccionPage(),
            ),
          ),
          GoRoute(
            path: _produccionPersonalPath,
            builder: (context, state) => const PersonalEmpresaPage(),
          ),
          GoRoute(
            path: _produccionProductosTerminadosPath,
            builder: (context, state) => BlocProvider<ProductosTerminadosCubit>(
              create: (_) => getIt<ProductosTerminadosCubit>()..initialize(),
              child: const ProductosTerminadosPage(),
            ),
          ),
          GoRoute(
            path: _produccionReportesPath,
            builder: (context, state) => BlocProvider<ProduccionReportesCubit>(
              create: (_) => getIt<ProduccionReportesCubit>()..initialize(),
              child: const ProduccionReportesPage(),
            ),
          ),
          GoRoute(
            path: _produccionSolicitudesInsumosPath,
            builder: (context, state) => BlocProvider<SolicitudesInsumosCubit>(
              create: (_) => getIt<SolicitudesInsumosCubit>()..load(),
              child: const SolicitudesInsumosPage(),
            ),
          ),
          GoRoute(
            path: _themePreviewPath,
            builder: (context, state) => const ThemePreviewPage(),
          ),
        ],
      );

  static const String _splashPath = '/splash';
  static const String _loginPath = '/login';
  static const String _changePasswordPath = '/change-password';
  static const String _homePath = '/home';
  static const String _alertsPath = '/alertas';
  static const String _usersPath = '/seguridad/usuarios';
  static const String _areasPath = '/configuracion/areas';
  static const String _systemParametersPath = '/configuracion/parametros';
  static const String _unitsPath = '/configuracion/unidades-medida';
  static const String _skinTypesPath = '/configuracion/tipos-piel';
  static const String _insumosPath = '/inventario/insumos';
  static const String _proveedoresPath = '/inventario/proveedores';
  static const String _comprasPath = '/inventario/compras';
  static const String _entradasPath = '/inventario/entradas';
  static const String _stockPath = '/inventario/stock';
  static const String _finanzasPeriodosPath = '/finanzas/periodos';
  static const String _finanzasIndirectosPath = '/finanzas/indirectos';
  static const String _finanzasManoObraPath = '/finanzas/mano-obra';
  static const String _finanzasActivosPath = '/finanzas/activos';
  static const String _finanzasDepreciacionesPath = '/finanzas/depreciaciones';
  static const String _finanzasCostosProcesoPath = '/finanzas/costos/procesos';
  static const String _finanzasCostosOrdenPath = '/finanzas/costos/ordenes';
  static const String _finanzasPreciosPath = '/finanzas/precios';
  static const String _finanzasRentabilidadPath = '/finanzas/rentabilidad';
  static const String _finanzasReportesPath = '/finanzas/reportes';
  static const String _inventarioFisicoPath = '/inventario/fisico';
  static const String _salidasPath = '/inventario/salidas';
  static const String _ajustesPath = '/inventario/ajustes';
  static const String _kardexPath = '/inventario/kardex';
  static const String _produccionClientesPath = '/produccion/clientes';
  static const String _produccionLotesPath = '/produccion/lotes';
  static const String _produccionOrdenesPath = '/produccion/ordenes';
  static const String _produccionPersonalPath = '/produccion/personal';
  static const String _produccionProductosTerminadosPath =
      '/produccion/productos-terminados';
  static const String _produccionReportesPath = '/produccion/reportes';
  static const String _produccionSolicitudesInsumosPath =
      '/produccion/solicitudes-insumos';
  static const String _themePreviewPath = '/theme-preview';

  final GoRouter router;
}

class _GoRouterAuthRefresh extends ChangeNotifier {
  _GoRouterAuthRefresh(
    Stream<dynamic> authStream,
    Stream<dynamic> accessStream,
  ) {
    _subscriptions = [authStream, accessStream]
        .map(
          (stream) => stream.asBroadcastStream().listen((_) {
            notifyListeners();
          }),
        )
        .toList();
  }

  late final List<StreamSubscription<dynamic>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Validando sesion y configuracion inicial...',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
