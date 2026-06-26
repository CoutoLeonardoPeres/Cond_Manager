import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/shared/domain/enums/app_module.dart';

abstract class CompanyModulesRepository {
  Future<Result<List<CompanyModuleRow>>> listCompanyModules();

  Future<Result<void>> setModuleEnabled({
    required String companyId,
    required AppModule module,
    required bool enabled,
  });
}
