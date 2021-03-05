# NotifyBus

Provide light weight notification bus on top of NotificationCenter, with typed message, don't need to mess with userInfo.

Usage

## Simple notification

- Definin Notification object:

```swift
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
```

- Initial bus and add observer:

```swift
let notifyBus = NotifyBus()
notifyBus.observe(UserNotification.infoChanged, handler: userInfoChangedNotify)
// observe on special OperationQueue
notifyBus.observe(UserNotification.infoChanged, queue: OperationQueue(), runAtOnce: false, handler: userInfoChangedNotify)

func userInfoChangedNotify(notificationInfo: UserNotification) {
	// ...
}
```

- Post message:

```swift
UserNotification.infoChanged.post()
```

## Manually execute notification handler

- You can choose to receive notification but execute later:

```swift
notifyBus.observe(UserNotification.infoChanged, runAtOnce: false, handler: userInfoChangedNotify)

// manully run notification handler later:
DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
  notifyBus.execute(UserNotification.infoChanged.name)
}
```

## Typed notification

- You can notify with typed info:

```swift
// Redefine UserNotification
enum UserNotification: InfomedNotifyObject {
  case logout
  case infoChanged(User?)
  
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
  
  var userInfoKey: String {
    switch self {
    case .infoChanged:
      return "userInfo"
    default:
      return ""
    }
  }
  
  var userInfo: [String : Any]? {
    switch self {
    case .infoChanged(let user):
      return user == nil ? nil : [self.userInfoKey: user!]
    default:
      return nil
    }
  }
  
  func getObject(notification: Notification) -> UserNotification {
    switch self {
    case .infoChanged:
      let userInfo = notification.userInfo
      let user = userInfo?[self.userInfoKey] as! User?
      return .infoChanged(user)
    case .logout:
      return .logout
    }
  } 
}

Struct User {
  var name: String
  var email: String
}
```

- post:

```swift
UserNotification.infoChanged(user).post()
```

- observe:

```swift
notifyBus.observe(UserNotification.infoChanged(nil), handler: userInfoChangedNotify)
```

- handler:

```swift
func userInfoChangedNotify(notificationInfo: UserNotification) {
  guard case let .infoChanged(_user) = notificationInfo,
        let user = _user else { return }
	// use user...
}
```