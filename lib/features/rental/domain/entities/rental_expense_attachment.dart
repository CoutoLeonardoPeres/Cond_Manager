import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class RentalExpenseAttachment extends Equatable {
  const RentalExpenseAttachment({
    required this.id,
    required this.financialRecordId,
    required this.companyId,
    required this.fileUrl,
    required this.filePath,
    this.fileName,
    this.mimeType,
    required this.createdAt,
  });

  final String id;
  final String financialRecordId;
  final String companyId;
  final String fileUrl;
  final String filePath;
  final String? fileName;
  final String? mimeType;
  final DateTime createdAt;

  bool get isPdf => mimeType == 'application/pdf' || (fileName?.toLowerCase().endsWith('.pdf') ?? false);

  bool get isImage {
    final mime = mimeType?.toLowerCase();
    if (mime != null && mime.startsWith('image/')) return true;
    final name = fileName?.toLowerCase() ?? '';
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        name.endsWith('.heic') ||
        name.endsWith('.heif');
  }

  @override
  List<Object?> get props => [id];
}

class PendingRentalExpenseAttachment {
  const PendingRentalExpenseAttachment({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}
