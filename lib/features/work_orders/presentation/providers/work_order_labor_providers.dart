import 'package:cond_manager/features/work_orders/domain/entities/work_order_labor.dart';
import 'package:cond_manager/features/work_orders/presentation/providers/work_order_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workOrderLaborProvider =
    FutureProvider.autoDispose.family<WorkOrderLaborTotals, String>((ref, workOrderId) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  final result = await repo.listLabor(workOrderId);
  return result.when(
    success: (t) => t,
    failure: (e) => throw e,
  );
});
