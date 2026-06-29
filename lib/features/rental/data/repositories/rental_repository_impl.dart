import 'package:cond_manager/core/errors/app_exception.dart'
    show AppAuthException, AppException, NetworkException, PermissionException, ValidationException;
import 'package:cond_manager/core/formatters/brazilian_input_format.dart';
import 'package:cond_manager/core/utils/result.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_booking.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inputs.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_lease.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_party.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_inclusion_catalog_item.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_inclusion.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_photo.dart';
import 'package:cond_manager/features/rental/domain/entities/rental_property_pnl.dart';
import 'package:cond_manager/features/rental/domain/repositories/rental_repository.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_channel.dart';
import 'package:cond_manager/shared/domain/enums/rental_booking_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_charge_type.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_contract_enums.dart';
import 'package:cond_manager/shared/domain/enums/rental_lease_status.dart';
import 'package:cond_manager/shared/domain/enums/rental_inclusion_category.dart';
import 'package:cond_manager/shared/domain/enums/rental_listing_mode.dart';
import 'package:cond_manager/shared/domain/enums/rental_party_category.dart';
import 'package:cond_manager/shared/domain/enums/rental_property_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class RentalRepositoryImpl implements RentalRepository {
  RentalRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _propertySelect = '''
    id, company_id, condominium_id, owner_party_id, property_type, listing_mode,
    code, title, description, address_street, address_number, address_building, address_block,
    address_apartment, address_neighborhood, address_city, address_state, address_zip, area_sqm,
    bedrooms, bathrooms, max_guests, base_rent_amount, base_daily_rate, deposit_amount, status,
    registry_matricula, registry_cartorio, iptu_inscription, municipal_inscription,
    is_furnished, accepts_pets,
    condominiums ( name, city, state )
  ''';

  static const _partySelect = '''
    id, company_id, full_name, category, email, phone, document_number, notes, status,
    is_rental_restricted, restriction_reason, restricted_at,
    address_street, address_number, address_complement, address_neighborhood,
    address_city, address_state, address_zip, intake_metadata,
    nationality, rg_number, rg_issuer, profession, marital_status
  ''';

  @override
  Future<Result<List<RentalProperty>>> listProperties(
    RentalPropertyListFilter filter,
  ) async {
    try {
      var query = _client.from('rental_properties').select(_propertySelect);
      if (filter.propertyType != null) {
        query = query.eq('property_type', filter.propertyType!.value);
      }
      if (filter.listingMode != null) {
        query = query.eq('listing_mode', filter.listingMode!.value);
      }
      if (filter.condominiumId != null) {
        query = query.eq('condominium_id', filter.condominiumId!);
      }
      final data = await query.order('title').limit(300);
      final list = <RentalProperty>[];
      for (final raw in data as List<dynamic>) {
        final p = _propertyFromMap(raw as Map<String, dynamic>);
        if (filter.search?.trim().isNotEmpty == true) {
          final q = filter.search!.toLowerCase();
          if (!p.title.toLowerCase().contains(q) &&
              !(p.code?.toLowerCase().contains(q) ?? false)) {
            continue;
          }
        }
        list.add(p);
      }
      return Success(list);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar imóveis: $e'));
    }
  }

  @override
  Future<Result<RentalProperty>> getProperty(String id) async {
    try {
      final data = await _client
          .from('rental_properties')
          .select(_propertySelect)
          .eq('id', id)
          .single();
      return Success(_propertyFromMap(data));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao buscar imóvel: $e'));
    }
  }

  @override
  Future<Result<RentalProperty>> createProperty(RentalPropertyInput input) async {
    return _saveProperty(input);
  }

  @override
  Future<Result<RentalProperty>> updateProperty(
    String id,
    RentalPropertyInput input,
  ) async {
    return _saveProperty(input, id: id);
  }

  @override
  Future<Result<void>> deleteProperty(String id) async {
    try {
      final photos = await _client
          .from('rental_property_photos')
          .select('id, file_path')
          .eq('property_id', id);
      final photoIds = (photos as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['id'] as String)
          .toList();
      if (photoIds.isNotEmpty) {
        final photoResult = await deletePropertyPhotos(photoIds);
        if (photoResult case Failure(:final error)) {
          return Failure(error);
        }
      }

      final bookings = await _client.from('rental_bookings').select('id').eq('property_id', id);
      final bookingIds = (bookings as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['id'] as String)
          .toList();
      if (bookingIds.isNotEmpty) {
        await _client.from('rental_charges').delete().inFilter('booking_id', bookingIds);
        await _client.from('rental_bookings').delete().eq('property_id', id);
      }

      final leases = await _client.from('rental_leases').select('id').eq('property_id', id);
      final leaseIds = (leases as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['id'] as String)
          .toList();
      if (leaseIds.isNotEmpty) {
        await _client.from('rental_charges').delete().inFilter('lease_id', leaseIds);
        await _client.from('rental_lease_tenants').delete().inFilter('lease_id', leaseIds);
        await _client.from('rental_leases').delete().eq('property_id', id);
      }

      await _client.from('rental_properties').delete().eq('id', id);
      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao excluir imóvel: $e'));
    }
  }

  Future<Result<RentalProperty>> _saveProperty(
    RentalPropertyInput input, {
    String? id,
  }) async {
    try {
      final row = _propertyPayload(input);
      final dynamic data;
      if (id == null) {
        data = await _client.from('rental_properties').insert(row).select(_propertySelect).single();
      } else {
        data = await _client.from('rental_properties').update(row).eq('id', id).select(_propertySelect).single();
      }
      return Success(_propertyFromMap(data as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao salvar imóvel: $e'));
    }
  }

  @override
  Future<Result<List<RentalPropertyInclusion>>> listPropertyInclusions(String propertyId) async {
    try {
      final data = await _client
          .from('rental_property_inclusions')
          .select()
          .eq('property_id', propertyId)
          .order('sort_order')
          .order('created_at');
      return Success(
        (data as List).map((e) => _inclusionFromMap(e as Map<String, dynamic>)).toList(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar itens inclusos: $e'));
    }
  }

  @override
  Future<Result<void>> replacePropertyInclusions(
    String propertyId,
    String companyId,
    List<RentalPropertyInclusionInput> items,
  ) async {
    try {
      await _client.from('rental_property_inclusions').delete().eq('property_id', propertyId);

      if (items.isEmpty) return const Success(null);

      final rows = items.asMap().entries.map((entry) {
        final i = entry.value;
        final index = entry.key;
        return {
          'company_id': companyId,
          'property_id': propertyId,
          'category': i.category.value,
          'catalog_item_id': i.catalogItemId,
          'custom_name': i.customName?.trim(),
          'amount': i.amount,
          'included_in_rent': i.includedInRent,
          'quantity': i.quantity,
          'size_label': i.sizeLabel?.trim(),
          'model': i.model?.trim(),
          'chair_count': i.chairCount,
          'notes': i.notes?.trim(),
          'sort_order': i.sortOrder != 0 ? i.sortOrder : index,
        };
      }).toList();

      await _client.from('rental_property_inclusions').insert(rows);
      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao salvar itens inclusos: $e'));
    }
  }

  @override
  Future<Result<List<RentalInclusionCatalogItem>>> listInclusionCatalog(String companyId) async {
    try {
      final data = await _client
          .from('rental_inclusion_catalog')
          .select()
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('name');
      return Success(
        (data as List).map((e) => _catalogFromMap(e as Map<String, dynamic>)).toList(),
      );
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar catálogo: $e'));
    }
  }

  @override
  Future<Result<RentalInclusionCatalogItem>> createInclusionCatalogItem(
    RentalInclusionCatalogInput input,
  ) async {
    try {
      final data = await _client
          .from('rental_inclusion_catalog')
          .insert({
            'company_id': input.companyId,
            'name': input.name.trim(),
            'category': input.category.value,
            'default_amount': input.defaultAmount,
          })
          .select()
          .single();
      return Success(_catalogFromMap(data as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao cadastrar item no catálogo: $e'));
    }
  }

  static const _photosBucket = 'rental-properties';

  @override
  Future<Result<List<RentalPropertyPhoto>>> listPropertyPhotos(String propertyId) async {
    try {
      final data = await _client
          .from('rental_property_photos')
          .select()
          .eq('property_id', propertyId)
          .order('sort_order')
          .order('created_at');

      final photos = <RentalPropertyPhoto>[];
      for (final raw in data as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        var url = map['file_url'] as String? ?? '';
        final path = map['file_path'] as String? ?? '';
        if (path.isNotEmpty) {
          url = await _client.storage.from(_photosBucket).createSignedUrl(path, 3600);
        }
        photos.add(_photoFromMap(map, fileUrl: url));
      }
      return Success(photos);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar fotos: $e'));
    }
  }

  @override
  Future<Result<void>> uploadPropertyPhotos({
    required String propertyId,
    required String companyId,
    required List<PendingRentalPropertyPhoto> files,
    int sortOffset = 0,
  }) async {
    if (files.isEmpty) return const Success(null);

    try {
      final userId = _client.auth.currentUser?.id;
      const uuid = Uuid();

      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final safeName = file.fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final path = '$companyId/$propertyId/${uuid.v4()}_$safeName';

        await _client.storage.from(_photosBucket).uploadBinary(
              path,
              file.bytes,
              fileOptions: FileOptions(contentType: file.mimeType, upsert: false),
            );

        final signedUrl = await _client.storage.from(_photosBucket).createSignedUrl(path, 86400);

        await _client.from('rental_property_photos').insert({
          'company_id': companyId,
          'property_id': propertyId,
          'file_url': signedUrl,
          'file_path': path,
          'file_name': file.fileName,
          'mime_type': file.mimeType,
          'sort_order': sortOffset + i,
          if (userId != null) 'uploaded_by': userId,
        });
      }

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao enviar fotos: $e'));
    }
  }

  @override
  Future<Result<void>> deletePropertyPhotos(List<String> photoIds) async {
    if (photoIds.isEmpty) return const Success(null);

    try {
      final data = await _client
          .from('rental_property_photos')
          .select('id, file_path')
          .inFilter('id', photoIds);

      final paths = (data as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['file_path'] as String)
          .where((p) => p.isNotEmpty)
          .toList();

      if (paths.isNotEmpty) {
        await _client.storage.from(_photosBucket).remove(paths);
      }

      await _client.from('rental_property_photos').delete().inFilter('id', photoIds);
      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao remover fotos: $e'));
    }
  }

  @override
  Future<Result<List<RentalParty>>> listParties() async {
    try {
      final data = await _client
          .from('rental_parties')
          .select(_partySelect)
          .order('full_name')
          .limit(300);
      return Success((data as List).map((e) => _partyFromMap(e as Map<String, dynamic>)).toList());
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar pessoas: $e'));
    }
  }

  @override
  Future<Result<RentalParty>> getParty(String id) async {
    try {
      final data = await _client.from('rental_parties').select().eq('id', id).single();
      return Success(_partyFromMap(data));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao buscar pessoa: $e'));
    }
  }

  @override
  Future<Result<RentalParty>> createParty(RentalPartyInput input) async {
    return _saveParty(input);
  }

  @override
  Future<Result<RentalParty>> updateParty(String id, RentalPartyInput input) async {
    return _saveParty(input, id: id);
  }

  @override
  Future<Result<RentalParty?>> findPartyByDocumentOrPhone({
    required String companyId,
    String? documentNumber,
    String? phone,
    String? excludePartyId,
  }) async {
    try {
      final orFilters = <String>[];

      if (documentNumber != null) {
        final docDigits = BrazilianInputFormat.digitsOnly(documentNumber);
        if (docDigits.length == 11) {
          orFilters.add(
            'document_number.eq.${BrazilianInputFormat.formatCpf(docDigits)}',
          );
        }
      }

      if (phone != null) {
        final phoneDigits = BrazilianInputFormat.digitsOnly(phone);
        if (phoneDigits.length >= 10 && phoneDigits.length <= 11) {
          orFilters.add(
            'phone.eq.${BrazilianInputFormat.formatPhone(phoneDigits)}',
          );
        }
      }

      if (orFilters.isEmpty) return const Success(null);

      var query = _client
          .from('rental_parties')
          .select(_partySelect)
          .eq('company_id', companyId)
          .or(orFilters.join(','));

      if (excludePartyId != null) {
        query = query.neq('id', excludePartyId);
      }

      final data = await query.limit(1).maybeSingle();
      if (data == null) return const Success(null);
      return Success(_partyFromMap(data));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao buscar pessoa: $e'));
    }
  }

  Future<Result<RentalParty>> _saveParty(RentalPartyInput input, {String? id}) async {
    try {
      final row = <String, dynamic>{
        'company_id': input.companyId,
        'full_name': input.fullName.trim(),
        'category': input.category.value,
        'email': input.email?.trim(),
        'phone': input.phone?.trim(),
        'document_number': input.documentNumber?.trim(),
        'notes': input.notes?.trim(),
        'status': input.status,
        'address_street': input.addressStreet?.trim(),
        'address_number': input.addressNumber?.trim(),
        'address_complement': input.addressComplement?.trim(),
        'address_neighborhood': input.addressNeighborhood?.trim(),
        'address_city': input.addressCity?.trim(),
        'address_state': input.addressState?.trim(),
        'address_zip': input.addressZip?.trim(),
        'intake_metadata': input.intakeMetadata,
        'nationality': input.nationality?.trim(),
        'rg_number': input.rgNumber?.trim(),
        'rg_issuer': input.rgIssuer?.trim(),
        'profession': input.profession?.trim(),
        'marital_status': input.maritalStatus?.trim(),
      };
      if (input.isRentalRestricted != null) {
        row['is_rental_restricted'] = input.isRentalRestricted;
        if (input.isRentalRestricted == true) {
          row['restricted_at'] = DateTime.now().toUtc().toIso8601String();
        }
      }
      if (input.restrictionReason != null) {
        row['restriction_reason'] = input.restrictionReason!.trim().isEmpty
            ? null
            : input.restrictionReason!.trim();
      }
      final dynamic data;
      if (id == null) {
        data = await _client.from('rental_parties').insert(row).select().single();
      } else {
        data = await _client.from('rental_parties').update(row).eq('id', id).select().single();
        await _syncPartyLinkedGuestFields(
          partyId: id,
          fullName: input.fullName.trim(),
          email: input.email?.trim(),
          phone: input.phone?.trim(),
        );
      }
      return Success(_partyFromMap(data as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao salvar pessoa: $e'));
    }
  }

  Future<void> _syncPartyLinkedGuestFields({
    required String partyId,
    required String fullName,
    String? email,
    String? phone,
  }) async {
    await _client.from('rental_bookings').update({
      'guest_name': fullName,
      'guest_email': email,
      'guest_phone': phone,
    }).eq('guest_party_id', partyId);
  }

  @override
  Future<Result<List<RentalLease>>> listLeases() async {
    try {
      final data = await _client.from('rental_leases').select(_leaseSelect).order('start_date', ascending: false).limit(300);
      return Success((data as List).map((e) => _leaseFromMap(e as Map<String, dynamic>)).toList());
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar contratos: $e'));
    }
  }

  @override
  Future<Result<RentalLease>> getLease(String id) async {
    try {
      final data = await _client.from('rental_leases').select(_leaseSelect).eq('id', id).single();
      return Success(_leaseFromMap(data));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao buscar contrato: $e'));
    }
  }

  @override
  Future<Result<RentalLease>> createLease(RentalLeaseInput input) async {
    return _saveLease(input);
  }

  @override
  Future<Result<RentalLease>> updateLease(String id, RentalLeaseInput input) async {
    return _saveLease(input, id: id);
  }

  @override
  Future<Result<RentalLease>> terminateLease(String id, TerminateLeaseInput input) async {
    final leaseResult = await getLease(id);
    return switch (leaseResult) {
      Failure(:final error) => Failure(error),
      Success(:final data) => _terminateLeaseImpl(id, data, input),
    };
  }

  Future<Result<RentalLease>> _terminateLeaseImpl(
    String id,
    RentalLease lease,
    TerminateLeaseInput input,
  ) async {
    try {
      final leaseRow = <String, dynamic>{
        'status': RentalLeaseStatus.terminated.value,
        'end_date': _dateStr(input.endDate),
        'termination_reason': input.terminationReason?.trim(),
      };

      final data = await _client
          .from('rental_leases')
          .update(leaseRow)
          .eq('id', id)
          .select(_leaseSelect)
          .single();

      if (input.applyTenantRestriction && lease.primaryTenantPartyId != null) {
        await _client.from('rental_parties').update({
          'is_rental_restricted': true,
          'restriction_reason': input.restrictionReason?.trim(),
          'restricted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', lease.primaryTenantPartyId!);
      }

      return Success(_leaseFromMap(data));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao encerrar contrato: $e'));
    }
  }

  Future<Result<RentalLease>> _saveLease(RentalLeaseInput input, {String? id}) async {
    try {
      final t = input.contractTerms;
      final row = {
        'company_id': input.companyId,
        'property_id': input.propertyId,
        'unit_id': input.unitId,
        'primary_tenant_party_id': input.primaryTenantPartyId,
        'lease_number': input.leaseNumber?.trim(),
        'listing_mode': input.listingMode.value,
        'status': input.status.value,
        'start_date': _dateStr(input.startDate),
        'end_date': input.endDate != null ? _dateStr(input.endDate!) : null,
        'monthly_rent': input.monthlyRent,
        'deposit_amount': input.depositAmount,
        'due_day_of_month': input.dueDayOfMonth,
        'notes': input.notes?.trim(),
        'adjustment_index': t.adjustmentIndex?.value,
        'adjustment_period_months': t.adjustmentPeriodMonths,
        'guarantee_type': t.guaranteeType?.value,
        'guarantee_other_description': t.guaranteeOtherDescription?.trim(),
        'payment_method': t.paymentMethod?.value,
        'pix_key': t.pixKey?.trim(),
        'bank_name': t.bankName?.trim(),
        'bank_agency': t.bankAgency?.trim(),
        'bank_account': t.bankAccount?.trim(),
        'bank_account_type': t.bankAccountType?.trim(),
        'bank_holder': t.bankHolder?.trim(),
        'bank_holder_document': t.bankHolderDocument?.trim(),
        'late_fee_percent': t.lateFeePercent,
        'interest_percent': t.interestPercent,
        'termination_penalty_months': t.terminationPenaltyMonths,
        'inspection_objection_days': t.inspectionObjectionDays,
        'key_delivery_method': t.keyDeliveryMethod?.trim(),
        'max_occupants': t.maxOccupants,
        'allows_pets': t.allowsPets,
        'pets_description': t.petsDescription?.trim(),
        'cancellation_policy': t.cancellationPolicy?.value,
        'season_total_amount': t.seasonTotalAmount,
        'tenant_charges': t.tenantCharges?.trim(),
        'landlord_charges': t.landlordCharges?.trim(),
        'witness_1_name': t.witness1Name?.trim(),
        'witness_1_cpf': t.witness1Cpf?.trim(),
        'witness_2_name': t.witness2Name?.trim(),
        'witness_2_cpf': t.witness2Cpf?.trim(),
      };
      final dynamic data;
      final String leaseId;
      if (id == null) {
        data = await _client.from('rental_leases').insert(row).select(_leaseSelect).single();
        leaseId = (data as Map<String, dynamic>)['id'] as String;
      } else {
        data = await _client.from('rental_leases').update(row).eq('id', id).select(_leaseSelect).single();
        leaseId = id;
      }

      if (input.primaryTenantPartyId != null) {
        await _client.from('rental_lease_tenants').upsert(
          {
            'lease_id': leaseId,
            'party_id': input.primaryTenantPartyId,
            'is_primary': true,
          },
          onConflict: 'lease_id,party_id',
        );
      }

      return Success(_leaseFromMap(data as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao salvar contrato: $e'));
    }
  }

  @override
  Future<Result<List<RentalBooking>>> listBookings({
    DateTime? from,
    DateTime? to,
    String? propertyId,
  }) async {
    try {
      var query = _client.from('rental_bookings').select(_bookingSelect);
      if (propertyId != null) query = query.eq('property_id', propertyId);
      if (from != null) query = query.gte('check_out', _dateStr(from));
      if (to != null) query = query.lte('check_in', _dateStr(to));
      final data = await query.order('check_in', ascending: false).limit(500);
      return Success((data as List).map((e) => _bookingFromMap(e as Map<String, dynamic>)).toList());
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar reservas: $e'));
    }
  }

  @override
  Future<Result<RentalBooking>> getBooking(String id) async {
    try {
      final data = await _client.from('rental_bookings').select(_bookingSelect).eq('id', id).single();
      return Success(_bookingFromMap(data));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao buscar reserva: $e'));
    }
  }

  @override
  Future<Result<RentalBooking>> createBooking(RentalBookingInput input) async {
    return _saveBooking(input);
  }

  @override
  Future<Result<RentalBooking>> updateBooking(String id, RentalBookingInput input) async {
    return _saveBooking(input, id: id);
  }

  Future<Result<RentalBooking>> _saveBooking(RentalBookingInput input, {String? id}) async {
    try {
      final row = {
        'company_id': input.companyId,
        'property_id': input.propertyId,
        'unit_id': input.unitId,
        'guest_party_id': input.guestPartyId,
        'guest_name': input.guestName.trim(),
        'guest_email': input.guestEmail?.trim(),
        'guest_phone': input.guestPhone?.trim(),
        'guests_count': input.guestsCount,
        'channel': input.channel.value,
        'status': input.status.value,
        'check_in': _dateStr(input.checkIn),
        'check_out': _dateStr(input.checkOut),
        'nightly_rate': input.nightlyRate,
        'total_amount': input.totalAmount,
        'is_fixed_rent': input.isFixedRent,
        'monthly_rent': input.isFixedRent ? input.monthlyRent : null,
        'payment_due_day': input.isFixedRent ? input.paymentDueDay : null,
        'notes': input.notes?.trim(),
      };
      final dynamic data;
      if (id == null) {
        data = await _client.from('rental_bookings').insert(row).select(_bookingSelect).single();
      } else {
        data = await _client.from('rental_bookings').update(row).eq('id', id).select(_bookingSelect).single();
      }
      return Success(_bookingFromMap(data as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao salvar reserva: $e'));
    }
  }

  @override
  Future<Result<int>> generateMonthlyCharges({DateTime? asOf}) async {
    try {
      final params = <String, dynamic>{};
      if (asOf != null) {
        params['p_as_of'] = _dateStr(asOf);
      }
      final data = await _client.rpc(
        'generate_rental_monthly_charges',
        params: params.isEmpty ? null : params,
      );
      return Success((data as num?)?.toInt() ?? 0);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao gerar cobranças: $e'));
    }
  }

  @override
  Future<Result<List<RentalCharge>>> listCharges(RentalChargeListFilter filter) async {
    try {
      var query = _client.from('rental_charges').select(_chargeSelect);
      if (filter.status != null) query = query.eq('status', filter.status!.value);
      if (filter.chargeType != null) query = query.eq('charge_type', filter.chargeType!.value);
      if (filter.bookingId != null) query = query.eq('booking_id', filter.bookingId!);
      final data = await query.order('due_date', ascending: false).limit(300);
      return Success((data as List).map((e) => _chargeFromMap(e as Map<String, dynamic>)).toList());
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao listar cobranças: $e'));
    }
  }

  @override
  Future<Result<RentalCharge>> getCharge(String id) async {
    try {
      final data = await _client.from('rental_charges').select(_chargeSelect).eq('id', id).single();
      return Success(_chargeFromMap(data));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao buscar cobrança: $e'));
    }
  }

  @override
  Future<Result<RentalCharge>> createCharge(RentalChargeInput input) async {
    return _saveCharge(input);
  }

  @override
  Future<Result<RentalCharge>> updateCharge(String id, RentalChargeInput input) async {
    return _saveCharge(input, id: id);
  }

  Future<Result<RentalCharge>> _saveCharge(RentalChargeInput input, {String? id}) async {
    try {
      final referenceMonth = _referenceMonthForCharge(input);
      final conflict = await _checkRentChargeConflict(
        leaseId: input.leaseId,
        bookingId: input.bookingId,
        dueDate: input.dueDate,
        chargeType: input.chargeType,
        status: input.status,
        excludeChargeId: id,
      );
      if (conflict case Failure<void>(:final error)) {
        return Failure(error);
      }

      final row = {
        'company_id': input.companyId,
        'lease_id': input.leaseId,
        'booking_id': input.bookingId,
        'party_id': input.partyId,
        'charge_type': input.chargeType.value,
        'status': input.status.value,
        'description': input.description.trim(),
        'amount': input.amount,
        'due_date': input.dueDate != null ? _dateStr(input.dueDate!) : null,
        'reference_month': referenceMonth != null ? _dateStr(referenceMonth) : null,
        'notes': input.notes?.trim(),
      };
      final dynamic data;
      if (id == null) {
        data = await _client.from('rental_charges').insert(row).select(_chargeSelect).single();
      } else {
        data = await _client.from('rental_charges').update(row).eq('id', id).select(_chargeSelect).single();
      }
      return Success(_chargeFromMap(data as Map<String, dynamic>));
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao salvar cobrança: $e'));
    }
  }

  @override
  Future<Result<RentalCharge>> markChargePaid(
    String chargeId, {
    required RentalPaymentMethod paymentMethod,
    required double paidAmount,
    required DateTime paidAt,
    bool syncFinancial = true,
  }) async {
    try {
      final paidAtUtc = DateTime(paidAt.year, paidAt.month, paidAt.day).toUtc();
      await _client.from('rental_charges').update({
        'status': RentalChargeStatus.paid.value,
        'amount': paidAmount,
        'paid_at': paidAtUtc.toIso8601String(),
        'paid_payment_method': paymentMethod.value,
      }).eq('id', chargeId);

      if (syncFinancial) {
        final sync = await syncChargeToFinancial(chargeId);
        if (sync case Failure<String>(:final error)) return Failure(error);
      }

      return getCharge(chargeId);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao marcar cobrança: $e'));
    }
  }

  @override
  Future<Result<String>> syncChargeToFinancial(String chargeId) async {
    try {
      final chargeResult = await getCharge(chargeId);
      RentalCharge? charge;
      AppException? loadError;
      chargeResult.when(
        success: (c) => charge = c,
        failure: (e) => loadError = e,
      );
      if (loadError != null) return Failure(loadError!);
      final c = charge!;

      if (c.financialRecordId != null) {
        return Success(c.financialRecordId!);
      }
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Failure(AppAuthException('Usuário não autenticado.'));
      }

      String? condoId;
      String? propertyId;

      if (c.leaseId != null) {
        final lease = await _client
            .from('rental_leases')
            .select('property_id')
            .eq('id', c.leaseId!)
            .maybeSingle();
        propertyId = lease?['property_id'] as String?;
      } else if (c.bookingId != null) {
        final booking = await _client
            .from('rental_bookings')
            .select('property_id')
            .eq('id', c.bookingId!)
            .maybeSingle();
        propertyId = booking?['property_id'] as String?;
      }

      if (propertyId != null) {
        final prop = await _client
            .from('rental_properties')
            .select('condominium_id')
            .eq('id', propertyId)
            .maybeSingle();
        condoId = prop?['condominium_id'] as String?;
      }

      final finRow = await _client.from('financial_records').insert({
        'scope': condoId != null ? 'condominium' : 'management_company',
        if (condoId != null) 'condominium_id': condoId,
        if (propertyId != null) 'rental_property_id': propertyId,
        'record_type': 'income',
        'category': 'revenue',
        'description': 'Locação: ${c.description}',
        'amount': c.amount,
        'tax_amount': 0,
        'reference_date': _dateStr(c.paidAt ?? c.dueDate ?? DateTime.now()),
        'due_date': c.dueDate != null ? _dateStr(c.dueDate!) : null,
        'paid_at': (c.paidAt ?? DateTime.now()).toUtc().toIso8601String(),
        'rental_charge_id': chargeId,
        'created_by': userId,
        'notes': [
          if (c.notes != null && c.notes!.trim().isNotEmpty) c.notes!.trim(),
          if (c.paidPaymentMethod != null)
            'Pagamento: ${c.paidPaymentMethod!.label}',
        ].join('\n'),
      }).select('id').single();

      final finId = finRow['id'] as String;
      await _client.from('rental_charges').update({
        'financial_record_id': finId,
      }).eq('id', chargeId);

      return Success(finId);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao integrar financeiro: $e'));
    }
  }

  static const _leaseSelect = '''
    id, company_id, property_id, unit_id, primary_tenant_party_id, lease_number, listing_mode, status,
    start_date, end_date, monthly_rent, deposit_amount, due_day_of_month, notes, termination_reason,
    adjustment_index, adjustment_period_months, guarantee_type, guarantee_other_description,
    payment_method, pix_key, bank_name, bank_agency, bank_account, bank_account_type,
    bank_holder, bank_holder_document, late_fee_percent, interest_percent, termination_penalty_months,
    inspection_objection_days, key_delivery_method, max_occupants, allows_pets, pets_description,
    cancellation_policy, season_total_amount, tenant_charges, landlord_charges,
    witness_1_name, witness_1_cpf, witness_2_name, witness_2_cpf,
    rental_properties ( title ),
    rental_parties!rental_leases_primary_tenant_party_id_fkey ( full_name )
  ''';

  static const _bookingSelect = '''
    id, company_id, property_id, unit_id, guest_party_id, booking_number, channel, status,
    guest_name, guest_email, guest_phone, guests_count, check_in, check_out,
    nightly_rate, total_amount, paid_amount, is_fixed_rent, monthly_rent, payment_due_day, notes,
    rental_properties ( title ),
    rental_parties!rental_bookings_guest_party_id_fkey ( document_number )
  ''';

  static const _chargeSelect = '''
    id, company_id, lease_id, booking_id, party_id, charge_type, status,
    description, amount, due_date, paid_at, paid_payment_method,
    financial_record_id, notes,
    rental_parties ( full_name ),
    rental_leases ( rental_properties ( title ) ),
    rental_bookings ( rental_properties ( title ) )
  ''';

  Map<String, dynamic> _propertyPayload(RentalPropertyInput input) => {
        'company_id': input.companyId,
        'title': input.title.trim(),
        'property_type': input.propertyType.value,
        'listing_mode': input.listingMode.value,
        'code': input.code?.trim(),
        'description': input.description?.trim(),
        'condominium_id': input.condominiumId,
        'owner_party_id': input.ownerPartyId,
        'address_street': input.addressStreet?.trim(),
        'address_number': input.addressNumber?.trim(),
        'address_building': input.addressBuilding?.trim(),
        'address_block': input.addressBlock?.trim(),
        'address_apartment': input.addressApartment?.trim(),
        'address_neighborhood': input.addressNeighborhood?.trim(),
        'address_city': input.addressCity?.trim(),
        'address_state': input.addressState?.trim(),
        'address_zip': input.addressZip?.trim(),
        'area_sqm': input.areaSqm,
        'bedrooms': input.bedrooms,
        'bathrooms': input.bathrooms,
        'max_guests': input.maxGuests,
        'base_rent_amount': input.baseRentAmount,
        'base_daily_rate': input.baseDailyRate,
        'deposit_amount': input.depositAmount,
        'status': input.status,
        'registry_matricula': input.registryMatricula?.trim(),
        'registry_cartorio': input.registryCartorio?.trim(),
        'iptu_inscription': input.iptuInscription?.trim(),
        'municipal_inscription': input.municipalInscription?.trim(),
        'is_furnished': input.isFurnished,
        'accepts_pets': input.acceptsPets,
      };

  RentalProperty _propertyFromMap(Map<String, dynamic> map) {
    final condo = map['condominiums'] as Map<String, dynamic>?;
    return RentalProperty(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      condominiumId: map['condominium_id'] as String?,
      condominiumName: condo?['name'] as String?,
      condominiumCity: condo?['city'] as String?,
      condominiumState: condo?['state'] as String?,
      ownerPartyId: map['owner_party_id'] as String?,
      propertyType: RentalPropertyType.fromValue(map['property_type'] as String),
      listingMode: RentalListingMode.fromValue(map['listing_mode'] as String),
      code: map['code'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      addressStreet: map['address_street'] as String?,
      addressNumber: map['address_number'] as String?,
      addressBuilding: map['address_building'] as String?,
      addressBlock: map['address_block'] as String?,
      addressApartment: map['address_apartment'] as String?,
      addressNeighborhood: map['address_neighborhood'] as String?,
      addressCity: map['address_city'] as String?,
      addressState: map['address_state'] as String?,
      addressZip: map['address_zip'] as String?,
      areaSqm: _toDouble(map['area_sqm']),
      bedrooms: map['bedrooms'] as int?,
      bathrooms: map['bathrooms'] as int?,
      maxGuests: map['max_guests'] as int?,
      baseRentAmount: _toDouble(map['base_rent_amount']),
      baseDailyRate: _toDouble(map['base_daily_rate']),
      depositAmount: _toDouble(map['deposit_amount']),
      status: map['status'] as String? ?? 'active',
      registryMatricula: map['registry_matricula'] as String?,
      registryCartorio: map['registry_cartorio'] as String?,
      iptuInscription: map['iptu_inscription'] as String?,
      municipalInscription: map['municipal_inscription'] as String?,
      isFurnished: map['is_furnished'] as bool?,
      acceptsPets: map['accepts_pets'] as bool?,
    );
  }

  RentalPropertyPhoto _photoFromMap(Map<String, dynamic> map, {required String fileUrl}) =>
      RentalPropertyPhoto(
        id: map['id'] as String,
        companyId: map['company_id'] as String,
        propertyId: map['property_id'] as String,
        fileUrl: fileUrl,
        filePath: map['file_path'] as String,
        fileName: map['file_name'] as String?,
        mimeType: map['mime_type'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  RentalPropertyInclusion _inclusionFromMap(Map<String, dynamic> map) => RentalPropertyInclusion(
        id: map['id'] as String,
        companyId: map['company_id'] as String,
        propertyId: map['property_id'] as String,
        category: RentalInclusionCategory.fromValue(map['category'] as String),
        catalogItemId: map['catalog_item_id'] as String?,
        customName: map['custom_name'] as String?,
        amount: _toDouble(map['amount']),
        includedInRent: map['included_in_rent'] as bool? ?? false,
        quantity: map['quantity'] as int?,
        sizeLabel: map['size_label'] as String?,
        model: map['model'] as String?,
        chairCount: map['chair_count'] as int?,
        notes: map['notes'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  RentalInclusionCatalogItem _catalogFromMap(Map<String, dynamic> map) =>
      RentalInclusionCatalogItem(
        id: map['id'] as String,
        companyId: map['company_id'] as String,
        name: map['name'] as String,
        category: RentalInclusionCategory.fromValue(map['category'] as String),
        defaultAmount: _toDouble(map['default_amount']),
        isActive: map['is_active'] as bool? ?? true,
      );

  RentalParty _partyFromMap(Map<String, dynamic> map) => RentalParty(
        id: map['id'] as String,
        companyId: map['company_id'] as String,
        fullName: map['full_name'] as String,
        category: RentalPartyCategory.fromValue(map['category'] as String? ?? 'tenant'),
        email: map['email'] as String?,
        phone: map['phone'] as String?,
        documentNumber: map['document_number'] as String?,
        notes: map['notes'] as String?,
        status: map['status'] as String? ?? 'active',
        isRentalRestricted: map['is_rental_restricted'] as bool? ?? false,
        restrictionReason: map['restriction_reason'] as String?,
        restrictedAt: map['restricted_at'] != null
            ? DateTime.parse(map['restricted_at'] as String)
            : null,
        addressStreet: map['address_street'] as String?,
        addressNumber: map['address_number'] as String?,
        addressComplement: map['address_complement'] as String?,
        addressNeighborhood: map['address_neighborhood'] as String?,
        addressCity: map['address_city'] as String?,
        addressState: map['address_state'] as String?,
        addressZip: map['address_zip'] as String?,
        intakeMetadata: () {
          final raw = map['intake_metadata'];
          if (raw is Map<String, dynamic>) return raw;
          if (raw is Map) return Map<String, dynamic>.from(raw);
          return null;
        }(),
        nationality: map['nationality'] as String?,
        rgNumber: map['rg_number'] as String?,
        rgIssuer: map['rg_issuer'] as String?,
        profession: map['profession'] as String?,
        maritalStatus: map['marital_status'] as String?,
      );

  RentalLease _leaseFromMap(Map<String, dynamic> map) {
    final prop = map['rental_properties'] as Map<String, dynamic>?;
    final tenant = map['rental_parties'] as Map<String, dynamic>?;
    return RentalLease(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      propertyId: map['property_id'] as String,
      propertyTitle: prop?['title'] as String? ?? '—',
      unitId: map['unit_id'] as String?,
      tenantName: tenant?['full_name'] as String?,
      leaseNumber: map['lease_number'] as String?,
      listingMode: RentalListingMode.fromValue(map['listing_mode'] as String),
      status: RentalLeaseStatus.fromValue(map['status'] as String),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      monthlyRent: _toDouble(map['monthly_rent']) ?? 0,
      depositAmount: _toDouble(map['deposit_amount']),
      dueDayOfMonth: map['due_day_of_month'] as int?,
      notes: map['notes'] as String?,
      primaryTenantPartyId: map['primary_tenant_party_id'] as String?,
      terminationReason: map['termination_reason'] as String?,
      contractTerms: RentalLeaseContractTerms(
        guaranteeType: RentalGuaranteeType.fromValue(map['guarantee_type'] as String?),
        guaranteeOtherDescription: map['guarantee_other_description'] as String?,
        adjustmentIndex: RentalAdjustmentIndex.fromValue(map['adjustment_index'] as String?),
        adjustmentPeriodMonths: map['adjustment_period_months'] as int?,
        paymentMethod: RentalPaymentMethod.fromValue(map['payment_method'] as String?),
        pixKey: map['pix_key'] as String?,
        bankName: map['bank_name'] as String?,
        bankAgency: map['bank_agency'] as String?,
        bankAccount: map['bank_account'] as String?,
        bankAccountType: map['bank_account_type'] as String?,
        bankHolder: map['bank_holder'] as String?,
        bankHolderDocument: map['bank_holder_document'] as String?,
        lateFeePercent: _toDouble(map['late_fee_percent']),
        interestPercent: _toDouble(map['interest_percent']),
        terminationPenaltyMonths: map['termination_penalty_months'] as int?,
        inspectionObjectionDays: map['inspection_objection_days'] as int?,
        keyDeliveryMethod: map['key_delivery_method'] as String?,
        maxOccupants: map['max_occupants'] as int?,
        allowsPets: map['allows_pets'] as bool?,
        petsDescription: map['pets_description'] as String?,
        cancellationPolicy:
            RentalCancellationPolicy.fromValue(map['cancellation_policy'] as String?),
        seasonTotalAmount: _toDouble(map['season_total_amount']),
        tenantCharges: map['tenant_charges'] as String?,
        landlordCharges: map['landlord_charges'] as String?,
        witness1Name: map['witness_1_name'] as String?,
        witness1Cpf: map['witness_1_cpf'] as String?,
        witness2Name: map['witness_2_name'] as String?,
        witness2Cpf: map['witness_2_cpf'] as String?,
      ),
    );
  }

  RentalBooking _bookingFromMap(Map<String, dynamic> map) {
    final prop = map['rental_properties'] as Map<String, dynamic>?;
    final party = map['rental_parties'] as Map<String, dynamic>?;
    return RentalBooking(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      propertyId: map['property_id'] as String,
      propertyTitle: prop?['title'] as String? ?? '—',
      unitId: map['unit_id'] as String?,
      bookingNumber: map['booking_number'] as String?,
      channel: RentalBookingChannel.fromValue(map['channel'] as String),
      status: RentalBookingStatus.fromValue(map['status'] as String),
      guestName: map['guest_name'] as String,
      guestEmail: map['guest_email'] as String?,
      guestPhone: map['guest_phone'] as String?,
      guestDocumentNumber: party?['document_number'] as String?,
      guestPartyId: map['guest_party_id'] as String?,
      guestsCount: map['guests_count'] as int? ?? 1,
      checkIn: DateTime.parse(map['check_in'] as String),
      checkOut: DateTime.parse(map['check_out'] as String),
      nightlyRate: _toDouble(map['nightly_rate']),
      totalAmount: _toDouble(map['total_amount']),
      paidAmount: _toDouble(map['paid_amount']),
      isFixedRent: map['is_fixed_rent'] as bool? ?? false,
      monthlyRent: _toDouble(map['monthly_rent']),
      paymentDueDay: map['payment_due_day'] as int?,
      notes: map['notes'] as String?,
    );
  }

  RentalCharge _chargeFromMap(Map<String, dynamic> map) {
    final party = map['rental_parties'] as Map<String, dynamic>?;
    String? propTitle;
    final lease = map['rental_leases'] as Map<String, dynamic>?;
    final booking = map['rental_bookings'] as Map<String, dynamic>?;
    if (lease != null) {
      final p = lease['rental_properties'] as Map<String, dynamic>?;
      propTitle = p?['title'] as String?;
    } else if (booking != null) {
      final p = booking['rental_properties'] as Map<String, dynamic>?;
      propTitle = p?['title'] as String?;
    }
    return RentalCharge(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      leaseId: map['lease_id'] as String?,
      bookingId: map['booking_id'] as String?,
      partyId: map['party_id'] as String?,
      partyName: party?['full_name'] as String?,
      propertyTitle: propTitle,
      chargeType: RentalChargeType.fromValue(map['charge_type'] as String),
      status: RentalChargeStatus.fromValue(map['status'] as String),
      description: map['description'] as String,
      amount: _toDouble(map['amount']) ?? 0,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at'] as String) : null,
      financialRecordId: map['financial_record_id'] as String?,
      paidPaymentMethod: RentalPaymentMethod.fromValue(map['paid_payment_method'] as String?),
      notes: map['notes'] as String?,
    );
  }

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  Future<Result<List<RentalPropertyPnl>>> propertyPnlReport({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (from != null) params['p_from'] = _dateStr(from);
      if (to != null) params['p_to'] = _dateStr(to);

      final data = await _client.rpc('rental_property_pnl_report', params: params);
      final rows = (data as List).map((e) {
        final map = e as Map<String, dynamic>;
        return RentalPropertyPnl(
          propertyId: map['property_id'] as String,
          propertyTitle: map['property_title'] as String,
          condominiumName: map['condominium_name'] as String?,
          rentalRevenue: _toDouble(map['rental_revenue']) ?? 0,
          maintenanceCost: _toDouble(map['maintenance_cost']) ?? 0,
          ticketCount: (map['ticket_count'] as num?)?.toInt() ?? 0,
          workOrderCount: (map['work_order_count'] as num?)?.toInt() ?? 0,
        );
      }).toList();
      return Success(rows);
    } on PostgrestException catch (e) {
      return Failure(_mapError(e));
    } catch (e) {
      return Failure(NetworkException('Erro ao carregar relatório: $e'));
    }
  }

  DateTime? _referenceMonthForCharge(RentalChargeInput input) {
    if (input.chargeType != RentalChargeType.rent || input.dueDate == null) {
      return null;
    }
    final due = input.dueDate!;
    return DateTime(due.year, due.month);
  }

  Future<Result<void>> _checkRentChargeConflict({
    required String? leaseId,
    required String? bookingId,
    required DateTime? dueDate,
    required RentalChargeType chargeType,
    required RentalChargeStatus status,
    String? excludeChargeId,
  }) async {
    if (status == RentalChargeStatus.cancelled) return const Success(null);
    if (chargeType != RentalChargeType.rent) return const Success(null);
    if (dueDate == null || (leaseId == null && bookingId == null)) {
      return const Success(null);
    }

    final refMonth = DateTime(dueDate.year, dueDate.month);
    final refMonthStr = _dateStr(refMonth);
    final nextMonth = DateTime(refMonth.year, refMonth.month + 1);
    final nextMonthStr = _dateStr(nextMonth);

    var query = _client
        .from('rental_charges')
        .select('id')
        .eq('charge_type', RentalChargeType.rent.value)
        .neq('status', RentalChargeStatus.cancelled.value)
        .or(
          'reference_month.eq.$refMonthStr,'
          'and(reference_month.is.null,due_date.gte.$refMonthStr,due_date.lt.$nextMonthStr)',
        );

    if (leaseId != null) {
      query = query.eq('lease_id', leaseId);
    } else {
      query = query.eq('booking_id', bookingId!);
    }

    final data = await query;
    final hasConflict = (data as List).any((row) {
      final chargeId = (row as Map<String, dynamic>)['id'] as String;
      return chargeId != excludeChargeId;
    });

    if (hasConflict) {
      final monthLabel =
          '${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}';
      return Failure(
        ValidationException(
          'Já existe uma cobrança de aluguel para este vínculo em $monthLabel. '
          'Edite a cobrança existente em vez de duplicar.',
        ),
      );
    }

    return const Success(null);
  }

  AppException _mapError(PostgrestException e) {
    if (e.code == '42501' || e.message.contains('permission')) {
      return PermissionException(e.message);
    }
    if (e.code == '23505' && e.message.contains('rental_charges')) {
      return const ValidationException(
        'Já existe uma cobrança de aluguel para este contrato ou reserva neste mês.',
      );
    }
    return NetworkException(e.message);
  }
}
