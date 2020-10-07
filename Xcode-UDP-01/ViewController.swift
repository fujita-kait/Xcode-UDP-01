//
//  ViewController.swift
//  Xcode-UDP-01
//
//  Created by Hiro Fujita on 2020/10/07.
//
//  This program is a sample of UDP send/receive string data with NETWORK framework
//
//  This program listen UDP connection on port 3610 and print received data to console.
//  To try this program, send data from another PC/Mac with
//  > nc -u 192.168.1.7 3610 (C/R)  // modify the IP according to the environment
//      ABC (C/R)
//  Then, the message ABC will be desplayed on the console.
//
//  SEND button sends a string message to a PC/MAC
//  Modify IP address in "private func startConnection()"
//  To verify this, do the following on the PC/MAC before click SEND button
//  > nc -lu 3610

import UIKit
import Foundation
import Network

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        receiveUDP()
        startConnection()
    }

    @IBAction func sendUDP(_ sender: UIButton) {
        print("SEND button is clicked")
        send(message: "ECHONET Lite\n")
    }
    
    //    receive
    func receiveUDP() {
        let myQueue  = DispatchQueue.global()
        do {
            let listener = try NWListener(using: .udp, on: 3610)
            listener.newConnectionHandler = { (newConnection) in
                // Handle inbound connections
                print("connection OK")
                newConnection.start(queue: myQueue)
                self.receive(on: newConnection)
            }

            listener.stateUpdateHandler = { (newState) in
                switch newState {
                    case .setup:
                        print("listner state is setup")
                    case .waiting:
                        print("listner state is waiting")
                    case .ready:
                        print("listner state is ready")
                    case .failed:
                        print("listner state is failed")
                    case .cancelled:
                        print("listner state is cancelled")
                    default:
                        print("listner state is error!")
                }
            }
            
            print("listener start")
            listener.start(queue: myQueue)
        }
        catch {
            print("Error", error)
        }
    }
    
    private func receive(on connection: NWConnection) {
        connection.receiveMessage { (data: Data?, contentContext: NWConnection.ContentContext?, aBool: Bool, error: NWError?) in
            print(data!)
            if let data = data, let message = String(data: data, encoding: .utf8) {
                print("Received Message: \(message)")
            }

            if let error = error {
                print(error)
            } else {
                // エラーがなければこのメソッドを再帰的に呼ぶ
                self.receive(on: connection)
            }
        }
    }
    
    private var connection: NWConnection!
    private func startConnection() {
        let udpParams = NWParameters.udp
        // 送信先エンドポイント
        let endpoint = NWEndpoint.hostPort(host: "192.168.1.14", port: 3610)
        connection = NWConnection(to: endpoint, using: udpParams)
        
        connection.stateUpdateHandler = { (state: NWConnection.State) in
            guard state != .ready else { return }
            print("connection is ready")
        }
        
        // コネクション開始
        let connectionQueue = DispatchQueue(label: "com.shu223.NetworkPlayground.sender")
        connection.start(queue: connectionQueue)
    }

    func send(message: String) {
        let data = message.data(using: .utf8)
        
        // 送信完了時の処理
        let completion = NWConnection.SendCompletion.contentProcessed { (error: NWError?) in
            print("送信完了")
        }

        // 送信
        connection.send(content: data, completion: completion)
    }

}
