//
//  StringExtension.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/2/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

extension String {
    var escaped: String {
       return CFURLCreateStringByAddingPercentEscapes(nil, self, nil, "!*'();:@&=+$,/?%#[]\" ", kCFStringEncodingASCII) as String
    }
}