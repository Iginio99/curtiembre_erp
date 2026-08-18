import 'package:equatable/equatable.dart';
import 'package:erp_curtiembre_fronted/features/security/domain/entities/security_role.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_area_option.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_detail.dart';
import 'package:erp_curtiembre_fronted/features/users/domain/entities/user_list_item.dart';

enum UsersStatus {
  loading,
  success,
  error,
}

enum UserActivityFilter {
  active,
  inactive,
  all,
}

class UsersState extends Equatable {
  static const Object _sentinel = Object();

  const UsersState({
    required this.status,
    this.items = const [],
    this.selectedUserId,
    this.selectedUserDetail,
    this.errorMessage,
    this.detailErrorMessage,
    this.isDetailLoading = false,
    this.isSubmittingAction = false,
    this.roles = const [],
    this.areas = const [],
    this.searchTerm = '',
    this.filter = UserActivityFilter.active,
  });

  const UsersState.loading() : this(status: UsersStatus.loading);

  final UsersStatus status;
  final List<UserListItem> items;
  final int? selectedUserId;
  final UserDetail? selectedUserDetail;
  final String? errorMessage;
  final String? detailErrorMessage;
  final bool isDetailLoading;
  final bool isSubmittingAction;
  final List<SecurityRole> roles;
  final List<UserAreaOption> areas;
  final String searchTerm;
  final UserActivityFilter filter;

  UsersState copyWith({
    UsersStatus? status,
    List<UserListItem>? items,
    Object? selectedUserId = _sentinel,
    UserDetail? selectedUserDetail,
    String? errorMessage,
    String? detailErrorMessage,
    bool? isDetailLoading,
    bool? isSubmittingAction,
    List<SecurityRole>? roles,
    List<UserAreaOption>? areas,
    String? searchTerm,
    UserActivityFilter? filter,
    bool clearError = false,
    bool clearDetailError = false,
    bool clearSelectedUserDetail = false,
  }) {
    return UsersState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedUserId: identical(selectedUserId, _sentinel)
          ? this.selectedUserId
          : selectedUserId as int?,
      selectedUserDetail: clearSelectedUserDetail
          ? null
          : selectedUserDetail ?? this.selectedUserDetail,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage:
          clearDetailError ? null : detailErrorMessage ?? this.detailErrorMessage,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      roles: roles ?? this.roles,
      areas: areas ?? this.areas,
      searchTerm: searchTerm ?? this.searchTerm,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        selectedUserId,
        selectedUserDetail,
        errorMessage,
        detailErrorMessage,
        isDetailLoading,
        isSubmittingAction,
        roles,
        areas,
        searchTerm,
        filter,
      ];
}
