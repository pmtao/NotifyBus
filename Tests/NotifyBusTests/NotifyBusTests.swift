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


final class NotifyBusTests: XCTestCase {
  var testNum = 0
  var expectation: XCTestExpectation?
  
  func testExample() {
    expectation = self.expectation(description: "UserNotification test")
    let notifyBus = NotifyBus()
    
    notifyBus.observe(UserNotification.infoChanged, runAtOnce: false, handler: userInfoChangedNotify)
    UserNotification.infoChanged.post()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      notifyBus.executeHandler(of: UserNotification.infoChanged.name)
    }
    
    self.wait(for: [expectation!], timeout: 2)
  }
  
  func userInfoChangedNotify(notificationInfo: UserNotification) {
    testNum += 1
    XCTAssert(self.testNum == 1)
    expectation!.fulfill()
    print("===userInfoChangedNotify complete.===")
  }
  
  static var allTests = [
    ("testExample", testExample),
  ]
}
