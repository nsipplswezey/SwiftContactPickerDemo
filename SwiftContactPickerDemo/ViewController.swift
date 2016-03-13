//
//  ViewController.swift
//  SwiftContactPickerDemo
//
//  Created by Nicolas Sippl-Swezey on 3/8/16.
//  Copyright © 2016 Nicolas Sippl-Swezey. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

enum ActionType: Int {
    case PickContact = 0
    case CreateNewContact
    case DisplayContact
    case EditUnknownContact
}

//  Height for the Edit Unknown Contact row
let kUIEditUnknownContactRowHeight: CGFloat = 81.0

class ViewController: UITableViewController, CNContactPickerDelegate, CNContactViewControllerDelegate {
    
    private var store: CNContactStore!
    private var menuArray: NSMutableArray?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        store = CNContactStore()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkContactsAccess()
    }
    
    private func checkContactsAccess() {
        switch CNContactStore.authorizationStatusForEntityType(.Contacts){
            //Update our UI if the user has granted access to their Contacts
        case .Authorized :
            self.accessGrantedForContacts()
            
            //Prompt user for access for Contacts if there is no definitive anser
        case .NotDetermined :
            self.requestContactsAccess()
            
            // Display a message if the user has denied or restricted access to Contracts
            case .Denied,
                 .Restricted:
                let alert = UIAlertController(title: "Privacy Warning!",
                                              message: "Permission was no granted for Contacts.",
                                              preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            
        }
    }
    
    // This method is called to toggle contact access
    // This should be triggered everytime a component that needs access, doesn't have it.
    private func requestContactsAccess() {
        
        store.requestAccessForEntityType(.Contacts) {granted, error in
            if granted {
                dispatch_async(dispatch_get_main_queue()){
                    self.accessGrantedForContacts()
                    return
                }
            }
        }
    }
    
    // This method is called when the user has granted access ot their address book data.
    private func accessGrantedForContacts() {
        // Load data from the plist file
        //Some table view stuff... idk Let's do that next
        let plistPath = NSBundle.mainBundle().pathForResource("Menu", ofType:"plist")
        self.menuArray = NSMutableArray(contentsOfFile: plistPath!)
        self.tableView.reloadData()
    }
    
    
    //Table view methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.menuArray?.count ?? 0
    }
    
    // Customize number of rows in the table view
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Customize the appearance of table view cells.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let DefaultCellIdentifier = "DefaultCell"
        let SubtitleCellIdentifier = "SubtitleCell"
        var aCell: UITableViewCell?
        // Make the Display Picker and Create New Contact rows look like buttons
        if indexPath.section < 2 {
            aCell = tableView.dequeueReusableCellWithIdentifier(DefaultCellIdentifier)
            if aCell == nil {
                aCell = UITableViewCell(style: .Default, reuseIdentifier: DefaultCellIdentifier)
            }
            aCell!.textLabel?.textAlignment = .Center
        } else {
            aCell = tableView.dequeueReusableCellWithIdentifier(SubtitleCellIdentifier)
            if aCell == nil {
                aCell = UITableViewCell(style: .Default, reuseIdentifier: SubtitleCellIdentifier)
                aCell!.accessoryType = .DisclosureIndicator
                aCell!.detailTextLabel?.numberOfLines = 0
            }
            // Display descriptions for the Edit Unknown Contact and Display and Edit Contact rows
            aCell!.detailTextLabel?.text = self.menuArray![indexPath.section].valueForKey("description") as! String?
        }
        
        aCell!.textLabel?.text = self.menuArray![indexPath.section].valueForKey("title") as! String?
        return aCell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let actionType = ActionType(rawValue: indexPath.section) {
            switch actionType {
            case .PickContact:
                self.showContactPickerController()
            case .CreateNewContact:
                self.showContactPickerController()
            case .DisplayContact:
                self.showContactPickerController()
            case .EditUnknownContact:
                self.showContactPickerController()
            }
        }
    }
    
    //  TableViewDelegate method
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Change the height if Edit Unknown Contact is the row selected
        return (indexPath.section == ActionType.EditUnknownContact.rawValue) ? kUIEditUnknownContactRowHeight : tableView.rowHeight
    }
    
    
    private func showContactPickerController() {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        // Display only a person's phone, email, and birthdate
        let displayedItems = [CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactBirthdayKey]
        picker.displayedPropertyKeys = displayedItems
        
        // Show the picker
        self.presentViewController(picker, animated: true, completion: nil)
    
    }
    
    // The selected person and property from the people picker.
    func contactPicker(picker: CNContactPickerViewController, didSelectContactProperty contactProperty: CNContactProperty) {
        
        let contact = contactProperty.contact
        
        let contactPhone = contactProperty.value as! CNPhoneNumber
        let phoneNumber = contactPhone.stringValue
        
        let contactName = CNContactFormatter.stringFromContact(contact, style: .FullName) ?? ""
        
        let propertyName = CNContact.localizedStringForKey(contactProperty.key)
        
        let message = "Picked \(propertyName) for \(contactName) with number \(phoneNumber)"
        
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: "Picker Result",
                                           message: message,
                                           preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // Implement this if you want to do additional work when the picker is cancelled by the user.
    func contactPickerDidCancel(picker: CNContactPickerViewController) {
        picker.dismissViewControllerAnimated(true, completion: {})
    }
    
    // Dismisses the new-person view controller.
    func contactViewController(viewController: CNContactViewController, didCompleteWithContact contact: CNContact?) {
        //
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func contactViewController(viewController: CNContactViewController, shouldPerformDefaultActionForContactProperty property: CNContactProperty) -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}



