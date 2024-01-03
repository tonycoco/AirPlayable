//
//  SafariExtensionHandler.swift
//  AirPlayable Extension
//
//  Created by Tony Coconate on 1/3/24.
//

import SafariServices

class StateManager {
  static let shared = StateManager()

  private init() {}

  var videosFound: [SFSafariPage: Int] = [:]
}

class SafariExtensionHandler: SFSafariExtensionHandler {
  override func messageReceived(
    withName messageName: String,
    from page: SFSafariPage,
    userInfo: [String: Any]?
  ) {
    if messageName == "videosChanged" {
      StateManager.shared.videosFound[page] = userInfo?["count"] as? Int ?? 0
      SFSafariApplication.setToolbarItemsNeedUpdate()
    }
  }

  override func toolbarItemClicked(in window: SFSafariWindow) {
    getActivePage {
      guard let page = $0 else { return }
      page.dispatchMessageToScript(withName: "toolbarItemClicked")
    }
  }

  override func validateToolbarItem(
    in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)
  ) {
    getActivePage {
      guard let page = $0 else { return }

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
