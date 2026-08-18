import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/configuration/formulas/domain/entities/formula_record.dart';
import 'package:erp_curtiembre_fronted/features/inventory/shared/domain/entities/insumo_lookup.dart';

enum FormulasStatus {
  loading,
  success,
  error,
}

enum FormulaActivityFilter {
  active,
  inactive,
  all,
}

class FormulasState extends Equatable {
  static const Object _sentinel = Object();

  const FormulasState({
    required this.status,
    this.items = const [],
    this.processOptions = const [],
    this.insumoOptions = const [],
    this.versions = const [],
    this.selectedFormulaId,
    this.selectedFormula,
    this.selectedVersionId,
    this.selectedVersion,
    this.errorMessage,
    this.formulaDetailErrorMessage,
    this.versionDetailErrorMessage,
    this.isFormulaDetailLoading = false,
    this.isVersionDetailLoading = false,
    this.isSubmittingAction = false,
    this.searchTerm = '',
    this.activityFilter = FormulaActivityFilter.active,
    this.processFilterId,
  });

  const FormulasState.loading() : this(status: FormulasStatus.loading);

  final FormulasStatus status;
  final List<FormulaRecord> items;
  final List<ProcesoProductivoOption> processOptions;
  final List<InsumoLookup> insumoOptions;
  final List<FormulaVersionRecord> versions;
  final int? selectedFormulaId;
  final FormulaRecord? selectedFormula;
  final int? selectedVersionId;
  final FormulaVersionRecord? selectedVersion;
  final String? errorMessage;
  final String? formulaDetailErrorMessage;
  final String? versionDetailErrorMessage;
  final bool isFormulaDetailLoading;
  final bool isVersionDetailLoading;
  final bool isSubmittingAction;
  final String searchTerm;
  final FormulaActivityFilter activityFilter;
  final int? processFilterId;

  FormulasState copyWith({
    FormulasStatus? status,
    List<FormulaRecord>? items,
    List<ProcesoProductivoOption>? processOptions,
    List<InsumoLookup>? insumoOptions,
    List<FormulaVersionRecord>? versions,
    Object? selectedFormulaId = _sentinel,
    FormulaRecord? selectedFormula,
    Object? selectedVersionId = _sentinel,
    FormulaVersionRecord? selectedVersion,
    String? errorMessage,
    String? formulaDetailErrorMessage,
    String? versionDetailErrorMessage,
    bool? isFormulaDetailLoading,
    bool? isVersionDetailLoading,
    bool? isSubmittingAction,
    String? searchTerm,
    Object? processFilterId = _sentinel,
    FormulaActivityFilter? activityFilter,
    bool clearError = false,
    bool clearFormulaDetailError = false,
    bool clearVersionDetailError = false,
    bool clearSelectedFormula = false,
    bool clearSelectedVersion = false,
  }) {
    return FormulasState(
      status: status ?? this.status,
      items: items ?? this.items,
      processOptions: processOptions ?? this.processOptions,
      insumoOptions: insumoOptions ?? this.insumoOptions,
      versions: versions ?? this.versions,
      selectedFormulaId: identical(selectedFormulaId, _sentinel)
          ? this.selectedFormulaId
          : selectedFormulaId as int?,
      selectedFormula:
          clearSelectedFormula ? null : selectedFormula ?? this.selectedFormula,
      selectedVersionId: identical(selectedVersionId, _sentinel)
          ? this.selectedVersionId
          : selectedVersionId as int?,
      selectedVersion:
          clearSelectedVersion ? null : selectedVersion ?? this.selectedVersion,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      formulaDetailErrorMessage: clearFormulaDetailError
          ? null
          : formulaDetailErrorMessage ?? this.formulaDetailErrorMessage,
      versionDetailErrorMessage: clearVersionDetailError
          ? null
          : versionDetailErrorMessage ?? this.versionDetailErrorMessage,
      isFormulaDetailLoading:
          isFormulaDetailLoading ?? this.isFormulaDetailLoading,
      isVersionDetailLoading:
          isVersionDetailLoading ?? this.isVersionDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      searchTerm: searchTerm ?? this.searchTerm,
      processFilterId: identical(processFilterId, _sentinel)
          ? this.processFilterId
          : processFilterId as int?,
      activityFilter: activityFilter ?? this.activityFilter,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        processOptions,
        insumoOptions,
        versions,
        selectedFormulaId,
        selectedFormula,
        selectedVersionId,
        selectedVersion,
        errorMessage,
        formulaDetailErrorMessage,
        versionDetailErrorMessage,
        isFormulaDetailLoading,
        isVersionDetailLoading,
        isSubmittingAction,
        searchTerm,
        activityFilter,
        processFilterId,
      ];
}
