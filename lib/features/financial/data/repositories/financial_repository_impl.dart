import 'dart:typed_data';

import 'package:cond_manager/core/errors/app_exception.dart'
    show AppAuthException, AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/financial/data/models/financial_record_model.dart';
import 'package:cond_manager/features/financial/domain/entities/financial_record.dart';
import 'package:cond_manager/features/financial/domain/repositories/financial_repository.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_expense_attachment.dart';
import 'package:cond_manager/features/rental/domain/utils/rental_expense_allocation.dart';
import 'package:cond_manager/shared/domain/enums/financial_category.dart';
import 'package:cond_manager/shared/domain/enums/financial_record_type.dart';
import 'package:cond_manager/shared/domain/enums/financial_scope.dart';
import 'package:cond_manager/shared/domain/enums/rental_expense_entry_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FinancialRepositoryImpl implements FinancialRepository {
  FinancialRepositoryImpl(this._client);

  final SupabaseClient _client;
  static const _expenseReceiptsBucket = 'rental-expense-receipts';

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
      if (filter.excludeRentalModule) {
        query = query
            .isFilter('rental_expense_entry_type', null)
            .isFilter('allocation_parent_id', null)
            .isFilter('rental_charge_id', null);
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
  Future<Result<List<FinancialRecord>>> listRentalExpenses({
    String? condominiumId,
    String? unitId,
  }) async {
    try {
      var query = _client
          .from('financial_records')
          .select(FinancialRecordModel.selectQuery)
          .eq('scope', FinancialScope.condominium.value)
          .not('rental_expense_entry_type', 'is', null)
          .isFilter('allocation_parent_id', null);

      if (condominiumId != null) {
        query = query.eq('condominium_id', condominiumId);
      }
      if (unitId != null) {
        query = query.eq('unit_id', unitId);
      }

      final data = await query.order('created_at').order('reference_date');

      final list = (data as List<dynamic>)
          .map((e) =>
              FinancialRecordModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();

      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar despesas: $e'));
    }
  }

  @override
  Future<Result<int>> generateRecurringRentalExpenses({
    String? condominiumId,
    required DateTime month,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final targetStart = DateTime(month.year, month.month, 1);
      final targetEnd = DateTime(month.year, month.month + 1, 0);
      final previousMonth = DateTime(month.year, month.month - 1, 1);
      final prevStart = DateTime(previousMonth.year, previousMonth.month, 1);
      final prevEnd = DateTime(previousMonth.year, previousMonth.month + 1, 0);

      var sourceQuery = _client
          .from('financial_records')
          .select(FinancialRecordModel.selectQuery)
          .eq('rental_expense_entry_type', RentalExpenseEntryType.fixedBill.value)
          .eq('is_recurring_template', false)
          .isFilter('allocation_parent_id', null)
          .gte('reference_date', _dateStr(prevStart))
          .lte('reference_date', _dateStr(prevEnd));

      if (condominiumId != null) {
        sourceQuery = sourceQuery.eq('condominium_id', condominiumId);
      }

      final sources = await sourceQuery;
      var created = 0;

      for (final row in sources as List<dynamic>) {
        final source =
            FinancialRecordModel.fromJson(row as Map<String, dynamic>).toEntity();
        if (source.condominiumId == null) continue;

        var dupQuery = _client
            .from('financial_records')
            .select('id')
            .eq('rental_expense_entry_type', RentalExpenseEntryType.fixedBill.value)
            .eq('is_recurring_template', false)
            .isFilter('allocation_parent_id', null)
            .eq('condominium_id', source.condominiumId!)
            .gte('reference_date', _dateStr(targetStart))
            .lte('reference_date', _dateStr(targetEnd));

        if (source.recurrenceTemplateId != null) {
          dupQuery = dupQuery.eq('recurrence_template_id', source.recurrenceTemplateId!);
        } else {
          dupQuery = dupQuery.eq('description', source.description);
          if (source.unitId != null) {
            dupQuery = dupQuery.eq('unit_id', source.unitId!);
          } else if (source.rentalPropertyId != null) {
            dupQuery = dupQuery.eq('rental_property_id', source.rentalPropertyId!);
          } else {
            dupQuery = dupQuery.isFilter('unit_id', null);
            dupQuery = dupQuery.isFilter('rental_property_id', null);
          }
          if (source.condominiumBillType != null) {
            dupQuery = dupQuery.eq('condominium_bill_type', source.condominiumBillType!.value);
          }
        }

        final existing = await dupQuery.maybeSingle();
        if (existing != null) continue;

        final refDate = _shiftDateToMonth(source.referenceDate, month.year, month.month);
        final dueDate = source.dueDate != null
            ? _shiftDateToMonth(source.dueDate!, month.year, month.month)
            : null;

        await _client.from('financial_records').insert({
          'scope': FinancialScope.condominium.value,
          'condominium_id': source.condominiumId,
          'record_type': FinancialRecordType.expense.value,
          'category': source.category.value,
          'description': source.description,
          'amount': 0,
          'tax_amount': 0,
          'reference_date': _dateStr(refDate),
          if (dueDate != null) 'due_date': _dateStr(dueDate),
          if (source.unitId != null) 'unit_id': source.unitId,
          if (source.rentalPropertyId != null) 'rental_property_id': source.rentalPropertyId,
          if (source.blockId != null) 'block_id': source.blockId,
          'rental_expense_entry_type': source.rentalExpenseEntryType!.value,
          if (source.condominiumBillType != null)
            'condominium_bill_type': source.condominiumBillType!.value,
          if (source.expenseServiceType != null)
            'expense_service_type': source.expenseServiceType!.value,
          if (source.materialCategoryId != null)
            'material_category_id': source.materialCategoryId,
          'is_recurring_template': false,
          if (source.recurrenceTemplateId != null)
            'recurrence_template_id': source.recurrenceTemplateId,
          'recurrence_active': true,
          if (source.recurrenceDayOfMonth != null)
            'recurrence_day_of_month': source.recurrenceDayOfMonth,
          'created_by': userId,
          if (source.notes != null) 'notes': source.notes,
        });

        created++;
      }

      return Success(created);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao gerar despesas fixas: $e'));
    }
  }

  DateTime _shiftDateToMonth(DateTime from, int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = from.day.clamp(1, lastDay);
    return DateTime(year, month, day);
  }

  @override
  Future<Result<List<FinancialRecord>>> listRentalExpenseAllocations(String parentId) async {
    try {
      final data = await _client
          .from('financial_records')
          .select(FinancialRecordModel.selectQuery)
          .eq('allocation_parent_id', parentId)
          .order('reference_date');

      final list = (data as List<dynamic>)
          .map((e) => FinancialRecordModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar rateio: $e'));
    }
  }

  @override
  Future<Result<List<FinancialRecord>>> allocateRentalExpenseToUnits({
    required String expenseId,
    required String method,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      final parentResult = await getById(expenseId);
      FinancialRecord? parent;
      AppException? loadError;
      parentResult.when(
        success: (p) => parent = p,
        failure: (e) => loadError = e,
      );
      if (loadError != null) return Failure(loadError!);
      final p = parent!;

      if (p.condominiumId == null) {
        return const Failure(NetworkException('Despesa sem condomínio.'));
      }
      if (p.unitId != null) {
        return const Failure(NetworkException('Despesa já vinculada a uma unidade.'));
      }
      if (!p.isRentalModuleExpense) {
        return const Failure(NetworkException('Apenas despesas do módulo locação podem ser rateadas.'));
      }

      final existing = await _client
          .from('financial_records')
          .select('id')
          .eq('allocation_parent_id', expenseId)
          .limit(1);
      if ((existing as List).isNotEmpty) {
        return const Failure(NetworkException('Esta despesa já foi rateada entre unidades.'));
      }

      final targetsResult = await _loadRentalExpenseAllocationTargets(p);
      List<RentalExpenseAllocationTarget>? targets;
      AppException? targetsError;
      targetsResult.when(
        success: (list) => targets = list,
        failure: (e) => targetsError = e,
      );
      if (targetsError != null) return Failure(targetsError!);
      final allocationTargets = targets!;
      if (allocationTargets.isEmpty) {
        return const Failure(
          NetworkException('Nenhuma unidade ou imóvel ativo neste condomínio.'),
        );
      }

      final weights = <({String unitId, double weight})>[];
      for (final target in allocationTargets) {
        if (method == RentalExpenseAllocationMethod.byArea.value) {
          final area = target.areaSqm ?? 0;
          if (area <= 0) {
            return const Failure(
              NetworkException(
                'Rateio por metragem exige área (m²) cadastrada em todas as unidades/imóveis.',
              ),
            );
          }
          weights.add((unitId: target.id, weight: area));
        } else {
          weights.add((unitId: target.id, weight: 1.0));
        }
      }

      final shares = computeUnitAllocationShares(
        totalAmount: p.totalWithTax,
        units: weights,
      );

      final created = <FinancialRecord>[];
      for (final target in allocationTargets) {
        final amount = shares[target.id] ?? 0;
        if (amount <= 0) continue;

        final input = FinancialRecordCreateInput(
          scope: FinancialScope.condominium,
          condominiumId: p.condominiumId,
          recordType: p.recordType,
          category: p.category,
          description: '${p.description} — ${target.label}',
          amount: amount,
          taxAmount: 0,
          referenceDate: p.referenceDate,
          dueDate: p.dueDate,
          paidAt: p.paidAt,
          notes: p.notes,
          unitId: target.unitId,
          rentalPropertyId: target.rentalPropertyId,
          rentalExpenseEntryType: p.rentalExpenseEntryType,
          condominiumBillType: p.condominiumBillType,
          expenseServiceType: p.expenseServiceType,
          materialCategoryId: p.materialCategoryId,
          allocationParentId: p.id,
        );

        final rowInsert = await _client
            .from('financial_records')
            .insert(FinancialRecordModel.createPayload(input, createdBy: userId))
            .select(FinancialRecordModel.selectQuery)
            .single();
        created.add(
          FinancialRecordModel.fromJson(rowInsert as Map<String, dynamic>).toEntity(),
        );
      }

      return Success(created);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao ratear despesa: $e'));
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
      if (input.scope == FinancialScope.managementCompany && input.managementCompanyId == null) {
        return const Failure(NetworkException('Empresa gestora não identificada.'));
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
    bool excludeRentalModule = false,
  }) async {
    final filter = FinancialListFilter(
      scope: scope,
      condominiumId: condominiumId,
      fromDate: fromDate,
      toDate: toDate,
      excludeRentalModule: excludeRentalModule,
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

  Future<Result<List<RentalExpenseAllocationTarget>>> _loadRentalExpenseAllocationTargets(
    FinancialRecord parent,
  ) async {
    try {
      var unitsQuery = _client
          .from('units')
          .select('id, identifier, area_sqm')
          .eq('condominium_id', parent.condominiumId!)
          .eq('status', 'active');
      if (parent.blockId != null) {
        unitsQuery = unitsQuery.eq('block_id', parent.blockId!);
      }
      final unitsData = await unitsQuery.order('identifier');
      final units = unitsData as List<dynamic>;
      if (units.isNotEmpty) {
        return Success(
          units
              .map(
                (row) => RentalExpenseAllocationTarget(
                  id: row['id'] as String,
                  label: row['identifier'] as String,
                  areaSqm: row['area_sqm'] != null
                      ? double.tryParse(row['area_sqm'].toString())
                      : null,
                  unitId: row['id'] as String,
                ),
              )
              .toList(),
        );
      }

      final propertiesData = await _client
          .from('rental_properties')
          .select('id, title, area_sqm')
          .eq('condominium_id', parent.condominiumId!)
          .eq('status', 'active')
          .order('title');
      final properties = propertiesData as List<dynamic>;
      return Success(
        properties
            .map(
              (row) => RentalExpenseAllocationTarget(
                id: row['id'] as String,
                label: row['title'] as String,
                areaSqm: row['area_sqm'] != null
                    ? double.tryParse(row['area_sqm'].toString())
                    : null,
                rentalPropertyId: row['id'] as String,
              ),
            )
            .toList(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar destinos de rateio: $e'));
    }
  }

  @override
  Future<Result<List<RentalExpenseAttachment>>> listRentalExpenseAttachments(
    String financialRecordId,
  ) async {
    try {
      final data = await _client
          .from('rental_expense_attachments')
          .select()
          .eq('financial_record_id', financialRecordId)
          .order('created_at');

      final attachments = <RentalExpenseAttachment>[];
      for (final raw in data as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        var url = map['file_url'] as String? ?? '';
        final path = map['file_path'] as String? ?? '';
        if (path.isNotEmpty) {
          url = await _client.storage.from(_expenseReceiptsBucket).createSignedUrl(path, 3600);
        }
        attachments.add(_attachmentFromMap(map, fileUrl: url));
      }
      return Success(attachments);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar anexos: $e'));
    }
  }

  @override
  Future<Result<void>> uploadRentalExpenseAttachments({
    required String financialRecordId,
    required String companyId,
    required List<PendingRentalExpenseAttachment> files,
  }) async {
    if (files.isEmpty) return const Success(null);

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      const uuid = Uuid();
      for (final file in files) {
        final safeName = file.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final path = '$companyId/$financialRecordId/${uuid.v4()}_$safeName';

        await _client.storage.from(_expenseReceiptsBucket).uploadBinary(
              path,
              file.bytes,
              fileOptions: FileOptions(contentType: file.mimeType, upsert: false),
            );

        final signedUrl =
            await _client.storage.from(_expenseReceiptsBucket).createSignedUrl(path, 86400);

        await _client.from('rental_expense_attachments').insert({
          'financial_record_id': financialRecordId,
          'company_id': companyId,
          'file_url': signedUrl,
          'file_path': path,
          'file_name': file.fileName,
          'mime_type': file.mimeType,
          'uploaded_by': userId,
        });
      }

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao enviar anexos: $e'));
    }
  }

  @override
  Future<Result<void>> deleteRentalExpenseAttachment(
    RentalExpenseAttachment attachment,
  ) async {
    try {
      if (attachment.filePath.isNotEmpty) {
        await _client.storage.from(_expenseReceiptsBucket).remove([attachment.filePath]);
      }
      await _client.from('rental_expense_attachments').delete().eq('id', attachment.id);
      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao remover anexo: $e'));
    }
  }

  RentalExpenseAttachment _attachmentFromMap(
    Map<String, dynamic> map, {
    required String fileUrl,
  }) {
    return RentalExpenseAttachment(
      id: map['id'] as String,
      financialRecordId: map['financial_record_id'] as String,
      companyId: map['company_id'] as String,
      fileUrl: fileUrl,
      filePath: map['file_path'] as String? ?? '',
      fileName: map['file_name'] as String?,
      mimeType: map['mime_type'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
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
