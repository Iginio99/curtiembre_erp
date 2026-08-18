import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/data/datasources/kardex_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/entities/kardex_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/kardex/domain/repositories/kardex_repository.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';
import 'package:talker_flutter/talker_flutter.dart';

class KardexRepositoryImpl implements KardexRepository {
  KardexRepositoryImpl(this._remoteDataSource, this._talker);

  final KardexRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<InsumoLookup>> listActiveInsumos() async {
    _talker.repository('Consultando insumos activos para filtros de kardex.');
    final items = await _remoteDataSource.listActiveInsumos();
    _talker.repository(
      'Se obtuvieron ${items.length} insumos activos para filtros de kardex.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<KardexRecord>> listKardex({
    int? insumoId,
    String? tipoMovimiento,
    String? documentoTipo,
    int? usuarioResponsableId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    _talker.repository(
      'Consultando kardex con filtros insumoId=$insumoId, tipoMovimiento=${_describeState(tipoMovimiento)}, documentoTipo=${_describeState(documentoTipo)}, usuarioResponsableId=$usuarioResponsableId, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}.',
    );
    final items = await _remoteDataSource.listKardex(
      insumoId: insumoId,
      tipoMovimiento: tipoMovimiento,
      documentoTipo: documentoTipo,
      usuarioResponsableId: usuarioResponsableId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} movimientos para la consulta de kardex.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<KardexRecord>> listKardexByInsumo(
    int insumoId, {
    String? tipoMovimiento,
    String? documentoTipo,
    int? usuarioResponsableId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    _talker.repository(
      'Consultando kardex del insumo $insumoId con filtros tipoMovimiento=${_describeState(tipoMovimiento)}, documentoTipo=${_describeState(documentoTipo)}, usuarioResponsableId=$usuarioResponsableId, fechaDesde=${_describeDate(fechaDesde)}, fechaHasta=${_describeDate(fechaHasta)}.',
    );
    final items = await _remoteDataSource.listKardexByInsumo(
      insumoId,
      tipoMovimiento: tipoMovimiento,
      documentoTipo: documentoTipo,
      usuarioResponsableId: usuarioResponsableId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} movimientos para el kardex del insumo $insumoId.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  String _describeState(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }

  String _describeDate(DateTime? value) {
    if (value == null) {
      return 'sin-filtro';
    }

    return value.toIso8601String();
  }
}
