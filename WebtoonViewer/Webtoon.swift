//
//  Webtoon.swift
//  WebtoonViewer
//
//  Created by Kim Yong Ha on 2021/12/12.
//

import Foundation
import UIKit

struct Webtoon {
    let data: Data
    let title: String
    let titleIdx: Int
    var details: String
    var seen: Int
}

struct Title {
    let url: String
    let title: String
    let titleIdx: Int
    let index: Int
}

struct Comment {
    let userName: String
    let contents: String
}
