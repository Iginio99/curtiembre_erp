import 'package:erp_curtiembre_fronted/core/logging/app_talker.dart';
import 'package:erp_curtiembre_fronted/core/network/api_exception.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/entities/producto_terminado_record.dart';
import 'package:erp_curtiembre_fronted/features/production/ordenes/domain/repositories/ordenes_produccion_repository.dart';
import 'package:erp_curtiembre_fronted/features/production/productos_terminados/presentation/cubit/productos_terminados_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ProductosTerminadosCubit extends Cubit<ProductosTerminadosState> {
  ProductosTerminadosCubit(this._repository, this._talker)
    : super(const ProductosTerminadosState.loading());

  final OrdenesProduccionRepository _repository;
  final Talker _talker;

  Future<void> initialize() async {
    _talker.cubit('Inicializando modulo de productos terminados.');
    emit(const ProductosTerminadosState.loading());
    try {
      final items = await _repository.listProductosTerminados();
      _talker.cubit(
        'Se cargaron ${items.length} productos terminados para la bandeja.',
      );
      emit(
        state.copyWith(
          status: ProductosTerminadosStatus.success,
          items: items,
          filteredItems: items,
          selectedItem: items.isEmpty ? null : items.first,
          searchTerm: '',
          clearError: true,
        ),
      );
    } on ApiException catch (exception) {
      _talker.cubit(
        'No se pudo cargar la lista de productos terminados: ${exception.message}',
        logLevel: LogLevel.error,
        exception: exception,
      );
      emit(
        state.copyWith(
          status: ProductosTerminadosStatus.error,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      _talker.cubit(
        'Fallo inesperado al cargar la lista de productos terminados.',
        logLevel: LogLevel.error,
      );
      emit(
        state.copyWith(
          status: ProductosTerminadosStatus.error,
          errorMessage: 'No pudimos cargar los productos terminados.',
        ),
      );
    }
  }

  void applySearch(String term) {
    final normalized = term.trim().toLowerCase();
    _talker.cubit(
      'Aplicando busqueda en productos terminados con texto=${_describeText(term)}.',
      logLevel: LogLevel.debug,
    );
    final filtered = state.items
        .where((item) {
          if (normalized.isEmpty) {
            return true;
          }
          return item.codigo.toLowerCase().contains(normalized) ||
              item.ordenCodigo.toLowerCase().contains(normalized) ||
              item.calidadCodigo.toLowerCase().contains(normalized) ||
              item.calidadNombre.toLowerCase().contains(normalized);
        })
        .toList(growable: false);

    ProductoTerminadoRecord? selected = state.selectedItem;
    if (selected == null || !filtered.any((item) => item.id == selected!.id)) {
      selected = filtered.isEmpty ? null : filtered.first;
    }
    _talker.cubit(
      'Busqueda de productos terminados devolvio ${filtered.length} resultados. Seleccion actual=${selected?.id ?? 'ninguna'}.',
      logLevel: LogLevel.debug,
    );

    emit(
      state.copyWith(
        filteredItems: filtered,
        selectedItem: selected,
        searchTerm: term,
      ),
    );
  }

  void selectItem(int id) {
    if (state.selectedItem?.id == id) {
      _talker.cubit(
        'Se ignoro la seleccion del producto terminado $id porque ya estaba activo.',
        logLevel: LogLevel.debug,
      );
      return;
    }

    ProductoTerminadoRecord? item;
    for (final candidate in state.filteredItems) {
      if (candidate.id == id) {
        item = candidate;
        break;
      }
    }
    if (item == null) {
      _talker.cubit(
        'Se intento seleccionar el producto terminado $id, pero no esta en la vista filtrada.',
        logLevel: LogLevel.warning,
      );
      return;
    }

    _talker.cubit('Seleccionando producto terminado $id para ver detalle.');
    emit(state.copyWith(selectedItem: item));
  }

  String _describeText(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'vacio';
    }

    return '${normalized.length} caracteres';
  }
}
