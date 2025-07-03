
//
//  ParentalGateView.swift
//  KidTubePlayer
//
//  Created by Gemini on 2025/7/3.
//

import SwiftUI

/// 一个用于输入和设置家长控制密码的视图
struct ParentalGateView: View {
    
    enum Mode {
        case setup
        case unlock
    }
    
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode
    
    let mode: Mode
    
    @State private var pin: String = ""
    @State private var feedbackMessage: String = ""
    @State private var attempts: Int = 0
    
    private var title: String {
        switch mode {
        case .setup:
            return "设置家长密码"
        case .unlock:
            return "进入家长模式"
        }
    }
    
    private var prompt: String {
        switch mode {
        case .setup:
            return "请输入一个4位数字密码"
        case .unlock:
            return "请输入密码"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(prompt)
                    .font(.headline)
                
                SecureField("----", text: $pin)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 150)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                Text(feedbackMessage)
                    .foregroundColor(.red)
                    .frame(height: 40)
                
                Button(action: submit) {
                    Text(mode == .setup ? "保存密码" : "解锁")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(pin.count != 4)
            }
            .padding()
            .navigationTitle(title)
            .navigationBarItems(leading: Button("取消") { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    private func submit() {
        switch mode {
        case .setup:
            if UserSettings.setPassword(pin: pin) {
                appSettings.isParentalModeUnlocked = true
                presentationMode.wrappedValue.dismiss()
            } else {
                feedbackMessage = "设置失败，请输入4位数字。"
                pin = ""
            }
        case .unlock:
            if UserSettings.verifyPassword(pin: pin) {
                appSettings.isParentalModeUnlocked = true
                presentationMode.wrappedValue.dismiss()
            } else {
                feedbackMessage = "密码错误，请重试。"
                pin = ""
                attempts += 1
                // 增加一些轻微的触觉反馈
                let haptic = UIImpactFeedbackGenerator(style: .medium)
                haptic.impactOccurred()
            }
        }
    }
}

struct ParentalGateView_Previews: PreviewProvider {
    static var previews: some View {
        ParentalGateView(mode: .unlock)
            .environmentObject(AppSettings())
    }
}

