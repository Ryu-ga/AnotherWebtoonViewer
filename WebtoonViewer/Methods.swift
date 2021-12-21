//
//  Methods.swift
//  WebtoonViewer
//
//  Created by Kim Yong Ha on 2021/12/12.
//

import Foundation
import SwiftSoup

func requestList(title: Int,num: Int, completionHandler: @escaping (Bool, Data) -> Void) {
    guard let url = URL(string: "https://comic.naver.com/webtoon/detail.nhn?titleId=\(title)&no=\(num)") else {
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("https://comic.naver.com/webtoon/detail.nhn?titleId=\(title)&no=\(num)", forHTTPHeaderField: "Referer")
    
    URLSession.shared.dataTask(with: request) { (data, response, error) in
        guard error == nil else {
            print("error")
            completionHandler(false, Data())
            return
        }
        guard let data = data else {
            print("error data")
            completionHandler(false, Data())
            return
        }
        guard let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode else {
            print("error response")
            completionHandler(true, data)
            return
        }
        
        completionHandler(true, data)
    }.resume()
}

func requestImage(uri: String, completionHandler: @escaping (Bool, Data) -> Void) async {
    guard let url = URL(string: uri) else {
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
    request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("keep-alive", forHTTPHeaderField: "Connection")
    request.addValue(uri, forHTTPHeaderField: "Referer")
    
    URLSession.shared.dataTask(with: request) { (data, response, error) in
        guard error == nil else {
            print("error")
            completionHandler(false, Data())
            return
        }
        guard let data = data else {
            print("error data")
            completionHandler(false, Data())
            return
        }
        guard let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode else {
            print("error response")
            completionHandler(false, Data())
            return
        }
        
        completionHandler(true, data)
    }.resume()
}

func requestTitles(title: Int, page: Int, completionHandler: @escaping (Bool, Data) -> Void) {
    let uri = "https://comic.naver.com/webtoon/list?titleId=\(title)&page=\(page)"
    guard let url = URL(string: uri) else {
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
    request.addValue(uri, forHTTPHeaderField: "Referer")
    
    URLSession.shared.dataTask(with: request) { (data, response, error) in
        guard error == nil else {
            print("error")
            completionHandler(false, Data())
            return
        }
        guard let data = data else {
            print("error data")
            completionHandler(false, Data())
            return
        }
        guard let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode else {
            print("error response")
            completionHandler(true, data)
            return
        }
        
        completionHandler(true, data)
    }.resume()
}

extension String{
    func getArrayAfterRegex(regex: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

func requestComment(title: Int, no: Int, completionHandler: @escaping (Bool, Data) -> Void) {
    let string2 = "https://apis.naver.com/commentBox/cbox/web_naver_list_jsonp.json?ticket=comic&templateId=webtoon&pool=cbox3&lang=ko&country=KR&objectId=\(title)_\(no)&categoryId=&pageSize=150&indexSize=10&groupId=&listType=OBJECT&pageType=default&page=1&initialize=true&userType=&useAltSort=true&replyPageSize=10"
    guard let url = URL(string: string2) else {
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("*/*", forHTTPHeaderField: "Accept")
    request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("same-site", forHTTPHeaderField: "Sec-Fetch-Site")
    request.addValue("no-cors", forHTTPHeaderField: "Sec-Fetch-Mode")
    request.addValue("script", forHTTPHeaderField: "Sec-Fetch-Dest")
    request.addValue("https://comic.naver.com/comment/comment?titleId=\(title)&no=\(no)", forHTTPHeaderField: "Referer")
    
    URLSession.shared.dataTask(with: request) { (data, response, error) in
        guard error == nil else {
            print("error")
            completionHandler(false, Data())
            return
        }
        guard let data = data else {
            print("error data")
            completionHandler(false, Data())
            return
        }
        guard let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode else {
            print("error response")
            completionHandler(true, data)
            return
        }
        
        completionHandler(true, data)
    }.resume()
}
