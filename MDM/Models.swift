//
//  Models.swift
//  MDM
//
//  Created by Jeffrey Macko on 11/09/15.
//  Copyright © 2015 PagesJaunes. All rights reserved.
//

import Foundation
import Parse

class PJUser : PFObject {
  
  func login() -> String {
    return self.objectForKey("login") as! String
  }

  func mail() -> String {
    return self.objectForKey("mail") as! String
  }
  
}

class BorrowedDevice : PFObject {
  
  
  func model() -> String {
    return self.objectForKey("model") as! String
  }
  
  func type__() -> String {
    return self.objectForKey("type") as! String
  }

  func userId() -> String {
    return self.objectForKey("userId") as! String
  }
  
  func user() -> PJUser {
    let tUser : PJUser = self.objectForKey("userId")  as! PJUser
    if tUser.isDataAvailable() == false {
      tUser.fetch()
    }
    return tUser
  }

  func installationId() -> String {
    return self.objectForKey("installationId") as! String
  }

  func installation() -> PFInstallation {
    let installation : PFInstallation = self.objectForKey("installationId")  as! PFInstallation
    if installation.isDataAvailable() == false {
      installation.fetch()
    }
    return installation
  }
  
  func manufacturer() -> String {
    return self.objectForKey("manufacturer") as! String
  }

  func systemName() -> String {
    return self.objectForKey("systemName") as! String
  }

  func systemVersion() -> String {
    return self.objectForKey("systemVersion") as! String
  }

  func broken() -> Bool {
    return self.objectForKey("broken") as! Bool
  }
  
}
