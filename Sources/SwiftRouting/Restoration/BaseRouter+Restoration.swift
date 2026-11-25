//
//  BaseRouter+Restoration.swift
//  swift-routing
//

extension BaseRouter {

  /// Erases the saved navigation state of this scene.
  ///
  /// Call it when the user logs out, so the next launch does not reopen account screens. It empties
  /// the saved state and erases the copy written by ``SwiftUICore/View/navigationRestoration(_:)``.
  /// It does nothing when restoration is not enabled.
  ///
  /// Saving is not blocked: the next time the app leaves the foreground, the navigation at that
  /// moment is saved again. Navigate to the login screen first, then clear.
  ///
  /// ```swift
  /// func logout() {
  ///   router.update(root: AppRoute.login)
  ///   router.clearNavigationRestoration()
  /// }
  /// ```
  public func clearNavigationRestoration() {
    restorationStore?.clear()
  }
}
