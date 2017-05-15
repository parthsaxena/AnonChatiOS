//
//  SocketIOManager.swift
//  SocketChat
//
//  Created by Parth Saxena on 2/23/16.
//  Copyright © 2016 Parth Saxena. All rights reserved.
//

import UIKit
import SocketIO

class SocketIOManager: NSObject {
    static let sharedInstance = SocketIOManager()
    
    //var socket: SocketIOClient = SocketIOClient(socketURL: NSURL(string: "http://vantage.social:3000")! as URL)
    let socket = SocketIOClient(socketURL: URL(string: "http://vantage.social:3000")!, config: [.log(true), .forcePolling(true)])
    
    override init() {
        super.init()
    }
    
    func connectToServerWithNickname(_ nickname: String, completionHandler: @escaping (_ userList: [[String: AnyObject]]?) -> Void) {
        establishConnection()
        
        socket.emit("connectUser", nickname)
        
        socket.on("userList") { ( dataArray, ack) -> Void in
            completionHandler(dataArray[0] as! [[String: AnyObject]])
        }
        
        listenForOtherMessages()

    }
    
    fileprivate func listenForOtherMessages() {
        socket.on("userConnectUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userWasConnectedNotification"), object: dataArray[0] as! [String: AnyObject])
        }
        
        socket.on("userExitUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userWasDisconnectedNotification"), object: dataArray[0] as! String)
        }
        
        socket.on("userTypingUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userTypingNotification"), object: dataArray[0] as? [String: AnyObject])
        }
    }
    
    func sendMessage(message: String, withNickname nickname: String) {
        //socket.emit("chat message", nickname, message)
        let obj = [[message, nickname]]
        print("OBJ SEND: \(obj)")
        socket.emit("chat message", obj)
    }
    
    func sendStartTypingMessage(nickname: String) {
        socket.emit("startType", nickname)
    }
    
    func sendStopTypingMessage(nickname: String) {
        socket.emit("stopType", nickname)
    }
    
    func getChatMessage(completionHandler: @escaping (_ messageInfo: [String: AnyObject]) -> Void) {
        print("getChatMessage")
        socket.on("chat message") { (dataArray, socketAck) -> Void in
            print("RECEIVED MESSAGE")
            
            var messageDictionary = [String: AnyObject]()
            print("ad:\(dataArray)")
            messageDictionary["nickname"] = ((dataArray[0] as? [Any])?[0] as? [Any])?[1] as AnyObject
            messageDictionary["message"] = ((dataArray[0] as? [Any])?[0] as? [Any])?[0] as AnyObject
            //messageDictionary["date"] = dataArray[2] as! String as AnyObject
            
            completionHandler(messageDictionary)
        }
    }
    
    func exitChatWithNickname(nickname: String, completionHandler: () -> Void) {
        socket.emit("exitUser", nickname)
        completionHandler()
    }
    
    func establishConnection() {
        socket.connect()
        print("Establishing connection to server...");
    }
    
    
    func closeConnection() {
        socket.disconnect()
        print("Closing connection to server...");
    }
    
}
