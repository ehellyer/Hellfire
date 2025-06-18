//
//  Company.swift
//  Hellfire
//
//  Created by Ed Hellyer on 9/2/19.
//  Copyright © 2019 Ed Hellyer. All rights reserved.
//

import Foundation
import Hellfire

struct Company: JSONSerializable {
    var name: String
    var tagLine: String?
    var employees: [Person]
}
