import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/configuration/system_parameters/domain/entities/system_parameter_record.dart';

enum SystemParametersStatus {
  loading,
  success,
  error,
}

enum SystemParameterEditabilityFilter {
  all,
  editable,
  readOnly,
}

class SystemParametersState extends Equatable {
  static const Object _sentinel = Object();

  const SystemParametersState({
    required this.status,
    this.allItems = const [],
    this.visibleItems = const [],
    this.selectedParameterId,
    this.selectedParameter,
    this.errorMessage,
    this.searchTerm = '',
    this.editabilityFilter = SystemParameterEditabilityFilter.all,
    this.typeFilter = '',
  });

  const SystemParametersState.loading()
      : this(
          status: SystemParametersStatus.loading,
        );

  final SystemParametersStatus status;
  final List<SystemParameterRecord> allItems;
  final List<SystemParameterRecord> visibleItems;
  final int? selectedParameterId;
  final SystemParameterRecord? selectedParameter;
  final String? errorMessage;
  final String searchTerm;
  final SystemParameterEditabilityFilter editabilityFilter;
  final String typeFilter;

  List<String> get availableTypes {
    final values = allItems
        .map((item) => item.tipoDato.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  SystemParametersState copyWith({
    SystemParametersStatus? status,
    List<SystemParameterRecord>? allItems,
    List<SystemParameterRecord>? visibleItems,
    Object? selectedParameterId = _sentinel,
    Object? selectedParameter = _sentinel,
    String? errorMessage,
    String? searchTerm,
    SystemParameterEditabilityFilter? editabilityFilter,
    String? typeFilter,
    bool clearError = false,
  }) {
    return SystemParametersState(
      status: status ?? this.status,
      allItems: allItems ?? this.allItems,
      visibleItems: visibleItems ?? this.visibleItems,
      selectedParameterId: identical(selectedParameterId, _sentinel)
          ? this.selectedParameterId
          : selectedParameterId as int?,
      selectedParameter: identical(selectedParameter, _sentinel)
          ? this.selectedParameter
          : selectedParameter as SystemParameterRecord?,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      searchTerm: searchTerm ?? this.searchTerm,
      editabilityFilter: editabilityFilter ?? this.editabilityFilter,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allItems,
        visibleItems,
        selectedParameterId,
        selectedParameter,
        errorMessage,
        searchTerm,
        editabilityFilter,
        typeFilter,
      ];
}
