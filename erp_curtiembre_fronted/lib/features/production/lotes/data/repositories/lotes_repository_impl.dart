import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/features/production/clientes/domain/entities/cliente_option.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/data/datasources/lotes_remote_data_source.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_disponibilidad.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/lote_record.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/entities/tipo_piel_option.dart';
import 'package:erp_curtiembre_fronted/features/production/lotes/domain/repositories/lotes_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LotesRepositoryImpl implements LotesRepository {
  LotesRepositoryImpl(this._remoteDataSource, this._talker);

  final LotesRemoteDataSource _remoteDataSource;
  final Talker _talker;

  @override
  Future<List<LoteRecord>> listLotes({
    String? texto,
    int? clienteId,
    int? tipoPielId,
    String? estado,
  }) async {
    _talker.repository(
      'Consultando lotes con filtros texto=${_describeText(texto)}, clienteId=$clienteId, tipoPielId=$tipoPielId, estado=${_describeState(estado)}.',
    );
    final items = await _remoteDataSource.listLotes(
      texto: texto,
      clienteId: clienteId,
      tipoPielId: tipoPielId,
      estado: estado,
    );
    _talker.repository(
      'Se obtuvieron ${items.length} lotes para la bandeja de produccion.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<LoteRecord> getLote(int id) async {
    _talker.repository('Consultando detalle del lote $id.');
    final item = await _remoteDataSource.getLote(id);
    _talker.repository('Detalle del lote $id obtenido correctamente.');
    return item.toEntity();
  }

  @override
  Future<LoteDisponibilidad> getDisponibilidad(int id) async {
    _talker.repository('Consultando disponibilidad del lote $id.');
    final item = await _remoteDataSource.getDisponibilidad(id);
    _talker.repository('Disponibilidad del lote $id obtenida correctamente.');
    return item.toEntity();
  }

  @override
  Future<List<ClienteOption>> listActiveClientes() async {
    _talker.repository(
      'Consultando clientes activos para formularios de lotes.',
    );
    final items = await _remoteDataSource.listActiveClientes();
    _talker.repository(
      'Se obtuvieron ${items.length} clientes activos para formularios de lotes.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<List<TipoPielOption>> listActiveTiposPiel() async {
    _talker.repository(
      'Consultando tipos de piel activos para formularios de lotes.',
    );
    final items = await _remoteDataSource.listActiveTiposPiel();
    _talker.repository(
      'Se obtuvieron ${items.length} tipos de piel activos para formularios de lotes.',
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<LoteRecord> createLote({
    required int clienteId,
    required int tipoPielId,
    required DateTime fechaIngreso,
    required double cantidadPielesInicial,
    required bool clienteTraeLote,
    required double costoPielesTotal,
    String? observacion,
  }) async {
    _talker.repository(
      'Iniciando creacion de lote para clienteId=$clienteId, tipoPielId=$tipoPielId, cantidadPielesInicial=$cantidadPielesInicial.',
    );
    final item = await _remoteDataSource.createLote(
      clienteId: clienteId,
      tipoPielId: tipoPielId,
      fechaIngreso: fechaIngreso,
      cantidadPielesInicial: cantidadPielesInicial,
      clienteTraeLote: clienteTraeLote,
      costoPielesTotal: costoPielesTotal,
      observacion: observacion,
    );
    _talker.repository('Lote creado correctamente con id=${item.id}.');
    return item.toEntity();
  }

  @override
  Future<LoteRecord> updateLote({
    required int id,
    required int clienteId,
    required int tipoPielId,
    required DateTime fechaIngreso,
    required double cantidadPielesInicial,
    required bool clienteTraeLote,
    required double costoPielesTotal,
    String? observacion,
  }) async {
    _talker.repository(
      'Iniciando actualizacion del lote $id para clienteId=$clienteId, tipoPielId=$tipoPielId, cantidadPielesInicial=$cantidadPielesInicial.',
    );
    final item = await _remoteDataSource.updateLote(
      id: id,
      clienteId: clienteId,
      tipoPielId: tipoPielId,
      fechaIngreso: fechaIngreso,
      cantidadPielesInicial: cantidadPielesInicial,
      clienteTraeLote: clienteTraeLote,
      costoPielesTotal: costoPielesTotal,
      observacion: observacion,
    );
    _talker.repository('Lote $id actualizado correctamente.');
    return item.toEntity();
  }

  String _describeText(String? texto) {
    final normalized = texto?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }

  String _describeState(String? estado) {
    final normalized = estado?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'vacio';
    }

    return normalized;
  }
}
