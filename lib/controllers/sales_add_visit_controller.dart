import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:monteage_employee/controllers/sales_controller.dart';
import 'package:monteage_employee/models/sales_lead_model.dart';
import 'package:monteage_employee/services/sales_api.dart';

class SalesAddVisitController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final organizationController = TextEditingController();
  final contactNameController = TextEditingController();
  final phoneController = TextEditingController();
  final alternatePhoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final remarksController = TextEditingController();

  final RxList<SalesVisitType> visitTypes = <SalesVisitType>[].obs;
  final Rxn<SalesVisitType> selectedType = Rxn<SalesVisitType>();
  final RxBool isLoadingTypes = false.obs;
  final RxString typesError = ''.obs;

  final RxBool isLocating = false.obs;
  final RxnDouble latitude = RxnDouble();
  final RxnDouble longitude = RxnDouble();
  final RxString locationText = ''.obs;
  final RxString locationError = ''.obs;

  final RxBool isSubmitting = false.obs;

  String get _cId => SalesApi.storedCId();

  @override
  void onInit() {
    super.onInit();
    loadVisitTypes();
    captureLocation();
  }

  Future<void> loadVisitTypes() async {
    isLoadingTypes.value = true;
    typesError.value = '';
    try {
      visitTypes.assignAll(await SalesApi.fetchVisitTypes(_cId));
      if (visitTypes.isEmpty) typesError.value = 'No visit types available.';
    } on SalesApiException catch (e) {
      typesError.value = e.message;
    } catch (e) {
      typesError.value = 'Could not load visit types.';
      debugPrint('Sales visit types error: $e');
    } finally {
      isLoadingTypes.value = false;
    }
  }

  Future<void> captureLocation() async {
    isLocating.value = true;
    locationError.value = '';
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        locationError.value = 'Turn on location services to tag this visit.';
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        locationError.value = 'Location permission is needed to tag this visit.';
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      latitude.value = pos.latitude;
      longitude.value = pos.longitude;
      locationText.value = await _addressFor(pos.latitude, pos.longitude);
    } catch (e) {
      locationError.value = 'Could not get your location. Tap to retry.';
      debugPrint('Sales location error: $e');
    } finally {
      isLocating.value = false;
    }
  }

  Future<String> _addressFor(double lat, double lng) async {
    try {
      final placemarks =
          await Geocoding().placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String?>[
          p.name,
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ].map((s) => (s ?? '').trim()).where((s) => s.isNotEmpty).toSet();
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (e) {
      debugPrint('Sales reverse geocode error: $e');
    }
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  String? validateRequired(String? value, String label) =>
      (value ?? '').trim().isEmpty ? 'Enter $label' : null;

  String? validatePhone(String? value, {bool required = true}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return required ? 'Enter phone number' : null;
    return RegExp(r'^\d{10}$').hasMatch(v)
        ? null
        : 'Enter a valid 10-digit number';
  }

  String? validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)
        ? null
        : 'Enter a valid email address';
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;
    if (selectedType.value == null) {
      Get.snackbar('Visit type', 'Select a visit type.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;

    isSubmitting.value = true;
    try {
      await SalesApi.addVisit({
        'CourseId': selectedType.value!.id,
        'Organizationname': organizationController.text.trim(),
        'Contactname': contactNameController.text.trim(),
        'LMobile': phoneController.text.trim(),
        'LEmail': emailController.text.trim(),
        'OrgAddress': addressController.text.trim(),
        'LRemarks': remarksController.text.trim(),
        'CreateBy': _cId,
        'Leadlatitude': latitude.value?.toString() ?? '',
        'Leadlongitude': longitude.value?.toString() ?? '',
        'CurruntAddrs': locationText.value,
        'AlternateMobile': alternatePhoneController.text.trim(),
      });

      if (Get.isRegistered<SalesController>()) {
        Get.find<SalesController>().refreshAll();
      }
      Get.back();
      Get.snackbar('Visit added', 'The visit was saved successfully.',
          snackPosition: SnackPosition.BOTTOM);
    } on SalesApiException catch (e) {
      Get.snackbar('Could not add visit', e.message,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('Sales add visit error: $e');
      Get.snackbar('Could not add visit', 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    organizationController.dispose();
    contactNameController.dispose();
    phoneController.dispose();
    alternatePhoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    remarksController.dispose();
    super.onClose();
  }
}
