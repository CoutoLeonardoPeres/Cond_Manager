import 'package:cond_manager/core/errors/app_exception.dart'
    show AppException, NetworkException, PermissionException;
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/modules/domain/repositories/company_modules_repository.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyModulesRepositoryImpl implements CompanyModulesRepository {
  CompanyModulesRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<CompanyModuleRow>>> listCompanyModules() async {
    try {
      final companies = await _client
          .from('management_companies')
          .select('id, legal_name, trade_name')
          .order('legal_name');

      final modules = await _client
          .from('company_modules')
          .select('company_id, module, status')
          .eq('status', 'active');

      final moduleMap = <String, Set<AppModule>>{};
      for (final raw in modules as List<dynamic>) {
        final m = raw as Map<String, dynamic>;
        final cid = m['company_id'] as String;
        moduleMap.putIfAbsent(cid, () => {});
        moduleMap[cid]!.add(AppModule.fromValue(m['module'] as String));
      }

      final rows = (companies as List<dynamic>).map((raw) {
        final c = raw as Map<String, dynamic>;
        final id = c['id'] as String;
        final name = c['trade_name'] as String? ?? c['legal_name'] as String;
        final mods = moduleMap[id] ?? {};
        return CompanyModuleRow(
          companyId: id,
          companyName: name,
          maintenanceEnabled: mods.contains(AppModule.maintenance),
          rentalEnabled: mods.contains(AppModule.rental),
        );
      }).toList();

      return Success(rows);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar módulos: $e'));
    }
  }

  @override
  Future<Result<void>> setModuleEnabled({
    required String companyId,
    required AppModule module,
    required bool enabled,
  }) async {
    try {
      if (enabled) {
        await _client.from('company_modules').upsert({
          'company_id': companyId,
          'module': module.value,
          'status': 'active',
        }, onConflict: 'company_id,module');
      } else {
        await _client.from('company_modules').upsert({
          'company_id': companyId,
          'module': module.value,
          'status': 'inactive',
        }, onConflict: 'company_id,module');
      }
      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao atualizar módulo: $e'));
    }
  }

  AppException _mapError(PostgrestException e) {
    if (e.code == '42501' || e.message.contains('permission')) {
      return PermissionException(e.message);
    }
    return NetworkException(e.message);
  }
}
