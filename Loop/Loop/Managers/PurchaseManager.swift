//
//  PurchaseManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/3/25.
//

import Foundation
import StoreKit

class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    func purchaseProduct(_ product: Product) async {
        do {
            let purchaseResult = try await product.purchase()
            
            switch purchaseResult {
                case .success(let verificationResult):
                    switch verificationResult {
                        case .verified(let transaction):
                            await completeTransaction(transaction)
                        case .unverified(let transaction, let verificationError):
                            break
                    }
                case .pending:
                    break
                case .userCancelled:
                    break
                @unknown default:
                    break
            }
        } catch {
            
        }
    }
    
    private func completeTransaction(_ transaction: Transaction) async {
       UserDefaults.standard.set(true, forKey: "isPremiumUser")
        await transaction.finish()
   }

   private func restoreTransaction(_ transaction: Transaction) async {
       UserDefaults.standard.set(true, forKey: "isPremiumUser")
       await transaction.finish()
   }
    
    func checkIfPremiumUser() -> Bool {
        return UserDefaults.standard.bool(forKey: "isPremiumUser")
    }
}
