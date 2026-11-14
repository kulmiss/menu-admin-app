import 'models.dart';

/// Mirrors the server's gates (AuthorizationServiceProvider) to hide what a
/// role can't do. The server still decides; this only keeps the UI honest.
class Can {
  const Can(this.tenant);
  final TenantInfo? tenant;

  Role? get _role => tenant?.role;
  bool get _managerOrOwner => _role == Role.owner || _role == Role.manager;

  bool get manageMenu => _managerOrOwner;
  bool get manageRestaurant => _managerOrOwner;
  bool get viewTeam => _managerOrOwner;
  bool get viewActivity => _managerOrOwner;
  bool get manageAccount => _role == Role.owner;
  bool get viewBilling => _role == Role.owner;
  bool get toggleSoldOut => _role != null;
  bool get viewInsights => _managerOrOwner;

  /// The server sends `can_edit_prices` already resolved (owner/manager always; staff when allowed).
  bool get editPrices => tenant?.canEditPricesFlag ?? false;
  bool get exportDishes => _managerOrOwner;

  /// Can this role change [target]'s role or remove them?
  bool manage(Role target) => switch (_role) {
    Role.owner => true,
    Role.manager => target == Role.staff,
    _ => false,
  };

  /// Plan switch (shows an "Upgrade" badge when off).
  bool feature(String key) => tenant?.feature(key) ?? false;

  /// Writes refused while the subscription is read-only (402).
  bool get writable => tenant?.allowsWrites ?? true;
}
