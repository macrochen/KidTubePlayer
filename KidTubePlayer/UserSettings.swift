
//
//  UserSettings.swift
//  KidTubePlayer
//
//  Created by Gemini on 2025/7/3.
//

import Foundation
import CryptoKit

/// 一个用于管理用户设置（如下次启动时是否需要重新输入密码）的辅助类
class AppSettings: ObservableObject {
    @Published var isParentalModeUnlocked: Bool = false
}

/// 一个专门用于安全管理家长密码和API Key、停用词的辅助类
struct UserSettings {

    private static let passwordKey = "parental_control_password_hash"
    

    // MARK: - Parental Control Password

    /// 检查是否已经设置过密码
    static var isPasswordSet: Bool {
        return UserDefaults.standard.data(forKey: passwordKey) != nil
    }

    /// 设置一个新的密码
    /// - Parameter pin: 用户输入的4位PIN码
    /// - Returns: 是否设置成功
    static func setPassword(pin: String) -> Bool {
        guard pin.count == 4, pin.allSatisfy({ $0.isNumber }) else { return false }
        let hashedPin = hash(pin: pin)
        UserDefaults.standard.set(hashedPin, forKey: passwordKey)
        return true
    }

    /// 验证输入的PIN码是否正确
    /// - Parameter pin: 用户输入的4位PIN码
    /// - Returns: 是否验证通过
    static func verifyPassword(pin: String) -> Bool {
        guard let storedHash = UserDefaults.standard.data(forKey: passwordKey) else { return false }
        let inputHash = hash(pin: pin)
        return storedHash == inputHash
    }

    /// 将PIN码字符串转换为一个安全的哈希值
    /// - Parameter pin: 4位PIN码字符串
    /// - Returns: 哈希后的Data对象
    private static func hash(pin: String) -> Data {
        let data = pin.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return Data(hash)
    }

    // MARK: - API Keys

    

    // MARK: - Stop Words

    
}

