import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:monteage_employee/models/sales_lead_model.dart';
import 'package:monteage_employee/services/sales_api.dart';

/// Shows one lead (passed as the route argument) and its follow-up history.
class SalesLeadDetailController extends GetxController {
  late final SalesLead lead;

  final RxList<SalesFollowupEntry> history = <SalesFollowupEntry>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    lead = Get.arguments as SalesLead;
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      history.assignAll(await SalesApi.fetchFollowupHistory(lead.leadsId));
    } on SalesApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Could not load follow-up history.';
      debugPrint('Sales history error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
