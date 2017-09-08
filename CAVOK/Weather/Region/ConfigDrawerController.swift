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
            
            Links.save(links)
        }
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
}

extension ConfigDrawerController: PulleyDrawerViewControllerDelegate {
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed, .partiallyRevealed, .open]
    }
    
    func collapsedDrawerHeight() -> CGFloat {
        return 75
    }
    
    func partialRevealDrawerHeight() -> CGFloat {
        return 190
    }
}
