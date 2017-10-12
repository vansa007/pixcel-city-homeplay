
//
//  MapViewController.swift
//  pixcel-city-homeplay
//
//  Created by Vansa Pha on 10/11/17.
//  Copyright © 2017 Vansa Pha. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import MapKit
import CoreLocation

class MapViewController: UIViewController, UIGestureRecognizerDelegate {

    //connection
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var swipeViewHieghtConstant: NSLayoutConstraint!
    @IBOutlet weak var heightCustomNavigationBar: NSLayoutConstraint!
    @IBOutlet weak var swipeView: UIView!
    
    //visual
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    var spinner: UIActivityIndicatorView?
    var processLb: UILabel?
    var screenSize = UIScreen.main.bounds
    typealias CompletionHandler = (_ Success: Bool) -> ()
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    var imageURLArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // init
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        let swipeViewRecognize = UISwipeGestureRecognizer(target: self, action: #selector(hideSwipeView))
        swipeViewRecognize.direction = .down
        swipeView.addGestureRecognizer(swipeViewRecognize)
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        registerForPreviewing(with: self, sourceView: collectionView!)
        swipeView.addSubview(collectionView!)
    }

    @IBAction func centerMapBtnWasPressed(_ sender: UIButton) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
    @objc func dropPin(_ sender: UITapGestureRecognizer) {
        removeNavigationView()
        removePin()
        cancelAllSessions()
        imageArray = []
        imageURLArray = []
        collectionView?.reloadData()
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        retrieveURLs(forAnnotation: annotation) { (status) in
            if status {
                self.retrieveImages(handler: { (status) in
                    if status {
                        //hide spinner, label, reload collection
                        self.removeSpinner()
                        self.removeProgressLb()
                        if self.imageURLArray.count <= 0 {
                            self.processLb?.text = "No photo(s) availble in this location."
                            self.addProgressLb()
                        }
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
        showSwipeView()
//        setRegionBySuccess(mv: mapView, coordinateRegion: coordinateRegion, animated: true) { (success) in
//            if success {
//                self.showSwipeView()
//            }else {
//                return
//            }
//        }
    }
    
    func setRegionBySuccess(mv: MKMapView, coordinateRegion: MKCoordinateRegion, animated: Bool, completion: @escaping CompletionHandler) {
        mv.setRegion(coordinateRegion, animated: animated)
        completion(true)
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func showSwipeView() {
        swipeViewHieghtConstant.constant = 300.0
        UIView.animate(withDuration: 0.35) {
            self.view.layoutIfNeeded()
            self.removeSpinner()
            self.removeProgressLb()
            self.addSpinner()
            self.addProgressLb()
        }
    }
    
    func addProgressLb() {
        processLb = UILabel()
        processLb?.frame = CGRect(x: screenSize.width/2 - 120, y: 175, width: 240, height: 40)
        processLb?.font = UIFont(name: "Avenir Next", size: 18)
        processLb?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        processLb?.textAlignment = .center
        collectionView?.addSubview(processLb!)
    }
    
    func removeProgressLb() {
        if processLb != nil {
            processLb?.removeFromSuperview()
        }
    }
    
    @objc func hideSwipeView() {
        cancelAllSessions()
        swipeViewHieghtConstant.constant = 0.0
        UIView.animate(withDuration: 0.35) {
            self.showNavigationView()
            self.view.layoutIfNeeded()
        }
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        //doubleTap.numberOfTapsRequired = 3
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: screenSize.width/2 - (spinner?.frame.width)!/2, y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func showNavigationView() {
        self.heightCustomNavigationBar.constant = 70.0
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    func removeNavigationView() {
        self.heightCustomNavigationBar.constant = 0.0
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    func retrieveURLs(forAnnotation annotation: DroppablePin, handler: @escaping CompletionHandler) {
        imageURLArray = []
        Alamofire.request(flickrURL(forApiKey: FLICKR_API_KEY, withAnnotation: annotation, andNumberOfPhotos: 30)).responseJSON { (response) in
            if response.result.error == nil {
                guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
                let photos = json["photos"] as! Dictionary<String, AnyObject>
                let photo = photos["photo"] as! [Dictionary<String, AnyObject>]
                for eachPhoto in photo {
                    let postUrl = "https://farm\(eachPhoto["farm"]!).staticflickr.com/\(eachPhoto["server"]!)/\(eachPhoto["id"]!)_\(eachPhoto["secret"]!)_h_d.jpg"
                    self.imageURLArray.append(postUrl)
                }
                handler(true)
            }
        }
    }
    
    func retrieveImages(handler: @escaping CompletionHandler) {
        imageArray = []
        for url in imageURLArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                if response.result.error == nil {
                    guard let image = response.result.value else { return }
                    self.imageArray.append(image)
                    self.processLb?.text = "\(self.imageArray.count)/30 images downloaded"
                    if self.imageArray.count == self.imageURLArray.count {
                        handler(true)
                    }
                }
            })
        }
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
        }
    }
    
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.938924253, green: 0.7100304961, blue: 0.1893346906, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }else {
            return
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        cell.addSubview(imageView)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVc = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopViewController else { return }
        popVc.initData(forImage: imageArray[indexPath.row])
        present(popVc, animated: true, completion: nil)
    }
}

extension MapViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
        guard let popVc = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopViewController else { return nil}
        popVc.initData(forImage: imageArray[indexPath.row])
        previewingContext.sourceRect = cell.contentView.frame
        return popVc
    }
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
























