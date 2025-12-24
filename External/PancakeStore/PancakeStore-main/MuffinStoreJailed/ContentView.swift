//
//  ContentView.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 26/12/2024.
//

import SwiftUI

struct ContentView: View {
    @State var ipaTool: IPATool?
    
    @State var appleId: String = ""
    @State var password: String = ""
    @State var code: String = ""
    
    @State var isAuthenticated: Bool = false
    @State var isDowngrading: Bool = false
    
    @State var appLink: String = ""
    
    @State var hasSent2FACode: Bool = false
    @State var showLogs: Bool = false
    @State var showPassword: Bool = false
    
    @ObservedObject var sharedData = SharedData.shared
    
    var body: some View {
        NavigationStack {
            List {
                if showLogs {
                    Section(header: LabelStyle(text: "Logs", icon: "terminal")) {
                        GlassyTerminal {
                            LogView()
                        }
                    }
                }
                // login page view
                if !isAuthenticated {
                    Section(header: HeaderStyle(text: "Apple ID", icon: "icloud"), footer: Text("Created by [mineek](https://github.com/mineek/MuffinStoreJailed-Public), UI modifications done by lunginspector for [jailbreak.party](https://github.com/jailbreakdotparty). Use this tool at your own risk! App data may be lost, and other damage could occur.")) {
                        VStack {
                            TextField("Email Address", text: $appleId)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textFieldStyle(GlassyTextFieldStyle(isDisabled: hasSent2FACode))
                            HStack {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .textFieldStyle(GlassyTextFieldStyle(isDisabled: hasSent2FACode))
                                } else {
                                    SecureField("Password", text: $password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .textFieldStyle(GlassyTextFieldStyle(isDisabled: hasSent2FACode))
                                }
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye" : "eye.slash")
                                        .frame(width: 20, height: 22)
                                }
                                .buttonStyle(GlassyButtonStyle())
                                .frame(width: 50)
                            }
                        }
                    }
                    if hasSent2FACode {
                        Section(header: HeaderStyle(text: "2FA Code", icon: "key"), footer: Text("If you did not receive a notification on any of the devices that are trusted to receive verification codes, type in six random numbers into the field. Trust me.")) {
                            TextField("2FA Code", text: $code)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textFieldStyle(GlassyTextFieldStyle())
                        }
                    }
                } else {
                    // downgrading application view
                    if isDowngrading {
                        Section {
                            HStack(spacing: 12) {
                                ProgressView()
                                VStack(alignment: .leading) {
                                    Text("Downgrading Application...")
                                        .fontWeight(.medium)
                                    Text("This may take a while, and PancakeStore will likely hang for a bit.")
                                        .font(.footnote)
                                }
                            }
                        }
                    } else {
                        // input the stupid app link or whatever view
                        Section(header: HeaderStyle(text: "Downgrade App", icon: "arrow.down.app"), footer: Text("Created by [mineek](https://github.com/mineek/MuffinStoreJailed-Public), UI modifications done by lunginspector for [jailbreak.party](https://github.com/jailbreakdotparty). Use this tool at your own risk! App data may be lost, and other damage could occur.")) {
                            HStack {
                                TextField("Link to App Store App", text: $appLink)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .textFieldStyle(GlassyTextFieldStyle())
                                Button(action: {
                                    Haptic.shared.play(.soft)
                                    appLink = UIPasteboard.general.string ?? ""
                                }) {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(GlassyButtonStyle())
                                .frame(width: 50)
                            }
                        }
                    }
                }
            }
            .navigationTitle("PancakeStore")
            .safeAreaInset(edge: .bottom) {
                VStack {
                    // i hate this.
                    if !isAuthenticated {
                        Button(action: {
                            Haptic.shared.play(.soft)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                if appleId.isEmpty || password.isEmpty {
                                    Alertinator.shared.alert(title: "No Apple ID details were input!", body: "Please type your Apple ID email address & password, then try again.")
                                }
                                if code.isEmpty {
                                    ipaTool = IPATool(appleId: appleId, password: password)
                                    ipaTool?.authenticate(requestCode: true)
                                    hasSent2FACode = true
                                    return
                                }
                                let finalPassword = password + code
                                ipaTool = IPATool(appleId: appleId, password: finalPassword)
                                let ret = ipaTool?.authenticate()
                                isAuthenticated = ret ?? false
                            }
                        }) {
                            if hasSent2FACode {
                                LabelStyle(text: "Log In", icon: "arrow.right")
                            } else {
                                LabelStyle(text: "Send 2FA Code", icon: "key")
                            }
                        }
                        .buttonStyle(GlassyButtonStyle(isDisabled: hasSent2FACode ? code.isEmpty : false, isMaterialButton: true))
                    } else {
                        if isDowngrading {
                            Button(action: {
                                Haptic.shared.play(.heavy)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    exitinator()
                                }
                            }) {
                                LabelStyle(text: "Go to Home Screen", icon: "house")
                            }
                            .buttonStyle(GlassyButtonStyle(isDisabled: !sharedData.hasAppBeenServed, isMaterialButton: true))
                        } else {
                            Button(action: {
                                Haptic.shared.play(.soft)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    if appLink.isEmpty {
                                        return
                                    }
                                    var appLinkParsed = appLink
                                    appLinkParsed = appLinkParsed.components(separatedBy: "id").last ?? ""
                                    for char in appLinkParsed {
                                        if !char.isNumber {
                                            appLinkParsed = String(appLinkParsed.prefix(upTo: appLinkParsed.firstIndex(of: char)!))
                                            break
                                        }
                                    }
                                    print("App ID: \(appLinkParsed)")
                                    isDowngrading = true
                                    downgradeApp(appId: appLinkParsed, ipaTool: ipaTool!)
                                }
                            }) {
                                LabelStyle(text: "Downgrade App", icon: "arrow.down")
                            }
                            .buttonStyle(GlassyButtonStyle(isMaterialButton: true))
                            
                            Button(action: {
                                Haptic.shared.play(.heavy)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    isAuthenticated = false
                                    EncryptedKeychainWrapper.nuke()
                                    EncryptedKeychainWrapper.generateAndStoreKey()
                                    sleep(3)
                                    exitinator()
                                }
                            }) {
                                LabelStyle(text: "Log Out & Exit", icon: "xmark")
                            }
                            .buttonStyle(GlassyButtonStyle(color: .red, isMaterialButton: true))
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 30)
                .background(VariableBlurView(maxBlurRadius: 5, direction: .blurredBottomClearTop).ignoresSafeArea())
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Haptic.shared.play(.soft)
                        showLogs.toggle()
                    }) {
                        Image(systemName: "terminal")
                    }
                }
            }
            .onAppear {
                isAuthenticated = EncryptedKeychainWrapper.hasAuthInfo()
                print("Found \(isAuthenticated ? "auth" : "no auth") info in keychain")
                if isAuthenticated {
                    guard let authInfo = EncryptedKeychainWrapper.getAuthInfo() else {
                        print("Failed to get auth info from keychain, logging out")
                        isAuthenticated = false
                        EncryptedKeychainWrapper.nuke()
                        EncryptedKeychainWrapper.generateAndStoreKey()
                        return
                    }
                    appleId = authInfo["appleId"]! as! String
                    password = authInfo["password"]! as! String
                    ipaTool = IPATool(appleId: appleId, password: password)
                    let ret = ipaTool?.authenticate()
                    print("Re-authenticated \(ret! ? "successfully" : "unsuccessfully")")
                } else {
                    print("No auth info found in keychain, setting up by generating a key in SEP")
                    EncryptedKeychainWrapper.generateAndStoreKey()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
