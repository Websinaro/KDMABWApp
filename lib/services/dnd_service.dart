import 'package:flutter/services.dart';

class DndService {
  DndService._internal();
  static final DndService instance = DndService._internal();

  static const _channel = MethodChannel('com.webalert/dnd');

  Future<bool> hasDndAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasDndAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openDndSettings() async {
    try {
      await _channel.invokeMethod('openDndSettings');
    } catch (_) {}
  }

  Future<void> createSosChannel() async {
    try {
      await _channel.invokeMethod('createSosChannel');
    } catch (_) {}
  }
}