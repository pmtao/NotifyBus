import XCTest
@testable import NotifyBus

private let userNotificationCenter = NotificationCenter()

enum UserNotification: BasicNotifyObject {
  case logout
  case infoChanged
  
  var notifyCenter: NotificationCenter {
    return userNotificationCenter
  }
  
  var name: Notification.Name {
    switch self {
    case .logout:
      return Notification.Name("UserLogoutNotificationName")
    case .infoChanged:
      return Notification.Name("UserChangeInfoNotificationName")
    }
  }
  
}

enum MessageNotification: InfomedNotifyObject {
  case commonMessage(String?)
  case secreteMessage(String?)
  
  var notifyCenter: NotificationCenter {
    return userNotificationCenter
  }
  
  var name: Notification.Name {
    switch self {
    case .commonMessage:
      return Notification.Name("CommonMessageNotificationName")
    case .secreteMessage:
      return Notification.Name("SecreteMessageNotificationName")
    }
  }
  
  var userInfoKey: String {
    switch self {
    case .commonMessage, .secreteMessage:
      return "message"
    }
  }
  
  var userInfo: [String : Any]? {
    switch self {
    case .commonMessage(let msg):
      return msg == nil ? nil : [userInfoKey: msg!]
    case .secreteMessage(let msg):
      return msg == nil ? nil : [userInfoKey: msg!]
    }
  }
  
  func getObject(notification: Notification) -> MessageNotification {
    switch self {
    case .commonMessage:
      let userInfo = notification.userInfo!
      let msg = userInfo[self.userInfoKey]! as! String
      return .commonMessage(msg)
    case .secreteMessage:
      let userInfo = notification.userInfo!
      let msg = userInfo[self.userInfoKey]! as! String
      return .secreteMessage(msg)
    }
  }
}


final class NotifyBusTests: XCTestCase {
  
  
  func testExecuteLater() {
    var testNum = 0
    let expectation = self.expectation(description: "UserNotification test")
    let notifyBus = NotifyBus()
    notifyBus.observe(UserNotification.infoChanged, executeLater: true) { _ in
      testNum += 1
      XCTAssert(testNum == 1)
      expectation.fulfill()
      print("===testExecuteLater complete.===")
    }
    
    UserNotification.infoChanged.post()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      notifyBus.execute(UserNotification.infoChanged.name)
    }
    
    self.wait(for: [expectation], timeout: 2)
  }
  
  func testExecuteLaterFirst() {
    var testNum = 2
    let expectation = self.expectation(description: "UserNotification test")
    let notifyBus = NotifyBus()
    notifyBus.observe(UserNotification.infoChanged, executeLater: true, handleMode: .first(1)) { _ in
      testNum *= 2
    }
    UserNotification.infoChanged.post()
    UserNotification.infoChanged.post()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      notifyBus.execute(UserNotification.infoChanged.name)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      XCTAssert(testNum == 4)
      expectation.fulfill()
      print("===testExecuteLaterFirst complete.===")
    }
    self.wait(for: [expectation], timeout: 3)
  }
  
  func testExecuteLaterLast() {
    var msg = [String]()
    let expectation = self.expectation(description: "MessageNotification test")
    let notifyBus = NotifyBus()
    notifyBus.observe(MessageNotification.commonMessage(nil), executeLater: true, handleMode: .onlyLast) {
      notification in
      guard case let .commonMessage(_msg) = notification, let newMsg = _msg else { return }
      msg.append(newMsg)
    }
    MessageNotification.commonMessage("good").post()
    MessageNotification.commonMessage("bad").post()
    MessageNotification.commonMessage("nice").post()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      notifyBus.execute(MessageNotification.commonMessage(nil).name)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      XCTAssert(msg == ["nice"])
      expectation.fulfill()
      print("===testExecuteLaterLast complete.===")
    }
    self.wait(for: [expectation], timeout: 3)
  }
  
  static var allTests = [
    ("testExecuteLater", testExecuteLater),
    ("testExecuteLaterFirst", testExecuteLaterFirst),
    ("testExecuteLaterLast", testExecuteLaterLast),
  ]
}
