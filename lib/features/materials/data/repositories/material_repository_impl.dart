import 'package:cond_manager/core/errors/app_exception.dart'
    show AppAuthException, AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/materials/data/models/material_model.dart';
import 'package:cond_manager/features/materials/data/models/material_supplier_model.dart';
import 'package:cond_manager/features/materials/data/models/material_supplier_purchase_model.dart';
import 'package:cond_manager/features/materials/domain/default_material_categories.dart';
import 'package:cond_manager/features/materials/domain/entities/material.dart';
import 'package:cond_manager/features/materials/domain/entities/material_supplier.dart';
import 'package:cond_manager/shared/domain/enums/provider_type.dart';
import 'package:cond_manager/features/materials/domain/repositories/material_repository.dart';
import 'package:cond_manager/shared/domain/enums/entity_status.dart';
import 'package:cond_manager/shared/domain/enums/stock_movement_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialRepositoryImpl implements MaterialRepository {
  MaterialRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<Material>>> list(MaterialListFilter filter) async {
    try {
      var query = _client.from('materials').select(MaterialModel.materialSelect);

      if (filter.condominiumId != null) {
        query = query.eq('condominium_id', filter.condominiumId!);
      }
      if (filter.categoryId != null) {
        query = query.eq('category_id', filter.categoryId!);
      }
      if (filter.itemType != null) {
        query = query.eq('item_type', filter.itemType!.value);
      }
      if (filter.status != null) {
        query = query.eq('status', filter.status!.value);
      }
      if (filter.serviceType != null) {
        query = query.contains('applicable_services', [filter.serviceType!.value]);
      }

      final data = await query.order('name');

      var list = (data as List<dynamic>)
          .map((e) => MaterialModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      if (filter.lowStockOnly) {
        list = list.where((m) => m.isLowStock).toList();
      }

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar materiais: $e'));
    }
  }

  @override
  Future<Result<Material>> getById(String id) async {
    try {
      final row = await _client
          .from('materials')
          .select(MaterialModel.materialSelect)
          .eq('id', id)
          .single();

      return Success(
        MaterialModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar material: $e'));
    }
  }

  @override
  Future<Result<Material>> create(MaterialCreateInput input) async {
    try {
      if (_client.auth.currentUser == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final row = await _client
          .from('materials')
          .insert(MaterialModel.createPayload(input))
          .select(MaterialModel.materialSelect)
          .single();

      return Success(
        MaterialModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao cadastrar material: $e'));
    }
  }

  @override
  Future<Result<Material>> update(String id, MaterialUpdateInput input) async {
    try {
      final row = await _client
          .from('materials')
          .update(MaterialModel.updatePayload(input))
          .eq('id', id)
          .select(MaterialModel.materialSelect)
          .single();

      return Success(
        MaterialModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar material: $e'));
    }
  }

  @override
  Future<Result<List<MaterialCategory>>> listCategories(String condominiumId) async {
    try {
      final data = await _client
          .from('material_categories')
          .select()
          .eq('condominium_id', condominiumId)
          .order('name');

      final list = (data as List<dynamic>)
          .map((e) => MaterialCategoryModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar categorias: $e'));
    }
  }

  @override
  Future<Result<MaterialCategory>> createCategory({
    required String condominiumId,
    required String name,
    String? description,
  }) async {
    try {
      final row = await _client
          .from('material_categories')
          .insert({
            'condominium_id': condominiumId,
            'name': name.trim(),
            'description': description?.trim(),
          })
          .select()
          .single();

      return Success(
        MaterialCategoryModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao criar categoria: $e'));
    }
  }

  @override
  Future<Result<List<MaterialCategory>>> ensureDefaultCategories(
    String condominiumId,
  ) async {
    try {
      final existing = await listCategories(condominiumId);
      final current = existing.when(
        success: (list) => list,
        failure: (e) => throw e,
      );
      if (current.isNotEmpty) return Success(current);

      final rows = defaultMaterialCategorySeeds
          .map(
            (seed) => {
              'condominium_id': condominiumId,
              'name': seed.name,
              'description': seed.description,
            },
          )
          .toList();

      await _client.from('material_categories').upsert(
            rows,
            onConflict: 'condominium_id,name',
            ignoreDuplicates: true,
          );

      return listCategories(condominiumId);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar categorias padrão: $e'));
    }
  }

  @override
  Future<Result<List<ProviderPickerForMaterial>>> listSuppliers(
    String condominiumId,
  ) async {
    try {
      final data = await _client
          .from('providers')
          .select('id, trade_name, legal_name')
          .eq('condominium_id', condominiumId)
          .eq('provider_type', ProviderType.supplier.value)
          .eq('status', EntityStatus.active.value)
          .order('legal_name');

      final list = (data as List<dynamic>).map((raw) {
        final map = raw as Map<String, dynamic>;
        final label = (map['trade_name'] as String?)?.trim().isNotEmpty == true
            ? map['trade_name'] as String
            : map['legal_name'] as String;
        return ProviderPickerForMaterial(id: map['id'] as String, label: label);
      }).toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar fornecedores: $e'));
    }
  }

  @override
  Future<Result<List<String>>> listSupplierIdsForMaterial(String materialId) async {
    try {
      final data = await _client
          .from('material_supplier_links')
          .select('provider_id')
          .eq('material_id', materialId);

      final ids = (data as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['provider_id'] as String)
          .toList();
      return Success(ids);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar fornecedores do material: $e'));
    }
  }

  @override
  Future<Result<void>> syncMaterialSuppliers({
    required String materialId,
    required String condominiumId,
    required List<String> providerIds,
    String? primaryProviderId,
  }) async {
    try {
      await _client.from('material_supplier_links').delete().eq('material_id', materialId);

      String? primary = primaryProviderId;
      if (providerIds.isNotEmpty) {
        primary ??= providerIds.first;
        final rows = providerIds
            .map(
              (pid) => {
                'material_id': materialId,
                'provider_id': pid,
                'condominium_id': condominiumId,
                'is_primary': pid == primary,
              },
            )
            .toList();
        await _client.from('material_supplier_links').insert(rows);
      } else {
        primary = null;
      }

      await _client.from('materials').update({'provider_id': primary}).eq('id', materialId);

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao vincular fornecedores: $e'));
    }
  }

  Future<Result<void>> _syncSupplierMaterials(MaterialSupplierSaveInput input, String providerId) async {
    await _client.from('material_supplier_links').delete().eq('provider_id', providerId);

    if (input.materialIds.isEmpty) return const Success(null);

    final rows = <Map<String, dynamic>>[];
    for (final materialId in input.materialIds) {
      final existing = await _client
          .from('material_supplier_links')
          .select('is_primary')
          .eq('material_id', materialId);

      final hasPrimary = (existing as List<dynamic>).any(
        (e) => (e as Map<String, dynamic>)['is_primary'] == true,
      );

      rows.add({
        'material_id': materialId,
        'provider_id': providerId,
        'condominium_id': input.condominiumId,
        'is_primary': !hasPrimary,
      });

      if (!hasPrimary) {
        await _client
            .from('materials')
            .update({'provider_id': providerId})
            .eq('id', materialId);
      }
    }

    await _client.from('material_supplier_links').insert(rows);
    return const Success(null);
  }

  @override
  Future<Result<List<MaterialSupplierListItem>>> listMaterialSuppliers(
    MaterialSupplierListFilter filter,
  ) async {
    try {
      var query = _client
          .from('providers')
          .select(MaterialSupplierModel.supplierSelect)
          .eq('provider_type', ProviderType.supplier.value);

      if (filter.condominiumId != null) {
        query = query.eq('condominium_id', filter.condominiumId!);
      }
      if (filter.status != null) {
        query = query.eq('status', filter.status!.value);
      }
      if (filter.serviceType != null) {
        query = query.contains('specialties', [filter.serviceType!.value]);
      }

      final data = await query.order('legal_name');

      final list = (data as List<dynamic>)
          .map(
            (e) => MaterialSupplierModel.listItemFromProviderJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar fornecedores: $e'));
    }
  }

  @override
  Future<Result<MaterialSupplierDetail>> getMaterialSupplier(String providerId) async {
    try {
      final row = await _client
          .from('providers')
          .select(MaterialSupplierModel.supplierDetailSelect)
          .eq('id', providerId)
          .eq('provider_type', ProviderType.supplier.value)
          .single();

      return Success(
        MaterialSupplierModel.detailFromJson(row as Map<String, dynamic>),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar fornecedor: $e'));
    }
  }

  @override
  Future<Result<MaterialSupplierDetail>> createMaterialSupplier(
    MaterialSupplierSaveInput input,
  ) async {
    try {
      if (_client.auth.currentUser == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final row = await _client
          .from('providers')
          .insert(MaterialSupplierModel.createProviderPayload(input))
          .select(MaterialSupplierModel.supplierDetailSelect)
          .single();

      final providerId = (row as Map<String, dynamic>)['id'] as String;
      final sync = await _syncSupplierMaterials(input, providerId);
      return sync.when(
        success: (_) => getMaterialSupplier(providerId),
        failure: Failure.new,
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao cadastrar fornecedor: $e'));
    }
  }

  @override
  Future<Result<MaterialSupplierDetail>> updateMaterialSupplier(
    String providerId,
    MaterialSupplierSaveInput input,
  ) async {
    try {
      await _client
          .from('providers')
          .update(MaterialSupplierModel.updateProviderPayload(input))
          .eq('id', providerId);

      final sync = await _syncSupplierMaterials(input, providerId);
      return sync.when(
        success: (_) => getMaterialSupplier(providerId),
        failure: Failure.new,
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar fornecedor: $e'));
    }
  }

  @override
  Future<Result<List<StockMovement>>> listStockMovements(String materialId) async {
    try {
      final data = await _client
          .from('stock_movements')
          .select('''
            *,
            profiles!stock_movements_performed_by_fkey ( full_name )
          ''')
          .eq('material_id', materialId)
          .order('created_at', ascending: false);

      final list = (data as List<dynamic>).map((raw) {
        final map = raw as Map<String, dynamic>;
        String? performerName;
        final profile = map['profiles'];
        if (profile is Map<String, dynamic>) {
          performerName = profile['full_name'] as String?;
        }
        map['performer'] = profile != null ? {'full_name': performerName} : null;
        return StockMovementModel.fromJson(map).toEntity();
      }).toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar movimentações: $e'));
    }
  }

  @override
  Future<Result<StockMovement>> createStockMovement(StockMovementInput input) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final unitCost = input.unitCost ?? 0;
      final totalCost = unitCost * input.quantity;

      final row = await _client
          .from('stock_movements')
          .insert({
            'material_id': input.materialId,
            'condominium_id': input.condominiumId,
            'movement_type': input.movementType.value,
            'quantity': input.quantity,
            'unit_cost': unitCost > 0 ? unitCost : null,
            'total_cost': totalCost > 0 ? totalCost : null,
            'provider_id': input.providerId,
            'reference_type': input.referenceType,
            'reference_id': input.referenceId,
            'notes': input.notes?.trim(),
            'performed_by': userId,
          })
          .select()
          .single();

      return Success(
        StockMovementModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao registrar movimentação: $e'));
    }
  }

  @override
  Future<Result<List<MaterialSupplierPurchase>>> listSupplierPurchases(
    String materialId, {
    String? providerId,
  }) async {
    try {
      var query = _client
          .from('material_supplier_purchases')
          .select(MaterialSupplierPurchaseModel.selectQuery)
          .eq('material_id', materialId);

      if (providerId != null) {
        query = query.eq('provider_id', providerId);
      }

      final data = await query.order('purchased_at', ascending: false);

      final list = (data as List<dynamic>)
          .map(
            (e) => MaterialSupplierPurchaseModel.fromJson(
              e as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar compras do fornecedor: $e'));
    }
  }

  @override
  Future<Result<MaterialSupplierPurchase>> recordSupplierPurchase(
    MaterialSupplierPurchaseInput input,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final totalCost = input.unitCost * input.quantity;
      String? stockMovementId;

      if (input.registerStockEntry) {
        final movementResult = await createStockMovement(
          StockMovementInput(
            materialId: input.materialId,
            condominiumId: input.condominiumId,
            movementType: StockMovementType.entry,
            quantity: input.quantity,
            unitCost: input.unitCost,
            providerId: input.providerId,
            notes: input.notes,
          ),
        );

        final movement = movementResult.when(
          success: (m) => m,
          failure: (e) => throw e,
        );
        stockMovementId = movement.id;

        final existing = await _client
            .from('material_supplier_purchases')
            .select(MaterialSupplierPurchaseModel.selectQuery)
            .eq('stock_movement_id', stockMovementId)
            .maybeSingle();

        if (existing != null) {
          return Success(
            MaterialSupplierPurchaseModel.fromJson(
              existing as Map<String, dynamic>,
            ).toEntity(),
          );
        }
      }

      final row = await _client
          .from('material_supplier_purchases')
          .insert({
            'material_id': input.materialId,
            'provider_id': input.providerId,
            'condominium_id': input.condominiumId,
            'purchased_at': (input.purchasedAt ?? DateTime.now()).toUtc().toIso8601String(),
            'quantity': input.quantity,
            'unit_cost': input.unitCost,
            'purchase_tax_percent': input.purchaseTaxPercent,
            'total_cost': totalCost,
            'resale_unit_price': input.resaleUnitPrice,
            'resale_tax_percent': input.resaleTaxPercent,
            'stock_movement_id': stockMovementId,
            'invoice_number': input.invoiceNumber?.trim(),
            'notes': input.notes?.trim(),
            'created_by': userId,
          })
          .select(MaterialSupplierPurchaseModel.selectQuery)
          .single();

      return Success(
        MaterialSupplierPurchaseModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } on AppException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(NetworkException('Erro ao registrar compra: $e'));
    }
  }

  @override
  Future<Result<MaterialBalanceSummary>> balanceSummary({
    String? condominiumId,
  }) async {
    final filter = MaterialListFilter(
      condominiumId: condominiumId,
      status: EntityStatus.active,
    );
    final result = await list(filter);
    return result.when(
      success: (items) {
        var cost = 0.0;
        var resale = 0.0;
        var low = 0;
        for (final m in items) {
          if (m.isStorable) {
            cost += m.stockValueAtCost;
            resale += m.stockValueAtResale;
          }
          if (m.isLowStock) low++;
        }
        return Success(
          MaterialBalanceSummary(
            itemCount: items.length,
            lowStockCount: low,
            totalStockCost: cost,
            totalStockResale: resale,
            estimatedMargin: resale - cost,
          ),
        );
      },
      failure: Failure.new,
    );
  }

  AppException _mapError(PostgrestException e) {
    if (e.code == '42501' || e.message.contains('permission')) {
      return PermissionException(e.message);
    }
    return NetworkException(e.message);
  }
}
