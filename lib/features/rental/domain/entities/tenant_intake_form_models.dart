class TenantIntakeFormDefinition {
  const TenantIntakeFormDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.submitButtonLabel,
    required this.successMessage,
    required this.whatsappMessageTemplate,
    required this.whatsappFallbackMessage,
    required this.linkExpirationHours,
    required this.sections,
  });

  final String id;
  final String name;
  final String description;
  final String submitButtonLabel;
  final String successMessage;
  final String whatsappMessageTemplate;
  final String whatsappFallbackMessage;
  final int linkExpirationHours;
  final List<TenantIntakeFormSection> sections;

  factory TenantIntakeFormDefinition.fromJson(Map<String, dynamic> json) {
    final form = json['form'] as Map<String, dynamic>;
    final whatsapp = form['whatsapp'] as Map<String, dynamic>? ?? {};
    return TenantIntakeFormDefinition(
      id: form['id'] as String,
      name: form['name'] as String,
      description: form['description'] as String? ?? '',
      submitButtonLabel: form['submitButtonLabel'] as String? ?? 'Enviar',
      successMessage: form['successMessage'] as String? ?? 'Enviado com sucesso.',
      whatsappMessageTemplate:
          whatsapp['messageTemplate'] as String? ?? 'Link: {{FORM_LINK}}',
      whatsappFallbackMessage:
          whatsapp['fallbackMessage'] as String? ?? 'Link: {{FORM_LINK}}',
      linkExpirationHours: whatsapp['linkExpirationHours'] as int? ?? 72,
      sections: (form['sections'] as List<dynamic>)
          .map((e) => TenantIntakeFormSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TenantIntakeFormSection {
  const TenantIntakeFormSection({
    required this.id,
    required this.title,
    this.description,
    required this.fields,
  });

  final String id;
  final String title;
  final String? description;
  final List<TenantIntakeFormField> fields;

  factory TenantIntakeFormSection.fromJson(Map<String, dynamic> json) =>
      TenantIntakeFormSection(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        fields: (json['fields'] as List<dynamic>)
            .map((e) => TenantIntakeFormField.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TenantIntakeFormField {
  const TenantIntakeFormField({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.placeholder,
    this.defaultValue,
    this.mask,
    this.options = const [],
    this.visibleWhen,
    this.min,
  });

  final String name;
  final String label;
  final String type;
  final bool required;
  final String? placeholder;
  final String? defaultValue;
  final String? mask;
  final List<TenantIntakeFieldOption> options;
  final TenantIntakeVisibleWhen? visibleWhen;
  final num? min;

  factory TenantIntakeFormField.fromJson(Map<String, dynamic> json) {
    final validation = json['validation'] as Map<String, dynamic>?;
    return TenantIntakeFormField(
      name: json['name'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      required: json['required'] as bool? ?? false,
      placeholder: json['placeholder'] as String?,
      defaultValue: json['defaultValue'] as String?,
      mask: json['mask'] as String?,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => TenantIntakeFieldOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      visibleWhen: json['visibleWhen'] != null
          ? TenantIntakeVisibleWhen.fromJson(json['visibleWhen'] as Map<String, dynamic>)
          : null,
      min: validation?['min'] as num?,
    );
  }

  bool isVisible(Map<String, String> values) {
    final rule = visibleWhen;
    if (rule == null) return true;
    final current = values[rule.field] ?? '';
    return switch (rule.operator) {
      'equals' => current == (rule.value?.toString() ?? ''),
      'in' => rule.values?.contains(current) ?? false,
      _ => true,
    };
  }
}

class TenantIntakeFieldOption {
  const TenantIntakeFieldOption({required this.label, required this.value});

  final String label;
  final String value;

  factory TenantIntakeFieldOption.fromJson(Map<String, dynamic> json) =>
      TenantIntakeFieldOption(
        label: json['label'] as String,
        value: json['value'] as String,
      );
}

class TenantIntakeVisibleWhen {
  const TenantIntakeVisibleWhen({
    required this.field,
    required this.operator,
    this.value,
    this.values,
  });

  final String field;
  final String operator;
  final dynamic value;
  final List<String>? values;

  factory TenantIntakeVisibleWhen.fromJson(Map<String, dynamic> json) {
    final raw = json['value'];
    List<String>? list;
    if (raw is List) {
      list = raw.map((e) => e.toString()).toList();
    }
    return TenantIntakeVisibleWhen(
      field: json['field'] as String,
      operator: json['operator'] as String,
      value: raw is List ? null : raw,
      values: list,
    );
  }
}

class TenantIntakeLinkPreview {
  const TenantIntakeLinkPreview({
    required this.companyName,
    required this.formName,
    required this.expiresAt,
    required this.isValid,
    this.linkId,
    this.category,
  });

  final String? companyName;
  final String? formName;
  final DateTime? expiresAt;
  final bool isValid;
  final String? linkId;
  final String? category;

  factory TenantIntakeLinkPreview.fromJson(Map<String, dynamic> json) =>
      TenantIntakeLinkPreview(
        companyName: json['company_name'] as String?,
        formName: json['form_name'] as String?,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        isValid: json['is_valid'] as bool? ?? false,
        linkId: json['link_id'] as String?,
        category: json['category'] as String?,
      );
}

class TenantIntakeSubmitResult {
  const TenantIntakeSubmitResult({
    required this.protocol,
    required this.partyId,
    required this.submissionId,
  });

  final String protocol;
  final String partyId;
  final String submissionId;

  factory TenantIntakeSubmitResult.fromJson(Map<String, dynamic> json) =>
      TenantIntakeSubmitResult(
        protocol: json['protocol'] as String,
        partyId: json['party_id'] as String,
        submissionId: json['submission_id'] as String,
      );
}

class TenantIntakeCreatedLink {
  const TenantIntakeCreatedLink({
    required this.id,
    required this.token,
    required this.expiresAt,
    required this.category,
  });

  final String id;
  final String token;
  final DateTime expiresAt;
  final String category;
}
