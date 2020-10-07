//
//  ViewController.swift
//  Xcode-UDP-01
//
//  Created by Hiro Fujita on 2020/10/07.
//

import UIKit
import Foundation
import Network

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        receiveUDP()
    }

    //    receive
    func receiveUDP() {
        let myQueue  = DispatchQueue.global()
        do {
            let listener = try NWListener(using: .udp, on: 3610)
            listener.newConnectionHandler = { (newConnection) in
                // Handle inbound connections
                print("connection OK", newConnection)
                newConnection.start(queue: myQueue)
                self.receive(on: newConnection)
            }

            listener.stateUpdateHandler = { (newState) in
                switch newState {
                    case .setup:
                        print("setup")
                    case .waiting:
                        print("waiting")
                    case .ready:
                        print("ready")
                    case .failed:
                        print("failed")
                    case .cancelled:
                        print("cancelled")
                    default:
                        print("error!")
                }
            }
            
            print("listener start")
            listener.start(queue: myQueue)
        }
        catch {
            print("Error", error)
        }
        print("end")
    }
    
    private func receive(on connection: NWConnection) {
        print("receive on connection: \(connection)")
        connection.receiveMessage { (data: Data?, contentContext: NWConnection.ContentContext?, aBool: Bool, error: NWError?) in
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

}
