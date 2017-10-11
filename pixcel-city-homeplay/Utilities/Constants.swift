//
//  Constants.swift
//  pixcel-city-homeplay
//
//  Created by Vansa Pha on 10/11/17.
//  Copyright © 2017 Vansa Pha. All rights reserved.
//

import Foundation

let FLICKR_API_KEY = "f380a0fabe072951e0a9764270cae67c"

func flickrURL(forApiKey: String, withAnnotation: DroppablePin, andNumberOfPhotos number: Int) -> String {
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(FLICKR_API_KEY)&lat=\(withAnnotation.coordinate.latitude)&lon=\(withAnnotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
}
