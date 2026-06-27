import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class RentalPropertyPhoto extends Equatable {
  const RentalPropertyPhoto({
    required this.id,
    required this.companyId,
    required this.propertyId,
    required this.fileUrl,
    required this.filePath,
    this.fileName,
    this.mimeType,
    this.sortOrder = 0,
  });

  final String id;
  final String companyId;
  final String propertyId;
  final String fileUrl;
  final String filePath;
  final String? fileName;
  final String? mimeType;
  final int sortOrder;

  @override
  List<Object?> get props => [id];
}

class PendingRentalPropertyPhoto extends Equatable {
  const PendingRentalPropertyPhoto({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  @override
  List<Object?> get props => [fileName];
}

/// Foto na UI — existente no servidor ou pendente de envio.
class RentalPropertyPhotoDraft extends Equatable {
  const RentalPropertyPhotoDraft.existing(this.photo)
      : pending = null,
        localKey = null;

  const RentalPropertyPhotoDraft.pending({
    required this.pending,
    required this.localKey,
  }) : photo = null;

  final RentalPropertyPhoto? photo;
  final PendingRentalPropertyPhoto? pending;
  final String? localKey;

  bool get isPending => pending != null;

  String get displayName => photo?.fileName ?? pending?.fileName ?? 'foto';

  @override
  List<Object?> get props => [photo?.id, localKey];
}
