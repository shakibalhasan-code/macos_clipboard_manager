import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/clipboard_item.dart';
import '../services/clipboard_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';

class ClipboardController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final ClipboardService _clipboardService = Get.find<ClipboardService>();
  final PermissionService _permissionService = PermissionService();

  // Reactive State
  final RxList<ClipboardItem> items = <ClipboardItem>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool hasPermission = false.obs;

  Timer? _permissionCheckTimer;

  @override
  void onInit() {
    super.onInit();
    _loadItems();
    _checkPermission();

    // Listen to services
    _clipboardService.onNewItem.listen((_) => _loadItems());
    _storageService.changes.listen((_) => _loadItems());

    // Periodic permission check
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkPermission();
    });
  }

  @override
  void onClose() {
    _permissionCheckTimer?.cancel();
    super.onClose();
  }

  void onResume() {
    debugPrint('App resumed, checking permission...');
    _checkPermission();
  }

  void onWindowFocus() {
    _checkPermission();
  }

  // --- Logic Methods ---

  Future<void> _checkPermission() async {
    final permission = await _permissionService.checkAccessibilityPermission();
    if (permission != hasPermission.value) {
      hasPermission.value = permission;
    }
  }

  void _loadItems() {
    if (searchQuery.isEmpty) {
      items.value = _storageService.getAll();
    } else {
      items.value = _storageService.search(searchQuery.value);
    }
  }

  void onSearch(String query) {
    searchQuery.value = query;
    _loadItems();
  }

  void clearSearch() {
    searchQuery.value = '';
    _loadItems();
  }

  Future<void> copyItem(ClipboardItem item) async {
    try {
      await _clipboardService.copyToClipboard(item);

      Get.rawSnackbar(
        messageText: Text(
          item.type == ClipboardType.text
              ? 'Copied to clipboard'
              : 'Image copied',
          style: const TextStyle(color: Colors.white),
        ),
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 800),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        maxWidth: 200,
      );
    } catch (e) {
      debugPrint('Error copying item: $e');
    }
  }

  Future<void> deleteItem(ClipboardItem item) async {
    await _storageService.remove(item.id);
    _loadItems();
  }

  Future<void> togglePin(ClipboardItem item) async {
    await _storageService.togglePin(item.id);
    _loadItems();
  }

  Future<void> clearHistory() async {
    await _storageService.clearHistory();
    _loadItems();
  }
}
