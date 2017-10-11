//
//  DroppablePin.swift
//  pixcel-city-homeplay
//
//  Created by Vansa Pha on 10/11/17.
//  Copyright © 2017 Vansa Pha. All rights reserved.
//

import Foundation
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var identifier: String
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}
