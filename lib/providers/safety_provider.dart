import 'package:flutter/foundation.dart';

import '../models/safety_contact.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';

/// Central source of truth for the logged-in user's safety contacts.
/// Both the "setup required" prompt at login and the SOS button (next
/// stage) read from this, so they never disagree about whether contacts
/// exist.
class SafetyProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<SafetyContact> contacts = [];
  bool loaded = false;
  bool loading = false;
  String? errorMessage;

  bool get hasContacts => contacts.isNotEmpty;

  Future<void> refresh() async {
    final online = await ConnectivityService.instance.hasConnection();
    if (!online) {
      // Don't block anything over a network hiccup - just leave whatever
      // was last loaded (possibly empty) and let the caller decide.
      return;
    }

    loading = true;
    notifyListeners();

    try {
      contacts = await _api.fetchSafetyContacts();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      loaded = true;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> delete(int contactId) async {
    await _api.deleteSafetyContact(contactId);
    contacts = contacts.where((c) => c.id != contactId).toList();
    notifyListeners();
  }

  void reset() {
    contacts = [];
    loaded = false;
    loading = false;
    errorMessage = null;
  }
}
