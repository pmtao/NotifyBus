//
//  NotifyBus.swift
//
//
//  Created by Meler Paine on 2021/3/5.
//

import Foundation

class NotifyHandler {
  var handlers: [() -> Void]
  
  init(_ handler: @escaping () -> Void) {
    self.handlers = [handler]
  }
  
  func addHanlder(_ handler: @escaping () -> Void) {
    handlers.append(handler)
  }
  
  func execute() {
    for handler in handlers {
      handler()
    }
    handlers = []
  }
}

/// send notification to obsevers
class NotifyBus {
  var notifyCenters: [NotificationCenter: [NSObjectProtocol]] = [:]
  var delayedHandlers = [Notification.Name: NotifyHandler]()
  
  deinit {
    for (center, tokens) in notifyCenters {
      for token in tokens {
        center.removeObserver(token)
      }
    }
  }
  
  func observe<T: BasicNotifyObject>(_ notifyObject: T,
                                     queue: OperationQueue? = nil,
                                     runAtOnce: Bool = true,
                                     handler: @escaping (T) -> Void) {
    let token = notifyObject.notifyCenter.addObserver(forName: notifyObject.name,
                                                      object: nil,
                                                      queue: queue) {_ in
      if runAtOnce {
        handler(notifyObject)
      } else {
        let handlerQueue = (queue != nil ? queue : OperationQueue.current) ?? OperationQueue()
        let delayedHandler = {
          handlerQueue.addOperation {
            handler(notifyObject)
          }
        }
        
        self.addDelayedHandler(of: notifyObject.name, delayedHandler: delayedHandler)
      }
    }
    self.addToken(in: notifyObject.notifyCenter, token: token)
  }
  
  func observe<T: InfomedNotifyObject>(_ notifyObject: T,
                                       queue: OperationQueue? = nil,
                                       runAtOnce: Bool = true,
                                       handler: @escaping (T) -> Void) {
    let token = notifyObject.notifyCenter.addObserver(forName: notifyObject.name,
                                                      object: nil,
                                                      queue: queue) {
      (_notification:Notification) in
      if runAtOnce {
        handler(notifyObject.getObject(notification: _notification))
      } else {
        let handlerQueue = (queue != nil ? queue : OperationQueue.current) ?? OperationQueue()
        let delayedHandler = {
          handlerQueue.addOperation {
            handler(notifyObject.getObject(notification: _notification))
          }
        }

        self.addDelayedHandler(of: notifyObject.name, delayedHandler: delayedHandler)
      }
    }
    self.addToken(in: notifyObject.notifyCenter, token: token)
  }
  
  private func addDelayedHandler(of name: Notification.Name, delayedHandler: @escaping () -> Void) {
    if self.delayedHandlers[name] != nil {
      self.delayedHandlers[name]!.addHanlder(delayedHandler)
    } else {
      let notifyHandler = NotifyHandler(delayedHandler)
      self.delayedHandlers[name] = notifyHandler
    }
  }
  
  private func addToken(in center: NotificationCenter, token: NSObjectProtocol) {
    if self.notifyCenters[center] != nil {
      self.notifyCenters[center]!.append(token)
    } else {
      self.notifyCenters[center] = [token]
    }
  }
  
  func executeHandler(of name: Notification.Name) {
    if let delayedHandlers = delayedHandlers[name] {
      delayedHandlers.execute()
    }
  }
  
}
