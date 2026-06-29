import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/rental/domain/entities/tenant_intake_form_models.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';

abstract class TenantIntakeRepository {
  Future<Result<TenantIntakeLinkPreview>> getLinkPreview(String token);

  Future<Result<String>> saveDraft({
    required String token,
    required Map<String, dynamic> formData,
    String? submissionId,
  });

  Future<Result<TenantIntakeSubmitResult>> submit({
    required String token,
    required Map<String, dynamic> formData,
    String? submissionId,
    String? ipAddress,
    String? userAgent,
  });

  Future<Result<TenantIntakeCreatedLink>> createLink({
    required String companyId,
    required RentalPartyCategory category,
    required String createdByProfileId,
    int expirationHours,
    String? label,
  });
}
