import 'package:cond_manager/core/errors/app_exception.dart';
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/rental/domain/entities/tenant_intake_form_models.dart';
import 'package:cond_manager/features/rental/domain/repositories/tenant_intake_repository.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TenantIntakeRepositoryImpl implements TenantIntakeRepository {
  TenantIntakeRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<TenantIntakeLinkPreview>> getLinkPreview(String token) async {
    try {
      final data = await _client.rpc(
        'get_rental_tenant_intake_preview',
        params: {'p_token': token},
      );
      final row = (data as List).isNotEmpty ? data.first as Map<String, dynamic> : <String, dynamic>{};
      return Success(TenantIntakeLinkPreview.fromJson(row));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar formulário: $e'));
    }
  }

  @override
  Future<Result<String>> saveDraft({
    required String token,
    required Map<String, dynamic> formData,
    String? submissionId,
  }) async {
    try {
      final data = await _client.rpc(
        'save_rental_tenant_intake_draft',
        params: {
          'p_token': token,
          'p_form_data': formData,
          'p_submission_id': submissionId,
        },
      );
      return Success(data as String);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao salvar rascunho: $e'));
    }
  }

  @override
  Future<Result<TenantIntakeSubmitResult>> submit({
    required String token,
    required Map<String, dynamic> formData,
    String? submissionId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final data = await _client.rpc(
        'submit_rental_tenant_intake',
        params: {
          'p_token': token,
          'p_form_data': formData,
          'p_submission_id': submissionId,
          'p_ip_address': ipAddress,
          'p_user_agent': userAgent,
        },
      );
      final row = (data as List).first as Map<String, dynamic>;
      return Success(TenantIntakeSubmitResult.fromJson(row));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao enviar formulário: $e'));
    }
  }

  @override
  Future<Result<TenantIntakeCreatedLink>> createLink({
    required String companyId,
    required RentalPartyCategory category,
    required String createdByProfileId,
    int expirationHours = 72,
    String? label,
  }) async {
    try {
      final expiresAt = DateTime.now().toUtc().add(Duration(hours: expirationHours));
      final data = await _client
          .from('rental_tenant_intake_links')
          .insert({
            'company_id': companyId,
            'category': category.value,
            'created_by': createdByProfileId,
            'expires_at': expiresAt.toIso8601String(),
            if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
          })
          .select('id, token, expires_at, category')
          .single();

      final map = data;
      return Success(
        TenantIntakeCreatedLink(
          id: map['id'] as String,
          token: map['token'] as String,
          expiresAt: DateTime.parse(map['expires_at'] as String),
          category: map['category'] as String,
        ),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao gerar link: $e'));
    }
  }

  AppException _mapError(PostgrestException e) {
    final message = e.message.contains('restrição')
        ? e.message
        : e.message.contains('expirou')
            ? 'Este link expirou. Solicite um novo link à imobiliária.'
            : e.message.contains('inválido') || e.message.contains('não encontrado')
                ? 'Link inválido ou não encontrado.'
                : e.message;
    return NetworkException(message);
  }
}
