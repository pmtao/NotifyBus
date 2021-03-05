//
//  NotifyObject.swift
//  
//
//  Created by Meler Paine on 2021/3/5.
//

import Foundation

/// only notify with name
protocol BasicNotifyObject {
  var name: Notification.Name { get }
  var notifyCenter: NotificationCenter { get }
}

/// notify with name and structured infomation
protocol InfomedNotifyObject: BasicNotifyObject {
  var userInfoKey: String { get }
  var userInfo: [String: Any] { get }
  func getObject(notification: Notification) -> Self
}

extension BasicNotifyObject {
  func post() {
    notifyCenter.post(name: self.name,
                      object: nil,
                      userInfo: nil)
  }
}

extension InfomedNotifyObject {
  func post() {
    notifyCenter.post(name: self.name,
                      object: nil,
                      userInfo: self.userInfo)
  }
}

