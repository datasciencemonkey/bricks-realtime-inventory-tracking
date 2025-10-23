import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/batch_event.dart';
import '../services/api_service.dart';
import 'inventory_provider.dart';

// Batches list provider
final batchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getBatches();
});

// Selected batch ID state
final selectedBatchIdProvider = StateProvider<String?>((ref) => null);

// Batch events provider for selected batch
final batchEventsProvider = FutureProvider<List<BatchEvent>>((ref) async {
  final batchId = ref.watch(selectedBatchIdProvider);
  if (batchId == null) return [];

  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getBatchEvents(batchId);
});

// Route coordinates provider with OSRM routing
final routeCoordinatesProvider = FutureProvider<List<LatLng>>((ref) async {
  final events = await ref.watch(batchEventsProvider.future);
  if (events.length < 2) return [];

  final apiService = ref.watch(apiServiceProvider);
  List<LatLng> allRouteCoords = [];

  for (int i = 0; i < events.length - 1; i++) {
    final curr = events[i];
    final next = events[i + 1];
    final routeSegment = await apiService.getRoute(
      curr.entityLatitude,
      curr.entityLongitude,
      next.entityLatitude,
      next.entityLongitude,
    );

    if (i == 0) {
      allRouteCoords.addAll(routeSegment);
    } else {
      allRouteCoords.addAll(routeSegment.skip(1));
    }
  }

  return allRouteCoords;
});

// Animation state
class AnimationState {
  final bool isAnimating;
  final int currentStep;
  final String currentStatus;

  AnimationState({
    required this.isAnimating,
    required this.currentStep,
    required this.currentStatus,
  });

  AnimationState copyWith({
    bool? isAnimating,
    int? currentStep,
    String? currentStatus,
  }) {
    return AnimationState(
      isAnimating: isAnimating ?? this.isAnimating,
      currentStep: currentStep ?? this.currentStep,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }
}

final animationStateProvider =
    StateNotifierProvider<AnimationStateNotifier, AnimationState>((ref) {
  return AnimationStateNotifier();
});

class AnimationStateNotifier extends StateNotifier<AnimationState> {
  AnimationStateNotifier()
      : super(AnimationState(
          isAnimating: false,
          currentStep: 0,
          currentStatus: '',
        ));

  void startAnimation(String initialStatus) {
    state = AnimationState(
      isAnimating: true,
      currentStep: 0,
      currentStatus: initialStatus,
    );
  }

  void updateStep(int step, String status) {
    state = state.copyWith(
      currentStep: step,
      currentStatus: status,
    );
  }

  void stopAnimation(int finalStep, String finalStatus) {
    state = AnimationState(
      isAnimating: false,
      currentStep: finalStep,
      currentStatus: finalStatus,
    );
  }
}
