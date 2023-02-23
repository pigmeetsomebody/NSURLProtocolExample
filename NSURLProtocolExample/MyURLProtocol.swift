//
//  MyURLProtocol.swift
//  NSURLProtocolExample
//
//  Created by yanyuzhu on 2023/2/22.
//

import Foundation
import UIKit
import CoreData

var requestCount: Int = 0

class MyURLProtocol: URLProtocol {
    
    private var dataTask: URLSessionDataTask?
    
    private lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }()
    
    override class func canInit(with request: URLRequest) -> Bool {
        requestCount += 1
        print("Request #\(requestCount): URL = \(String(describing: request.url?.absoluteString))")
        return true
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to: b)
    }
    override func startLoading() {
       cancel()
        let possibleCachedResponse = self.cachedResponseForCurrentRequest()
        if let cachedResponse = possibleCachedResponse {
            print("Serving response from cache")
            let data = cachedResponse.value(forKey: "data") as? Data ?? Data()
            let mimeType = cachedResponse.value(forKey: "mimeType") as? String ?? ""
            let encoding = cachedResponse.value(forKey: "encoding") as? String ?? ""
            let response = URLResponse(url: self.request.url!, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: encoding)
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
            
        } else {
            dataTask = session.dataTask(with: request)
            dataTask?.resume()
        }
    }
    override func stopLoading() {
        cancel()
    }
    func cancel() {
        if dataTask != nil {
            dataTask?.cancel()
        }
        dataTask = nil
    }
    
    var mutableData: NSMutableData?
    var response: URLResponse?
    func saveCachedResponseData() {
        guard let mutableData = mutableData, let response = response else {
            return
        }
        print("Saving cahced response")
        
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            print("AppDelegate is nil")
            return
        }
        let context = delegate.managedObjectContext!
        let cachedResponse = NSEntityDescription.insertNewObject(forEntityName: "CachedURLResponse", into: context) as NSManagedObject
        cachedResponse.setValue(mutableData, forKey: "data")
        cachedResponse.setValue(request.url?.absoluteString, forKey: "url")
        cachedResponse.setValue(Date(), forKey: "timestamp")
        cachedResponse.setValue(response.mimeType, forKey: "mimeType")
        cachedResponse.setValue(response.textEncodingName, forKey: "encoding")
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    func cachedResponseForCurrentRequest() -> NSManagedObject? {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.managedObjectContext!
        let entity = NSEntityDescription.entity(forEntityName: "CachedURLResponse", in: context)
        let fetchRequest = NSFetchRequest<NSManagedObject>()
        fetchRequest.entity = entity
        let predicate = NSPredicate(format: "url == %@", self.request.url!.absoluteString)
        fetchRequest.predicate = predicate
        if #available(iOS 11.0, *) {
            do {
                let possibleResult = try context.fetch(fetchRequest)
                guard possibleResult.count > 0 else {
                    return nil
                }
                return possibleResult[0]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

extension MyURLProtocol: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.response = response
        self.mutableData = NSMutableData()
        completionHandler(.allow)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.client?.urlProtocol(self, didLoad: data)
        self.mutableData?.append(data)
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            self.client?.urlProtocolDidFinishLoading(self)
            
            self.saveCachedResponseData()
            return
        }
        self.client?.urlProtocol(self, didFailWithError: error)
    }
}
