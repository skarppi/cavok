//
//  ConfigDrawerController.swift
//  CAVOK
//
//  Created by Juho Kolehmainen on 01.06.2017.
//  Copyright © 2017 Juho Kolehmainen. All rights reserved.
//

import Foundation
import Pulley
import os.log

class ConfigDrawerController: UIViewController {
    
    //MARK: Properties
    
    @IBOutlet weak var radius: UILabel!
    
    @IBOutlet weak var status: UILabel!
    
    @IBOutlet weak var stepper: UIStepper!
    
    @IBOutlet weak var linksTable: UITableView!
    
    @IBOutlet var gripperTopConstraint: NSLayoutConstraint!
    
    fileprivate var links: [Link] = []
    
    private var region: WeatherRegion!

    private var resized: (WeatherRegion) -> Void = { (r: WeatherRegion) -> Void in
    }
    
    private var closed: (WeatherRegion) -> Void = { (r: WeatherRegion) -> Void in
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stepper.value = Double(region.radius)
        
        radiusChanged(stepper)
        
        links = Links.load()
        
        linksTable.isEditing = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        drawerDisplayModeDidChange(drawer: pulley)
    }
    
    func setup(region: WeatherRegion, closed: @escaping (WeatherRegion) -> Void, resized: @escaping (WeatherRegion) -> Void) {
        self.region = region
        self.closed = closed
        self.resized = resized
    }
    
    func status(text: String, color: UIColor = UIColor.blue) {
        status.text = text
        status.textColor = color
    }
    
    @IBAction func radiusChanged(_ stepper: UIStepper) {
        region.radius = Float(stepper.value)
        
        radius.text = "\(region.radius) km"
        
        if stepper.value >= 1000 {
            stepper.stepValue = 200
        } else {
            stepper.stepValue = 100
        }

        resized(region)
    }
    
    @IBAction func center(_ button: UIButton) {
        if let location = LastLocation.load() {
            region.center = location
            resized(region)
        } else {
            status(text: "Unknown location", color: ColorRamp.color(for: .IFR, alpha: 1))
        }
    }
    
    @IBAction func close(_ button: UIButton) {
        closed(region)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "AddLink":
            os_log("Adding a new link.", log: OSLog.default, type: .debug)
            
        case "EditLink":
            
            guard let navigationController = segue.destination as? UINavigationController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let linkEditController = navigationController.topViewController as? LinkEditController else {
                fatalError("Unexpected destination: \(String(describing: navigationController.topViewController))")
            }
            
            guard let selectedCell = sender as? LinkTableViewCell else {
                fatalError("Unexpected sender: \(sender ?? "")")
            }
            
            guard let indexPath = linksTable.indexPath(for: selectedCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            linkEditController.link = links[indexPath.row]
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier ?? "")")
        }
    }

    //MARK: Actions
    
    @IBAction func unwindToLinkList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? LinkEditController, let link = sourceViewController.link {
            
            if let selectedIndexPath = linksTable.indexPathForSelectedRow {
                // update
                links[selectedIndexPath.row] = link
                linksTable.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                // create new
                let newIndexPath = IndexPath(row: links.count, section: 0)
                
                links.append(link)
                linksTable.insertRows(at: [newIndexPath], with: .automatic)
            }
            
            if !Links.save(links) {
                Messages.show(error: "Links cannot be saved")
            }

            pulley.setNeedsSupportedDrawerPositionsUpdate()
            pulley.setDrawerPosition(position: .partiallyRevealed, animated: false)
        }
    }
    
    func drawerDisplayModeDidChange(drawer: PulleyViewController) {
        gripperTopConstraint.isActive = drawer.currentDisplayMode == .bottomDrawer
    }
}

extension ConfigDrawerController: UITableViewDataSource, UITableViewDelegate  {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return links.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "LinkTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? LinkTableViewCell  else {
            fatalError("The dequeued cell is not an instance of \(cellIdentifier).")
        }
        
        let link = links[indexPath.row]
        
        cell.titleLabel.text = link.title
        cell.urlLabel.text = link.url
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            links.remove(at: indexPath.row)
            if Links.save(links) {
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                pulley.setDrawerPosition(position: .collapsed, animated: false)
                pulley.setNeedsSupportedDrawerPositionsUpdate()
                pulley.setDrawerPosition(position: .partiallyRevealed, animated: false)
            } else {
                Messages.show(error: "Links cannot be saved")
            }
            
        }
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 40
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = links[sourceIndexPath.row]
        links.remove(at: sourceIndexPath.row)
        links.insert(movedObject, at: destinationIndexPath.row)
    }
}

extension ConfigDrawerController: PulleyDrawerViewControllerDelegate {
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed, .collapsed, .partiallyRevealed]
    }
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 170 + (pulley.displayMode == .bottomDrawer ? bottomSafeArea : 5)
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let tablePositionY = linksTable.frame.origin.y + (linksTable.superview?.frame.origin.y ?? 0)
        
        let currentContentHeight = tablePositionY + linksTable.contentSize.height
        
        let maxAvailableHeight = UIApplication.shared.keyWindow!.frame.height
        if pulley.displayMode == .bottomDrawer {
            return min(maxAvailableHeight - bottomSafeArea - pulley.topInset, currentContentHeight + bottomSafeArea)
        } else {
            return min(maxAvailableHeight - pulley.topInset * 2, currentContentHeight)
        }        
    }
}
