import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monteage_employee/models/sales_lead_model.dart';
import 'package:monteage_employee/services/sales_api.dart';

/// Load state of one lead list.
class SalesListState {
  final RxList<SalesLead> leads = <SalesLead>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;
  final RxString errorMessage = ''.obs;
}

/// Owns every Sales lead list so the home counts and the list screens share
/// one copy of the data and refresh together after a follow-up update.
class SalesController extends GetxController {
  static const List<String> followupActions = [
    'Next Session',
    'Not eligible',
    'Registered',
    'In Progress',
    'Invalid',
    'Contacted',
    'Not Reachable',
    'Not Interested',
    'Duplicate',
    'Closed',
  ];

  final Map<SalesListType, SalesListState> lists = {
    for (final type in SalesListType.values) type: SalesListState(),
  };

  final RxString cId = ''.obs;
  final RxString salesName = ''.obs;
  final RxBool isSaving = false.obs;

  bool get isLinked => cId.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    cId.value = SalesApi.storedCId();
    salesName.value = (GetStorage().read(SalesApi.nameKey) ?? '').toString();
    refreshAll();
  }

  SalesListState stateOf(SalesListType type) => lists[type]!;

  /// Re-reads the stored sales account, which login links in the background.
  Future<void> relink() {
    cId.value = SalesApi.storedCId();
    salesName.value = (GetStorage().read(SalesApi.nameKey) ?? '').toString();
    return refreshAll();
  }

  Future<void> refreshAll() {
    return Future.wait(SalesListType.values.map(load));
  }

  Future<void> load(SalesListType type) async {
    final state = stateOf(type);
    if (!isLinked) {
      state.errorMessage.value = '';
      return;
    }

    state.isLoading.value = true;
    state.errorMessage.value = '';
    try {
      state.leads.assignAll(await SalesApi.fetchLeads(type, cId.value));
      state.hasLoaded.value = true;
    } on SalesApiException catch (e) {
      state.errorMessage.value = e.message;
    } catch (e) {
      state.errorMessage.value = 'Could not load ${type.title.toLowerCase()}.';
      debugPrint('Sales load ${type.name} error: $e');
    } finally {
      state.isLoading.value = false;
    }
  }

  /// Saves a follow-up for [lead]. Returns an error message, or null when it
  /// was saved.
  Future<String?> updateFollowup({
    required SalesLead lead,
    required String action,
    required DateTime followupAt,
    required String remarks,
  }) async {
    if (isSaving.value) return null;
    isSaving.value = true;
    try {
      await SalesApi.updateFollowup({
        'LeadsId': lead.leadsId,
        'LSubstatus': lead.subStatus,
        'LAction': action,
        'LFollowupdate': _formatForApi(followupAt),
        'LRemarks': remarks.trim(),
        'Updateby': cId.value,
      });
      refreshAll();
      return null;
    } on SalesApiException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('Sales updateFollowup error: $e');
      return 'Could not update follow-up. Please try again.';
    } finally {
      isSaving.value = false;
    }
  }

  static String _formatForApi(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
