import 'package:erp_curtiembre_fronted/features/inventory/stock/domain/entities/stock_record.dart';

abstract class StockRepository {
  Future<List<StockRecord>> listStock({
    String? texto,
    String? tipoBien,
    bool? stockBajo,
    bool? activo,
  });

  Future<List<StockRecord>> listLowStock({
    String? texto,
    String? tipoBien,
    bool? activo,
  });

  Future<StockRecord> getStockByInsumoId(int insumoId);
}
