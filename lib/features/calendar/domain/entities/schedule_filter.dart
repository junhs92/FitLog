import 'package:equatable/equatable.dart';
import 'schedule_entry.dart';

/// Filter criteria for schedule queries
class ScheduleFilter extends Equatable {
  final List<String> clientIds;
  final List<ScheduleStatus> statuses;
  final String? searchQuery;

  const ScheduleFilter({
    this.clientIds = const [],
    this.statuses = const [],
    this.searchQuery,
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      clientIds.isNotEmpty ||
      (statuses.isNotEmpty && statuses.length < ScheduleStatus.values.length) ||
      (searchQuery?.isNotEmpty ?? false);

  /// Create a copy with updated values
  ScheduleFilter copyWith({
    List<String>? clientIds,
    List<ScheduleStatus>? statuses,
    String? searchQuery,
  }) {
    return ScheduleFilter(
      clientIds: clientIds ?? this.clientIds,
      statuses: statuses ?? this.statuses,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Clear all filters
  ScheduleFilter clear() {
    return const ScheduleFilter();
  }

  @override
  List<Object?> get props => [clientIds, statuses, searchQuery];
}
