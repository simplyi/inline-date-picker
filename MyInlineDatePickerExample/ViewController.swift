//
//  ViewController.swift
//  MyInlineDatePickerExample
//
//  Created by Sergey Kargopolov on 2016-09-05.
//  Copyright © 2016 Sergey Kargopolov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let kPickerAnimationDuration = 0.40 // duration for the animation to slide the date picker into view
    let kDatePickerTag           = 99   // view tag identifiying the date picker view
    
    let kTitleKey = "title" // key for obtaining the data source item's title
    let kDateKey  = "date"  // key for obtaining the data source item's date value
    
    // keep track of which rows have date cells
    let kDateStartRow = 4
    let kDateEndRow   = 5
    
    let kDateCellID       = "dateCell";       // the cells with the start or end date
    let kDatePickerCellID = "datePickerCell"; // the cell containing the date picker
    let kOtherCellID      = "otherCell";      // the remaining cells at the end
    
    var dataArray: [[String: AnyObject]] = []
    var dateFormatter = NSDateFormatter()
    
    // keep track which indexPath points to the cell with UIDatePicker
    var datePickerIndexPath: NSIndexPath?
    
    var pickerCellRowHeight: CGFloat = 216
    
    @IBOutlet weak var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // setup our data source
        let itemOne = [kTitleKey : "Tap a cell to change its date:"]
        let itemTwo = [kTitleKey : "Start Date", kDateKey : NSDate()]
        let itemThree = [kTitleKey : "End Date", kDateKey : NSDate()]
        let itemFour = [kTitleKey : "(other item1)"]
        let itemFive = [kTitleKey : "(other item2)"]
        let itemSix = [kTitleKey : "(other item3)"]
        dataArray = [itemOne, itemFour, itemFive, itemSix, itemTwo, itemThree]
        
        dateFormatter.dateStyle = .MediumStyle // show short-style date format
        dateFormatter.timeStyle = .ShortStyle
        
        // if the locale changes while in the background, we need to be notified so we can update the date
        // format in the table view cells
        //
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.localeChanged(_:)), name: NSCurrentLocaleDidChangeNotification, object: nil)
        
    }
    
    // MARK: - Locale
    
    /*! Responds to region format or locale changes.
     */
    func localeChanged(notif: NSNotification) {
        // the user changed the locale (region format) in Settings, so we are notified here to
        // update the date format in the table view cells
        //
        myTableView.reloadData()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if hasInlineDatePicker() {
            // we have a date picker, so allow for it in the number of rows in this section
            return dataArray.count + 1;
        }
        
        return dataArray.count;
    }
    
 
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell: UITableViewCell?
        
        var cellID = kOtherCellID
        
        if indexPathHasPicker(indexPath) {
            // the indexPath is the one containing the inline date picker
            cellID = kDatePickerCellID     // the current/opened date picker cell
        } else if indexPathHasDate(indexPath) {
            // the indexPath is one that contains the date information
            cellID = kDateCellID       // the start/end date cells
        }
        
        cell = tableView.dequeueReusableCellWithIdentifier(cellID)
        
        if indexPath.row == 0 {
            // we decide here that first cell in the table is not selectable (it's just an indicator)
            cell?.selectionStyle = .None;
        }
        
        // if we have a date picker open whose cell is above the cell we want to update,
        // then we have one more cell than the model allows
        //
        var modelRow = indexPath.row
        if (datePickerIndexPath != nil && datePickerIndexPath?.row <= indexPath.row) {
            modelRow -= 1
        }
        
        let itemData = dataArray[modelRow]
        
        if cellID == kDateCellID {
            // we have either start or end date cells, populate their date field
            //
            cell?.textLabel?.text = itemData[kTitleKey] as? String
            cell?.detailTextLabel?.text = self.dateFormatter.stringFromDate(itemData[kDateKey] as! NSDate)
        } else if cellID == kOtherCellID {
            // this cell is a non-date cell, just assign it's text label
            //
            cell?.textLabel?.text = itemData[kTitleKey] as? String
        }
        
        return cell!

    }
 
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if cell?.reuseIdentifier == kDateCellID {
            displayInlineDatePickerForRowAtIndexPath(indexPath)
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
       return (indexPathHasPicker(indexPath) ? pickerCellRowHeight : tableView.rowHeight)
    }
    
    
    /*! Determines if the UITableViewController has a UIDatePicker in any of its cells.
     */
    func hasInlineDatePicker() -> Bool {
        return datePickerIndexPath != nil
    }
    
    /*! Determines if the given indexPath points to a cell that contains the UIDatePicker.
     
     @param indexPath The indexPath to check if it represents a cell with the UIDatePicker.
     */
    func indexPathHasPicker(indexPath: NSIndexPath) -> Bool {
        return hasInlineDatePicker() && datePickerIndexPath?.row == indexPath.row
    }
    
    /*! Determines if the given indexPath points to a cell that contains the start/end dates.
     
     @param indexPath The indexPath to check if it represents start/end date cell.
     */
    func indexPathHasDate(indexPath: NSIndexPath) -> Bool {
        var hasDate = false
        
        if (indexPath.row == kDateStartRow) || (indexPath.row == kDateEndRow || (hasInlineDatePicker() && (indexPath.row == kDateEndRow + 1))) {
            hasDate = true
        }
        return hasDate
    }

    
    /*! Reveals the date picker inline for the given indexPath, called by "didSelectRowAtIndexPath".
     
     @param indexPath The indexPath to reveal the UIDatePicker.
     */
    func displayInlineDatePickerForRowAtIndexPath(indexPath: NSIndexPath) {
        
        // display the date picker inline with the table content
        self.myTableView.beginUpdates()
        
        var before = false // indicates if the date picker is below "indexPath", help us determine which row to reveal
        if hasInlineDatePicker() {
            before = datePickerIndexPath?.row < indexPath.row
        }
        
        let sameCellClicked = (datePickerIndexPath?.row == indexPath.row + 1)
        
        // remove any date picker cell if it exists
        if self.hasInlineDatePicker() {
            self.myTableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: datePickerIndexPath!.row, inSection: 0)], withRowAnimation: .Fade)
            datePickerIndexPath = nil
        }
        
        if !sameCellClicked {
            // hide the old date picker and display the new one
            let rowToReveal = (before ? indexPath.row - 1 : indexPath.row)
            let indexPathToReveal = NSIndexPath(forRow: rowToReveal, inSection: 0)
            
            toggleDatePickerForSelectedIndexPath(indexPathToReveal)
            datePickerIndexPath = NSIndexPath(forRow: indexPathToReveal.row + 1, inSection: 0)
        }
        
        // always deselect the row containing the start or end date
        self.myTableView.deselectRowAtIndexPath(indexPath, animated:true)
        
        self.myTableView.endUpdates()
        
        // inform our date picker of the current date to match the current cell
        updateDatePicker()
    }
    
    /*! Adds or removes a UIDatePicker cell below the given indexPath.
     
     @param indexPath The indexPath to reveal the UIDatePicker.
     */
    func toggleDatePickerForSelectedIndexPath(indexPath: NSIndexPath) {
        
        self.myTableView.beginUpdates()
        
        let indexPaths = [NSIndexPath(forRow: indexPath.row + 1, inSection: 0)]
        
        // check if 'indexPath' has an attached date picker below it
        if hasPickerForIndexPath(indexPath) {
            // found a picker below it, so remove it
             self.myTableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
        } else {
            // didn't find a picker below it, so we should insert it
             self.myTableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
        }
         self.myTableView.endUpdates()
    }

    /*! Updates the UIDatePicker's value to match with the date of the cell above it.
     */
    func updateDatePicker() {
        if let indexPath = datePickerIndexPath {
            let associatedDatePickerCell = self.myTableView.cellForRowAtIndexPath(indexPath)
            if let targetedDatePicker = associatedDatePickerCell?.viewWithTag(kDatePickerTag) as! UIDatePicker? {
                let itemData = dataArray[self.datePickerIndexPath!.row - 1]
                targetedDatePicker.setDate(itemData[kDateKey] as! NSDate, animated: false)
            }
        }
    }
    
    
    /*! Determines if the given indexPath has a cell below it with a UIDatePicker.
     
     @param indexPath The indexPath to check if its cell has a UIDatePicker below it.
     */
    func hasPickerForIndexPath(indexPath: NSIndexPath) -> Bool {
        var hasDatePicker = false
        
        let targetedRow = indexPath.row + 1
        
        let checkDatePickerCell = self.myTableView.cellForRowAtIndexPath(NSIndexPath(forRow: targetedRow, inSection: 0))
        let checkDatePicker = checkDatePickerCell?.viewWithTag(kDatePickerTag)
        
        hasDatePicker = checkDatePicker != nil
        return hasDatePicker
    }


    @IBAction func dateAction(sender: UIDatePicker) {
       
        var targetedCellIndexPath: NSIndexPath?
        
        if self.hasInlineDatePicker() {
            // inline date picker: update the cell's date "above" the date picker cell
            //
            targetedCellIndexPath = NSIndexPath(forRow: datePickerIndexPath!.row - 1, inSection: 0)
        } else {
            // external date picker: update the current "selected" cell's date
            targetedCellIndexPath = self.myTableView.indexPathForSelectedRow!
        }
        
        let cell = self.myTableView.cellForRowAtIndexPath(targetedCellIndexPath!)
        let targetedDatePicker = sender
        
        // update our data model
        var itemData = dataArray[targetedCellIndexPath!.row]
        itemData[kDateKey] = targetedDatePicker.date
        dataArray[targetedCellIndexPath!.row] = itemData
        
        // update the cell's date string
        cell?.detailTextLabel?.text = dateFormatter.stringFromDate(targetedDatePicker.date)
        
    }
    
    @IBAction func doneButtonTapped(sender: AnyObject) {
        
        let targetedCellIndexPath: NSIndexPath =  NSIndexPath(forRow: 4, inSection: 0)
        let cell = myTableView.cellForRowAtIndexPath(targetedCellIndexPath)
        let cellLabelText  = cell?.textLabel!.text
        let dateString = cell?.detailTextLabel!.text
        
        print("\(cellLabelText!): \(dateString!)")
        
        let myDateFormatter = NSDateFormatter()
        myDateFormatter.dateFormat = "MM/dd/yy, h:mm a"
        myDateFormatter.timeZone = NSTimeZone.localTimeZone()
        
        let providedDate = myDateFormatter.dateFromString(dateString!)! as NSDate
        
        print(myDateFormatter.stringFromDate(providedDate))
    }
    

}

