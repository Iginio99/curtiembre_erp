import 'package:dio/dio.dart';
import 'package:erp_curtiembre_fronted/core/network/api_client.dart';
import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/storage/session_storage.dart';
import 'package:erp_curtiembre_fronted/core/theme/theme_mode_controller.dart';
import 'package:erp_curtiembre_fronted/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/auth/domain/repositories/auth_repository.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:erp_curtiembre_fronted/features/auth/presentation/cubit/change_password_cubit.dart';
import 'package:erp_curtiembre_fronted/features/alerts/data/datasources/alerts_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:erp_curtiembre_fronted/features/alerts/presentation/cubit/alerts_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/data/datasources/areas_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/data/repositories/areas_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/domain/repositories/areas_repository.dart';
import 'package:erp_curtiembre_fronted/features/configuration/areas/presentation/cubit/areas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/data/datasources/system_parameters_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/data/repositories/system_parameters_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/domain/repositories/system_parameters_repository.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/presentation/cubit/system_parameters_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/data/datasources/skin_types_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/data/repositories/skin_types_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/domain/repositories/skin_types_repository.dart';
import 'package:erp_curtiembre_fronted/features/configuration/skin_types/presentation/cubit/skin_types_cubit.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/data/datasources/units_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/data/repositories/units_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/domain/repositories/units_repository.dart';
import 'package:erp_curtiembre_fronted/features/configuration/units/presentation/cubit/units_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/data/datasources/activos_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/data/repositories/activos_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/domain/repositories/activos_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/activos/presentation/cubit/activos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/data/datasources/costos_finanzas_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/data/repositories/costos_finanzas_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/domain/repositories/costos_finanzas_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/cubit/costos_orden_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/costos/presentation/cubit/costos_proceso_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/data/datasources/depreciaciones_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/data/repositories/depreciaciones_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/domain/repositories/depreciaciones_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/depreciaciones/presentation/cubit/depreciaciones_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/data/datasources/indirectos_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/data/repositories/indirectos_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/domain/repositories/indirectos_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/indirectos/presentation/cubit/indirectos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/data/datasources/mano_obra_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/data/repositories/mano_obra_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/domain/repositories/mano_obra_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/mano_obra/presentation/cubit/mano_obra_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/data/datasources/periodos_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/data/repositories/periodos_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/domain/repositories/periodos_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/periodos/presentation/cubit/periodos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/data/datasources/finanzas_pricing_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/data/repositories/finanzas_pricing_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/domain/repositories/finanzas_pricing_repository.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/finanzas_reportes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/precio_sugerido_cubit.dart';
import 'package:erp_curtiembre_fronted/features/finance/pricing/presentation/cubit/rentabilidad_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/data/datasources/insumos_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/data/repositories/insumos_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/domain/repositories/insumos_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/insumos/presentation/cubit/insumos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/data/datasources/kardex_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/data/repositories/kardex_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/repositories/kardex_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/presentation/cubit/kardex_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/data/datasources/compras_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/data/repositories/compras_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/domain/repositories/compras_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/compras/presentation/cubit/compras_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/data/datasources/entradas_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/data/repositories/entradas_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/domain/repositories/entradas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/entradas/presentation/cubit/entradas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/data/datasources/inventario_fisico_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/data/repositories/inventario_fisico_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/domain/repositories/inventario_fisico_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/fisico/presentation/cubit/inventario_fisico_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/data/datasources/proveedores_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/data/repositories/proveedores_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/domain/repositories/proveedores_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/proveedores/presentation/cubit/proveedores_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/data/datasources/salidas_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/data/repositories/salidas_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/domain/repositories/salidas_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/salidas/presentation/cubit/salidas_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/data/datasources/stock_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/data/repositories/stock_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/repositories/stock_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/stock/presentation/cubit/stock_cubit.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/data/datasources/ajustes_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/data/repositories/ajustes_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/domain/repositories/ajustes_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/ajustes/presentation/cubit/ajustes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/data/datasources/clientes_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/data/repositories/clientes_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/repositories/clientes_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/presentation/cubit/clientes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/data/datasources/lotes_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/data/repositories/lotes_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/repositories/lotes_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/presentation/cubit/lotes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/datasources/ordenes_produccion_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/data/repositories/ordenes_produccion_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/presentation/cubit/ordenes_produccion_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/data/datasources/produccion_reportes_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/data/repositories/produccion_reportes_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/domain/repositories/produccion_reportes_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/reportes/presentation/cubit/produccion_reportes_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/data/datasources/solicitudes_insumos_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/data/repositories/solicitudes_insumos_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/domain/repositories/solicitudes_insumos_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/solicitudes_insumos/presentation/cubit/solicitudes_insumos_cubit.dart';
import 'package:erp_curtiembre_fronted/features/production/productos_terminados/presentation/cubit/productos_terminados_cubit.dart';
import 'package:erp_curtiembre_fronted/features/security/data/datasources/security_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/security/data/repositories/security_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/repositories/security_repository.dart';
import 'package:erp_curtiembre_fronted/features/security/presentation/cubit/security_access_cubit.dart';
import 'package:erp_curtiembre_fronted/features/users/data/datasources/users_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/users/data/repositories/users_repository_impl.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/repositories/users_repository.dart';
import 'package:erp_curtiembre_fronted/features/users/presentation/cubit/users_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AuthCubit>()) {
    return;
  }

  if (!getIt.isRegistered<Talker>()) {
    getIt.registerSingleton<Talker>(createAppTalker());
  }

  final secureStorage = const FlutterSecureStorage();
  final themeModeController = ThemeModeController(secureStorage);
  await themeModeController.load();

  getIt
    ..registerLazySingleton<FlutterSecureStorage>(() => secureStorage)
    ..registerSingleton<ThemeModeController>(themeModeController)
    ..registerLazySingleton<SessionStorage>(() => SessionStorage(getIt()))
    ..registerLazySingleton<Dio>(() => ApiClient.create(getIt()))
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<AlertsRemoteDataSource>(
      () => AlertsRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<AreasRemoteDataSource>(
      () => AreasRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<SystemParametersRemoteDataSource>(
      () => SystemParametersRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<SkinTypesRemoteDataSource>(
      () => SkinTypesRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<UnitsRemoteDataSource>(
      () => UnitsRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<ActivosRemoteDataSource>(
      () => ActivosRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<CostosFinanzasRemoteDataSource>(
      () => CostosFinanzasRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<DepreciacionesRemoteDataSource>(
      () => DepreciacionesRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<FinanzasPricingRemoteDataSource>(
      () => FinanzasPricingRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<ManoObraRemoteDataSource>(
      () => ManoObraRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<PeriodosRemoteDataSource>(
      () => PeriodosRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<IndirectosRemoteDataSource>(
      () => IndirectosRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<InsumosRemoteDataSource>(
      () => InsumosRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<StockRemoteDataSource>(
      () => StockRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<KardexRemoteDataSource>(
      () => KardexRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<ComprasRemoteDataSource>(
      () => ComprasRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<EntradasRemoteDataSource>(
      () => EntradasRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<InventarioFisicoRemoteDataSource>(
      () => InventarioFisicoRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<SalidasRemoteDataSource>(
      () => SalidasRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<AjustesRemoteDataSource>(
      () => AjustesRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<ProveedoresRemoteDataSource>(
      () => ProveedoresRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<ClientesRemoteDataSource>(
      () => ClientesRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<LotesRemoteDataSource>(
      () => LotesRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<OrdenesProduccionRemoteDataSource>(
      () => OrdenesProduccionRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<ProduccionReportesRemoteDataSource>(
      () => ProduccionReportesRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<SolicitudesInsumosRemoteDataSource>(
      () => SolicitudesInsumosRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<SecurityRemoteDataSource>(
      () => SecurityRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<UsersRemoteDataSource>(
      () => UsersRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<AlertsRepository>(
      () => AlertsRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<AreasRepository>(() => AreasRepositoryImpl(getIt()))
    ..registerLazySingleton<SystemParametersRepository>(
      () => SystemParametersRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<SkinTypesRepository>(
      () => SkinTypesRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<UnitsRepository>(() => UnitsRepositoryImpl(getIt()))
    ..registerLazySingleton<ActivosRepository>(
      () => ActivosRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<CostosFinanzasRepository>(
      () => CostosFinanzasRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<DepreciacionesRepository>(
      () => DepreciacionesRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<FinanzasPricingRepository>(
      () => FinanzasPricingRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<ManoObraRepository>(
      () => ManoObraRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<PeriodosRepository>(
      () => PeriodosRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<IndirectosRepository>(
      () => IndirectosRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<InsumosRepository>(
      () => InsumosRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<StockRepository>(
      () => StockRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<KardexRepository>(
      () => KardexRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<ComprasRepository>(
      () => ComprasRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<EntradasRepository>(
      () => EntradasRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<InventarioFisicoRepository>(
      () => InventarioFisicoRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<SalidasRepository>(
      () => SalidasRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<AjustesRepository>(
      () => AjustesRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<ProveedoresRepository>(
      () => ProveedoresRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<ClientesRepository>(
      () => ClientesRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<LotesRepository>(
      () => LotesRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<OrdenesProduccionRepository>(
      () => OrdenesProduccionRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<ProduccionReportesRepository>(
      () => ProduccionReportesRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<SolicitudesInsumosRepository>(
      () => SolicitudesInsumosRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<SecurityRepository>(
      () => SecurityRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<UsersRepository>(
      () => UsersRepositoryImpl(getIt(), getIt()),
    )
    ..registerFactory<AuthCubit>(() => AuthCubit(getIt()))
    ..registerFactory<AlertsCubit>(() => AlertsCubit(getIt()))
    ..registerFactory<AreasCubit>(() => AreasCubit(getIt()))
    ..registerFactory<SystemParametersCubit>(
      () => SystemParametersCubit(getIt()),
    )
    ..registerFactory<SkinTypesCubit>(() => SkinTypesCubit(getIt()))
    ..registerFactory<UnitsCubit>(() => UnitsCubit(getIt()))
    ..registerFactory<ActivosCubit>(() => ActivosCubit(getIt(), getIt()))
    ..registerFactory<CostosProcesoCubit>(
      () => CostosProcesoCubit(getIt(), getIt(), getIt()),
    )
    ..registerFactory<CostosOrdenCubit>(
      () => CostosOrdenCubit(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory<DepreciacionesCubit>(
      () => DepreciacionesCubit(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory<PrecioSugeridoCubit>(
      () => PrecioSugeridoCubit(getIt(), getIt(), getIt()),
    )
    ..registerFactory<RentabilidadCubit>(
      () => RentabilidadCubit(getIt(), getIt(), getIt()),
    )
    ..registerFactory<FinanzasReportesCubit>(
      () => FinanzasReportesCubit(getIt(), getIt()),
    )
    ..registerFactory<ManoObraCubit>(
      () => ManoObraCubit(getIt(), getIt(), getIt()),
    )
    ..registerFactory<PeriodosCubit>(() => PeriodosCubit(getIt(), getIt()))
    ..registerFactory<IndirectosCubit>(
      () => IndirectosCubit(getIt(), getIt(), getIt()),
    )
    ..registerFactory<InsumosCubit>(() => InsumosCubit(getIt(), getIt()))
    ..registerFactory<StockCubit>(() => StockCubit(getIt(), getIt()))
    ..registerFactory<KardexCubit>(() => KardexCubit(getIt(), getIt()))
    ..registerFactory<ComprasCubit>(() => ComprasCubit(getIt(), getIt()))
    ..registerFactory<EntradasCubit>(() => EntradasCubit(getIt(), getIt()))
    ..registerFactory<InventarioFisicoCubit>(
      () => InventarioFisicoCubit(getIt(), getIt()),
    )
    ..registerFactory<SalidasCubit>(() => SalidasCubit(getIt(), getIt()))
    ..registerFactory<AjustesCubit>(() => AjustesCubit(getIt(), getIt()))
    ..registerFactory<ProveedoresCubit>(
      () => ProveedoresCubit(getIt(), getIt()),
    )
    ..registerFactory<ClientesCubit>(() => ClientesCubit(getIt(), getIt()))
    ..registerFactory<LotesCubit>(() => LotesCubit(getIt(), getIt()))
    ..registerFactory<OrdenesProduccionCubit>(
      () => OrdenesProduccionCubit(getIt(), getIt()),
    )
    ..registerFactory<ProduccionReportesCubit>(
      () => ProduccionReportesCubit(getIt(), getIt(), getIt()),
    )
    ..registerFactory<SolicitudesInsumosCubit>(
      () => SolicitudesInsumosCubit(getIt()),
    )
    ..registerFactory<ProductosTerminadosCubit>(
      () => ProductosTerminadosCubit(getIt(), getIt()),
    )
    ..registerFactory<ChangePasswordCubit>(() => ChangePasswordCubit(getIt()))
    ..registerFactory<SecurityAccessCubit>(
      () => SecurityAccessCubit(getIt(), getIt()),
    )
    ..registerFactory<UsersCubit>(() => UsersCubit(getIt(), getIt()));
}
