import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../datos/api_services/api_service.dart';

class ProfileImageState {
  final bool isUploading;
  final String? error;
  final String? successMessage;

  const ProfileImageState({
    this.isUploading = false,
    this.error,
    this.successMessage,
  });

  ProfileImageState copyWith({
    bool? isUploading,
    String? error,
    String? successMessage,
  }) {
    return ProfileImageState(
      isUploading: isUploading ?? this.isUploading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class ProfileImageNotifier extends StateNotifier<ProfileImageState> {
  final ApiService _apiService = ApiService();

  ProfileImageNotifier() : super(const ProfileImageState());

  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      state = state.copyWith(
        isUploading: true,
        error: null,
        successMessage: null,
      );

      await _apiService.uploadProfileImage(imageFile);

      state = state.copyWith(
        isUploading: false,
        successMessage: 'Imagen de perfil actualizada exitosamente',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Error al subir imagen: $e',
      );
      return false;
    }
  }

  Future<bool> uploadUserProfileImage(BigInt userId, File imageFile) async {
    try {
      state = state.copyWith(
        isUploading: true,
        error: null,
        successMessage: null,
      );

      await _apiService.uploadUserProfileImage(userId, imageFile);

      state = state.copyWith(
        isUploading: false,
        successMessage: 'Imagen de perfil actualizada exitosamente',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Error al subir imagen: $e',
      );
      return false;
    }
  }

  Future<bool> deleteProfileImage() async {
    try {
      state = state.copyWith(
        isUploading: true,
        error: null,
        successMessage: null,
      );

      await _apiService.deleteProfileImage();

      state = state.copyWith(
        isUploading: false,
        successMessage: 'Imagen de perfil eliminada exitosamente',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Error al eliminar imagen: $e',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }
}

final profileImageProvider =
    StateNotifierProvider<ProfileImageNotifier, ProfileImageState>(
      (ref) => ProfileImageNotifier(),
    );
