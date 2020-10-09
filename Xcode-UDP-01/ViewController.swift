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
//  Destination IPをECHONET Liteのマルチキャストアドレス 224.0.23.0 を指定した場合
//  netcatでは受信確認できない。Wiresharkでは確認できる。udp.port==3610でフィルターをかけること。

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
        // multicasting: START
        guard let multicast = try? NWMulticastGroup(for:
            [ .hostPort(host: "224.0.23.0", port: 3610) ])
            else { fatalError() }
        let group = NWConnectionGroup(with: multicast, using: .udp)
        group.setReceiveHandler(maximumMessageSize: 16384, rejectOversizedMessages: true) { (message, content, isComplete) in
            print("Received message from \(String(describing: message.remoteEndpoint))")
            if let content = content, let message = String(data: content, encoding: .utf8) {
                print("Received Message: \(message)")
            }
        }
        group.stateUpdateHandler = { (newState) in
            print("Group entered state \(String(describing: newState))")
        }
        group.start(queue: .main)
        // multicasting: END

        // unicasting: START
        do {
//            let listener = try NWListener(using: .udp, on: 3610)
            let listener = try NWListener(using: .udp, on: 3611)
            listener.newConnectionHandler = { (newConnection) in
                // Handle inbound connections
                print("connection OK")
                newConnection.start(queue: .main)
                self.receive(on: newConnection)
            }

            listener.stateUpdateHandler = { (newState) in
                print("listener entered state \(String(describing: newState))")
            }
            print("listener start")
            listener.start(queue: .main)
        }
        catch {
            print("Error", error)
        }
        // unicasting: END

    }
    
    private func receive(on connection: NWConnection) {
        connection.receiveMessage { (data: Data?, contentContext: NWConnection.ContentContext?, aBool: Bool, error: NWError?) in
            print("Received message from \(String(describing: connection.endpoint))")
            if let data = data, let message = String(data: data, encoding: .utf8) {
                print("Received Message(unicast): \(message)")
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
//        let endpoint = NWEndpoint.hostPort(host: "224.0.23.0", port: 3610)
        connection = NWConnection(to: endpoint, using: udpParams)
        
        connection.stateUpdateHandler = { (state: NWConnection.State) in
            guard state != .ready else { return }
            print("connection is ready")
        }
        
        // コネクション開始
        let myQueue  = DispatchQueue.global()
        connection.start(queue: myQueue)
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
