import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';

class SettingsState {
  final bool performanceMode;
  final String themeMode;

  const SettingsState({
    this.performanceMode = false,
    this.themeMode = 'system',
  });

  SettingsState copyWith({bool? performanceMode, String? themeMode}) {
    return SettingsState(
      performanceMode: performanceMode ?? this.performanceMode,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsController extends StateNotifier<AsyncValue<SettingsState>> {
  final SettingsRepository _repository;

  SettingsController(this._repository) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final performanceMode = await _repository.getPerformanceMode();
      final themeMode = await _repository.getThemeMode();
      state = AsyncValue.data(
        SettingsState(performanceMode: performanceMode, themeMode: themeMode),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> togglePerformanceMode(bool value) async {
    try {
      await _repository.setPerformanceMode(value);
      state = AsyncValue.data(state.value!.copyWith(performanceMode: value));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateThemeMode(String mode) async {
    try {
      await _repository.setThemeMode(mode);
      state = AsyncValue.data(state.value!.copyWith(themeMode: mode));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<SettingsState>>((ref) {
      final repository = ref.watch(settingsRepositoryProvider);
      return SettingsController(repository);
    });
