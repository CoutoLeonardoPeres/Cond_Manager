import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart';
import 'package:cond_manager/features/materials/domain/entities/material_supplier.dart';

abstract class MaterialRepository {
  Future<Result<List<Material>>> list(MaterialListFilter filter);

  Future<Result<Material>> getById(String id);

  Future<Result<Material>> create(MaterialCreateInput input);

  Future<Result<Material>> update(String id, MaterialUpdateInput input);

  Future<Result<List<MaterialCategory>>> listCategories(String condominiumId);

  Future<Result<MaterialCategory>> createCategory({
    required String condominiumId,
    required String name,
    String? description,
  });

  Future<Result<List<ProviderPickerForMaterial>>> listSuppliers(String condominiumId);

  Future<Result<List<String>>> listSupplierIdsForMaterial(String materialId);

  Future<Result<void>> syncMaterialSuppliers({
    required String materialId,
    required String condominiumId,
    required List<String> providerIds,
    String? primaryProviderId,
  });

  Future<Result<List<MaterialSupplierListItem>>> listMaterialSuppliers(
    MaterialSupplierListFilter filter,
  );

  Future<Result<MaterialSupplierDetail>> getMaterialSupplier(String providerId);

  Future<Result<MaterialSupplierDetail>> createMaterialSupplier(
    MaterialSupplierSaveInput input,
  );

  Future<Result<MaterialSupplierDetail>> updateMaterialSupplier(
    String providerId,
    MaterialSupplierSaveInput input,
  );

  Future<Result<List<StockMovement>>> listStockMovements(String materialId);

  Future<Result<StockMovement>> createStockMovement(StockMovementInput input);

  Future<Result<MaterialBalanceSummary>> balanceSummary({
    String? condominiumId,
  });
}
