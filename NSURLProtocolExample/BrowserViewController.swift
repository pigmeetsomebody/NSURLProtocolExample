//
//  BrowserViewController.swift
//  NSURLProtocolExample
//
//  Created by yanyuzhu on 2023/2/22.
//

import UIKit

class BrowserViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var webView: UIWebView!
    
    //MARK: IBAction
    @IBAction func onGoClicked(_ sender: Any) {
        if self.textField.isFirstResponder {
            self.textField.resignFirstResponder()
        }
        
        self.sendRequest()
    }
  

    //MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        self.sendRequest()
        
        return true
    }
    
    //MARK: Private
    
    func sendRequest() {
        if let text = self.textField.text {
            guard let url = URL(string:text) else {
                return
            }
            let request = URLRequest(url: url)
            self.webView.loadRequest(request)
        }
    }
}

