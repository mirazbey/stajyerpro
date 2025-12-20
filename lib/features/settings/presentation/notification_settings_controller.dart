import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';

class NotificationSettingsState {
  final bool isEnabled;
  final TimeOfDay reminderTime;

  NotificationSettingsState({
    required this.isEnabled,
    required this.reminderTime,
  });

  NotificationSettingsState copyWith({
    bool? isEnabled,
    TimeOfDay? reminderTime,
  }) {
    return NotificationSettingsState(
      isEnabled: isEnabled ?? this.isEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

class NotificationSettingsController
    extends StateNotifier<AsyncValue<NotificationSettingsState>> {
  final NotificationService _notificationService;

  NotificationSettingsController(this._notificationService)
    : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('notifications_enabled') ?? true;
      final hour = prefs.getInt('notification_hour') ?? 19;
      final minute = prefs.getInt('notification_minute') ?? 0;

      final loadedState = NotificationSettingsState(
        isEnabled: isEnabled,
        reminderTime: TimeOfDay(hour: hour, minute: minute),
      );

      state = AsyncValue.data(loadedState);

      if (isEnabled) {
        await _scheduleNotification(loadedState.reminderTime);
      } else {
        await _notificationService.cancelAll();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleNotifications(bool value) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);

      state = AsyncValue.data(currentState.copyWith(isEnabled: value));

      if (value) {
        await _scheduleNotification(currentState.reminderTime);
      } else {
        await _notificationService.cancelAll();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTime(TimeOfDay newTime) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', newTime.hour);
      await prefs.setInt('notification_minute', newTime.minute);

      state = AsyncValue.data(currentState.copyWith(reminderTime: newTime));

      if (currentState.isEnabled) {
        await _scheduleNotification(newTime);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _scheduleNotification(TimeOfDay time) async {
    await _notificationService.cancelAll();
    await _notificationService.scheduleDailyReminder(
      id: 0,
      title: 'Çalışma Zamanı!',
      body: 'Bugünkü hedeflerini tamamlamak için harika bir zaman.',
      time: time,
    );
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<
      NotificationSettingsController,
      AsyncValue<NotificationSettingsState>
    >((ref) {
      final notificationService = ref.watch(notificationServiceProvider);
      return NotificationSettingsController(notificationService);
    });
