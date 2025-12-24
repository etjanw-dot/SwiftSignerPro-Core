//
//  MuffinStoreJailedApp.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 31/12/2024.
//

import SwiftUI

final class SharedData: ObservableObject {
    static let shared = SharedData()
    
    @Published var hasAppBeenServed: Bool = false
}

var pipe = Pipe()
var sema = DispatchSemaphore(value: 0)

@main
struct MuffinStoreJailedApp: App {
    init() {
        // Setup log stuff (redirect stdout)
        setvbuf(stdout, nil, _IONBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

extension String: @retroactive Error {}
