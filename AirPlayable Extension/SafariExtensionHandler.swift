import SafariServices

class StateManager {
  static let shared = StateManager()

  private init() {}

  var videosFound: [SFSafariPage: Int] = [:]

  func updateVideosCount(for page: SFSafariPage, count: Int) {
    DispatchQueue.main.async {
      self.videosFound[page] = count
    }
  }

  func removePage(_ page: SFSafariPage) {
    DispatchQueue.main.async {
      self.videosFound.removeValue(forKey: page)
    }
  }
}

class SafariExtensionHandler: SFSafariExtensionHandler {
  override func messageReceived(
    withName messageName: String,
    from page: SFSafariPage,
    userInfo: [String: Any]?
  ) {
    switch messageName {
    case "videosChanged":
      guard let count = userInfo?["count"] as? Int else { return }
      StateManager.shared.updateVideosCount(for: page, count: count)
      SFSafariApplication.setToolbarItemsNeedUpdate()
    case "pageUnloaded":
      StateManager.shared.removePage(page)
    default:
      break
    }
  }

  override func toolbarItemClicked(in window: SFSafariWindow) {
    getActivePage { page in
      guard let page = page else { return }
      page.dispatchMessageToScript(withName: "toolbarItemClicked")
    }
  }

  override func validateToolbarItem(
    in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)
  ) {
    getActivePage {
      guard let page = $0 else {
        validationHandler(false, "")
        return
      }

      let videosFound = StateManager.shared.videosFound[page] ?? 0
      validationHandler(videosFound > 0, "")
    }
  }

  func getActivePage(completionHandler: @escaping (SFSafariPage?) -> Void) {
    SFSafariApplication.getActiveWindow {
      $0?.getActiveTab { $0?.getActivePage(completionHandler: completionHandler) }
    }
  }
}
