//
//  NotifyBus.swift
//
//
//  Created by Meler Paine on 2021/3/5.
//

import Foundation

public enum HandleMode {
  case all
  case onlyFirst
  case onlyLast
  case first(Int)
  case last(Int)
}

class NotifyHandler {
  var handlers: [() -> Void]
  
  init(_ handler: @escaping () -> Void) {
    self.handlers = [handler]
  }
  
  func execute() {
    for handler in handlers {
      handler()
    }
    handlers = []
  }
}

/// send notification to obsevers
public class NotifyBus {
  var notifyCenters: [NotificationCenter: [NSObjectProtocol]] = [:]
  var delayedHandlers = [Notification.Name: NotifyHandler]()
  
  public init() {
    
  }
  
  deinit {
    for (center, tokens) in notifyCenters {
      for token in tokens {
        center.removeObserver(token)
      }
    }
  }
  
  public func observe<T: BasicNotifyObject>(_ notifyObject: T,
                                            queue: OperationQueue? = nil,
                                            executeLater: Bool = false,
                                            handleMode: HandleMode = .all,
                                            handler: @escaping (T) -> Void) {
    let token = notifyObject.notifyCenter.addObserver(forName: notifyObject.name,
                                                      object: nil,
                                                      queue: queue) {_ in
      if !executeLater {
        handler(notifyObject)
      } else {
        let handlerQueue = (queue != nil ? queue : OperationQueue.current) ?? OperationQueue()
        let delayedHandler = {
          handlerQueue.addOperation {
            handler(notifyObject)
          }
        }
        
        self.addDelayedHandler(of: notifyObject.name, handleMode: handleMode, delayedHandler: delayedHandler)
      }
    }
    self.addToken(in: notifyObject.notifyCenter, token: token)
  }
  
  public func observe<T: InfomedNotifyObject>(_ notifyObject: T,
                                              queue: OperationQueue? = nil,
                                              executeLater: Bool = false,
                                              handleMode: HandleMode = .all,
                                              handler: @escaping (T) -> Void) {
    let token = notifyObject.notifyCenter.addObserver(forName: notifyObject.name,
                                                      object: nil,
                                                      queue: queue) {
      (_notification:Notification) in
      if !executeLater {
        handler(notifyObject.getObject(notification: _notification))
      } else {
        let handlerQueue = (queue != nil ? queue : OperationQueue.current) ?? OperationQueue()
        let delayedHandler = {
          handlerQueue.addOperation {
            handler(notifyObject.getObject(notification: _notification))
          }
        }

        self.addDelayedHandler(of: notifyObject.name, handleMode: handleMode, delayedHandler: delayedHandler)
      }
    }
    self.addToken(in: notifyObject.notifyCenter, token: token)
  }
  
  private func addDelayedHandler(of name: Notification.Name,
                                 handleMode: HandleMode = .all,
                                 delayedHandler: @escaping () -> Void) {
    if self.delayedHandlers[name] != nil {
      let currentHandlerCount = self.delayedHandlers[name]!.handlers.count
      switch handleMode {
      case .all:
        self.delayedHandlers[name]!.handlers.append(delayedHandler)
      case .first(let count):
        guard count > 0 else { return }
        if currentHandlerCount >= count {
          self.delayedHandlers[name]!.handlers.removeSubrange(count...)
        } else {
          self.delayedHandlers[name]!.handlers.append(delayedHandler)
        }
      case .onlyFirst:
        if currentHandlerCount >= 1 {
          self.delayedHandlers[name]!.handlers.removeSubrange(1...)
        } else {
          self.delayedHandlers[name]!.handlers.append(delayedHandler)
        }
      case .last(let count):
        guard count > 0 else { return }
        if currentHandlerCount >= count {
          self.delayedHandlers[name]!.handlers.append(delayedHandler)
          self.delayedHandlers[name]!.handlers.removeFirst(currentHandlerCount - count + 1)
        } else {
          self.delayedHandlers[name]!.handlers.append(delayedHandler)
        }
      case .onlyLast:
        if currentHandlerCount >= 1 {
          self.delayedHandlers[name]!.handlers = [delayedHandler]
        } else {
          self.delayedHandlers[name]!.handlers.append(delayedHandler)
        }
      }
    } else {
      switch handleMode {
      case .all, .onlyFirst, .onlyLast:
        let notifyHandler = NotifyHandler(delayedHandler)
        self.delayedHandlers[name] = notifyHandler
      case .first(let count):
        if count > 0 {
          let notifyHandler = NotifyHandler(delayedHandler)
          self.delayedHandlers[name] = notifyHandler
        }
      case .last(let count):
        if count > 0 {
          let notifyHandler = NotifyHandler(delayedHandler)
          self.delayedHandlers[name] = notifyHandler
        }
      }
    }
  }
  
  private func addToken(in center: NotificationCenter, token: NSObjectProtocol) {
    if self.notifyCenters[center] != nil {
      self.notifyCenters[center]!.append(token)
    } else {
      self.notifyCenters[center] = [token]
    }
  }
  
  public func execute(_ name: Notification.Name) {
    if let delayedHandlers = delayedHandlers[name] {
      delayedHandlers.execute()
    }
  }
  
}
