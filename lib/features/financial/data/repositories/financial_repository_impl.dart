import 'package:cond_manager/core/errors/app_exception.dart'
    show AppAuthException, AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/financial/data/models/financial_record_model.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/domain/repositories/financial_repository.dart';
import 'package:cond_manager/shared/domain/enums/financial_category.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinancialRepositoryImpl implements FinancialRepository {
  FinancialRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<FinancialRecord>>> list(FinancialListFilter filter) async {
    try {
      var query = _client.from('financial_records').select(FinancialRecordModel.selectQuery);

      query = query.eq('scope', filter.scope.value);

      if (filter.scope == FinancialScope.condominium && filter.condominiumId != null) {
        query = query.eq('condominium_id', filter.condominiumId!);
      }
      if (filter.recordType != null) {
        query = query.eq('record_type', filter.recordType!.value);
      }
      if (filter.category != null) {
        query = query.eq('category', filter.category!.value);
      }
      if (filter.fromDate != null) {
        query = query.gte('reference_date', _dateStr(filter.fromDate!));
      }
      if (filter.toDate != null) {
        query = query.lte('reference_date', _dateStr(filter.toDate!));
      }
      if (filter.paidOnly == true) {
        query = query.not('paid_at', 'is', null);
      } else if (filter.paidOnly == false) {
        query = query.isFilter('paid_at', null);
      }

      final data = await query.order('reference_date', ascending: false);

      final list = (data as List<dynamic>)
          .map((e) =>
              FinancialRecordModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar lançamentos: $e'));
    }
  }

  @override
  Future<Result<FinancialRecord>> getById(String id) async {
    try {
      final row = await _client
          .from('financial_records')
          .select(FinancialRecordModel.selectQuery)
          .eq('id', id)
          .single();

      return Success(
        FinancialRecordModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar lançamento: $e'));
    }
  }

  @override
  Future<Result<FinancialRecord>> create(FinancialRecordCreateInput input) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      if (input.scope == FinancialScope.condominium && input.condominiumId == null) {
        return const Failure(NetworkException('Selecione o condomínio.'));
      }

      final row = await _client
          .from('financial_records')
          .insert(FinancialRecordModel.createPayload(input, createdBy: userId))
          .select(FinancialRecordModel.selectQuery)
          .single();

      return Success(
        FinancialRecordModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao criar lançamento: $e'));
    }
  }

  @override
  Future<Result<FinancialRecord>> update(
    String id,
    FinancialRecordUpdateInput input,
  ) async {
    try {
      final row = await _client
          .from('financial_records')
          .update(FinancialRecordModel.updatePayload(input))
          .eq('id', id)
          .select(FinancialRecordModel.selectQuery)
          .single();

      return Success(
        FinancialRecordModel.fromJson(row as Map<String, dynamic>).toEntity(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar lançamento: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _client.from('financial_records').delete().eq('id', id);
      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao excluir lançamento: $e'));
    }
  }

  @override
  Future<Result<FinancialReportSummary>> reportSummary({
    required FinancialScope scope,
    String? condominiumId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final filter = FinancialListFilter(
      scope: scope,
      condominiumId: condominiumId,
      fromDate: fromDate,
      toDate: toDate,
    );
    final listResult = await list(filter);
    return listResult.when(
      success: (records) => Success(_buildSummary(records, scope, condominiumId)),
      failure: Failure.new,
    );
  }

  FinancialReportSummary _buildSummary(
    List<FinancialRecord> records,
    FinancialScope scope,
    String? condominiumId,
  ) {
    var expenses = 0.0;
    var income = 0.0;
    var taxes = 0.0;
    var labor = 0.0;
    var materials = 0.0;
    var freight = 0.0;
    var contracted = 0.0;
    var personnel = 0.0;

    final catMap = <FinancialCategory, ({double exp, double inc})>{};

    for (final r in records) {
      final total = r.totalWithTax;
      taxes += r.taxAmount;

      if (r.recordType == FinancialRecordType.income) {
        income += total;
      } else {
        expenses += total;
      }

      final cur = catMap[r.category] ?? (exp: 0.0, inc: 0.0);
      if (r.recordType == FinancialRecordType.income) {
        catMap[r.category] = (exp: cur.exp, inc: cur.inc + total);
      } else {
        catMap[r.category] = (exp: cur.exp + total, inc: cur.inc);
      }

      switch (r.category) {
        case FinancialCategory.laborHour:
          labor += total;
        case FinancialCategory.materials:
          materials += total;
        case FinancialCategory.freight:
          freight += total;
        case FinancialCategory.contractedServices:
          contracted += total;
        case FinancialCategory.personnel:
          personnel += total;
        case FinancialCategory.tax:
          taxes += r.amount;
        default:
          break;
      }
    }

    final breakdown = FinancialCategory.values
        .where((c) => catMap.containsKey(c))
        .map(
          (c) => FinancialCategoryBreakdown(
            category: c,
            expenses: catMap[c]!.exp,
            income: catMap[c]!.inc,
          ),
        )
        .toList()
      ..sort((a, b) => b.expenses.compareTo(a.expenses));

    String? condoName;
    if (records.isNotEmpty && scope == FinancialScope.condominium) {
      condoName = records.first.condominiumName;
    }

    return FinancialReportSummary(
      scope: scope,
      condominiumId: condominiumId,
      condominiumName: condoName,
      totalExpenses: expenses,
      totalIncome: income,
      totalTaxes: taxes,
      totalLabor: labor,
      totalMaterials: materials,
      totalFreight: freight,
      totalContractedServices: contracted,
      totalPersonnel: personnel,
      recordCount: records.length,
      byCategory: breakdown,
    );
  }

  static String _dateStr(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    return x.toIso8601String().split('T').first;
  }

  AppException _mapError(PostgrestException e) {
    if (e.code == '42501' || e.message.contains('permission')) {
      return PermissionException(e.message);
    }
    return NetworkException(e.message);
  }
}
