import StoreKit
import SwiftUI
import Combine


class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    @Published var isPremium = false
    private let premiumProductID = "com.yourapp.premium"
    
    init() {
        // Load saved premium status
        isPremium = UserDefaults.standard.bool(forKey: "userIsPremium")
        
        Task {
            await checkPremiumStatus()
            await listenForTransactions()
        }
    }
    
    // Simple function to check if user is premium
    func isUserPremium() -> Bool {
        return isPremium
    }
    
    // Get max recording duration based on premium status
    func getMaxRecordingDuration() -> Int {
        return isUserPremium() ? 1200 : 60 // 1200 seconds (20 min) for premium, 60 seconds for free
    }
    
    // Check premium status from StoreKit
    @MainActor
    func checkPremiumStatus() async {
        do {
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                if transaction.productID == premiumProductID && transaction.revocationDate == nil {
                    self.isPremium = true
                    UserDefaults.standard.set(true, forKey: "userIsPremium")
                    return
                }
            }
        } catch {
            print("Failed to check premium status: \(error)")
        }
    }
    
    // Listen for transactions
    @MainActor
    func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.productID == premiumProductID && transaction.revocationDate == nil {
                self.isPremium = true
                UserDefaults.standard.set(true, forKey: "userIsPremium")
            }
            
            await transaction.finish()
        }
    }
    
    // Purchase premium
    func purchasePremium() async throws -> Bool {
        do {
            let products = try await Product.products(for: [premiumProductID])
            guard let product = products.first else {
                print("Premium product not found")
                return false
            }
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                guard case .verified(let transaction) = verificationResult else {
                    return false
                }
                
                await transaction.finish()
                await MainActor.run {
                    self.isPremium = true
                }
                UserDefaults.standard.set(true, forKey: "userIsPremium")
                return true
                
            case .userCancelled, .pending:
                return false
                
            default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            throw error
        }
    }
    
    // Restore purchases
    func restorePurchases() async {
        await checkPremiumStatus()
    }
}
