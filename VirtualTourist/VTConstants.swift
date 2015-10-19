//
//  VTConstants.swift
//  VirtualTourist
//
//  Created by Vikas Varma on 10/14/15.
//  Copyright © 2015 Vikas Varma. All rights reserved.
//

import Foundation

extension VTClient{
    struct Constants {
        static let baseSecuredFlickrURL: String = "https://api.flickr.com/services/rest/"
        static let api_key: String = "1a1728a24c0a1d84926462e1814cf53d"
        //static let secret_key: String = "5ea98f4cf25afeab"
        static let extra: String = "url_m"
        static let nojsoncallback: String = "1"
        static let safe_search = "1"
        static let data_format = "json"
        static let lat_min = -90.0
        static let lat_max = 90.0
        static let lon_min = -180.0
        static let lon_max = 180.0
        static let max_pic_per_page = 21
        static let max_flickr_photos = 4000
    }
    
    // MARK: - Methods
    struct Methods {
        static let photoSearch = "flickr.photos.search"
    }
    struct Parameters {
        static let method = "method"
        static let apiKey = "api_key"
        static let safeSearch = "safe_search"
        static let dataFormat = "format"
        static let extra = "extras"
        static let longitude = "lon"
        static let latitude = "lat"
        static let jsonCallback = "nojsoncallback"
        static let perPage = "per_page"
        static let page = "page"
    }
    
    // MARK: - JSON response from API
    struct JSONResponse {
        static let photoList = "photos"
        static let photoKey = "photo"
        static let totalPhotosPerPage = "perpage"
        static let pages = "pages"
        static let page = "page"
    }

}
