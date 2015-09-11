//
//  PreviousUserCollectionViewController.swift
//  MDM
//
//  Created by Jeffrey Macko on 08/09/15.
//  Copyright (c) 2015 PagesJaunes. All rights reserved.
//

import UIKit
import Parse

struct PFObjectFake {
  let userInfo : PJUser
  let borrowedDevice : BorrowedDevice
}

typealias sectionCoordinatorType = Array< String >
typealias borrowedDeviceListType = [String : Array< PFObjectFake > ]
typealias dataControllerTupleType = (sectionCoordinatorType, borrowedDeviceListType)

class PreviousUserViewController : UITableViewController {
  
  var sectionCoordinator : sectionCoordinatorType = []
  var borrowedDeviceList : borrowedDeviceListType = borrowedDeviceListType()
  
  
  func generateBorrowedDeviceListFromParse(borrowedDevices: [BorrowedDevice], users: [PJUser]) -> dataControllerTupleType? {
    var sectionCoordinator : sectionCoordinatorType = []
    var tmpBorrowedDeviceListType : borrowedDeviceListType = borrowedDeviceListType()
    var tmpObjtByDay : Array< PFObjectFake > = []
    
    
    // remplir le section coordinator avec une liste de jour
    for aBorrowedDevice in borrowedDevices {
      if let tmpUpdatedAt : NSDate = aBorrowedDevice.updatedAt {
        let actualUpdatedAt = self.formatFromDate(tmpUpdatedAt)
        if !sectionCoordinator.contains(actualUpdatedAt) {
          sectionCoordinator.append(actualUpdatedAt)
        }
      }
    }
    
    // pour chaque section remplir la liste de device emprunté
    for aSectionIdx in sectionCoordinator {
      
      // filtrer la liste de device utiliser ce jour precis
      let filteredBorrowedArray = borrowedDevices.filter({ (aDevice) -> Bool in
        let tmpAdevice: BorrowedDevice = aDevice
        if let tmpUpdatedAt : NSDate = tmpAdevice.updatedAt {
          let actualUpdatedAt = self.formatFromDate(tmpUpdatedAt)
          if actualUpdatedAt == aSectionIdx {
            return true
          }
        }
        return false
      })
      
      // recuperer la liste des utilisateus ayant emprunter un device ce jour et les coupler
      for aUser in users {
        for aBorrowedDevice in filteredBorrowedArray {
          if let userObjectId = aUser.objectId {
            if userObjectId == aBorrowedDevice.userId {
              tmpObjtByDay.append(PFObjectFake(userInfo: aUser, borrowedDevice: aBorrowedDevice))
            }
          }
        }
      }
      
      // remplir le tableau final
      tmpBorrowedDeviceListType[aSectionIdx] = tmpObjtByDay
    }
    
    return (sectionCoordinator, tmpBorrowedDeviceListType)
  }
  
  func formatFromDate(aDate : NSDate) -> String {
    let calendar = NSCalendar.currentCalendar()
    let components : NSDateComponents =  calendar.components([NSCalendarUnit.Day , NSCalendarUnit.Month , NSCalendarUnit.Year], fromDate: aDate)
    let sectionIdx : String = "\(components.year)/\(components.month)/\(components.day)"
    return sectionIdx
  }
  
  func refreshCells() {
    print(__LINE__)
    //    On remet tout a 0
    self.borrowedDeviceList = borrowedDeviceListType()
    self.sectionCoordinator = []
    
    print(__LINE__)
    // on charger les derniers BorrowedDevice
    let borrowedDeviceQuery = PFQuery(className: "BorrowedDevice")
    borrowedDeviceQuery.limit = 50
    print(__LINE__)
    borrowedDeviceQuery.findObjectsInBackgroundWithBlock {
      (borrowedDevices, error) -> Void in
      
      print(__LINE__)
      // si tout ce passe bien... on charger les user lié a ces devices
      if let cleanedBorrowedDevices = borrowedDevices as! [BorrowedDevice]? {
        
        print(__LINE__)
        // On cherche les UserID
        let unfilteredUserIDs : Array<String> = cleanedBorrowedDevices.map {
          return $0.userId()
        }
        let userIDs = Array(Set(unfilteredUserIDs))
        
        // On charge les user lié
        print(__LINE__)
        print(unfilteredUserIDs)
        print(userIDs)
        print(__LINE__)
        let pjUserQuery = PFQuery(className: "PJUser", predicate: NSPredicate(format: "objectId IN ", userIDs))
        print(__LINE__)
        pjUserQuery.findObjectsInBackgroundWithBlock {
          (pjUsersDirty, errorUsers) -> Void in
          print(__LINE__)
          if let pjUsers = pjUsersDirty {
            print(__LINE__)
            // on trie et on nettoie
            if let deviceList = self.generateBorrowedDeviceListFromParse(cleanedBorrowedDevices, users: pjUsers as! [PJUser]) {
              print(__LINE__)
              self.sectionCoordinator = deviceList.0
              self.borrowedDeviceList = deviceList.1
              print(__LINE__)
              self.tableView.reloadData()
            }
          }
        }
      }
    }
  }
  
  
  //  MARK
  
  override func viewWillAppear(animated: Bool) {
    self.refreshCells()
  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return self.sectionCoordinator.count
  }
  
  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if let aSectionDate : String = self.sectionCoordinator[section] {
      return aSectionDate
    }
    return ""
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let aSectionDate : String = self.sectionCoordinator[section] {
      if let aSection : Array<PFObjectFake> = self.borrowedDeviceList[aSectionDate] {
        return aSection.count
      }
    }
    return 0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier(PreviousUserCustomCell.cellIdentifier()) as! PreviousUserCustomCell
    
    if let aSectionDate : String = self.sectionCoordinator[indexPath.section] {
      if let aSection : Array<PFObjectFake> = self.borrowedDeviceList[aSectionDate] {
        if let tmpfakeobject : PFObjectFake = aSection[indexPath.row] {
          
          if let stateSwitch = tmpfakeobject.borrowedDevice["broken"] as! Bool? {
            cell.deviceStateSwitch.on = stateSwitch
          }
          if let mail = tmpfakeobject.userInfo["mail"] as! String? {
            cell.loginUserLabel.text = mail
          }
          if let aDate = tmpfakeobject.borrowedDevice["updatedAt"] as! NSDate? {
            cell.dateLabel.text = aDate.description
          }
          
        }
      }
    }
    return cell
  }
}


class PreviousUserCustomCell : UITableViewCell {
  
  @IBOutlet weak var deviceStateSwitch: UISwitch!
  @IBOutlet weak var loginUserLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  
  static func cellIdentifier() -> String {
    return "customCellPikaPika"
  }
  
  
}