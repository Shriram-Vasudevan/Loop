import StoreKit
import SwiftUI
import Combine


import StoreKit
import SwiftUI
import Combine

enum SubscriptionType {
    case monthly
    case yearly
}

class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    @Published var isPremium = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    
    private let monthlyProductID = "LoopPremium"
    private let yearlyProductID = "Loop"
    
    init() {
        isPremium = UserDefaults.standard.bool(forKey: "userIsPremium")
        
        Task {
            await loadProducts()
            await checkPremiumStatus()
            await listenForTransactions()
        }
    }
    
    func isUserPremium() -> Bool {
        return isPremium
    }
    
    func getMaxRecordingDuration() -> Int {
        return isUserPremium() ? 1200 : 120
    }
    
    @MainActor
    func loadProducts() async {
        isLoading = true
        
        do {
            products = try await Product.products(for: [monthlyProductID, yearlyProductID])
            isLoading = false
        } catch {
            print("Failed to load products: \(error)")
            isLoading = false
        }
    }

    func getMonthlyProduct() -> Product? {
        return products.first { $0.id == monthlyProductID }
    }
    
    func getYearlyProduct() -> Product? {
        return products.first { $0.id == yearlyProductID }
    }
    
    func getFormattedPrice(for type: SubscriptionType) -> String {
        switch type {
        case .monthly:
            return getMonthlyProduct()?.displayPrice ?? "$0.00/month"
        case .yearly:
            return getYearlyProduct()?.displayPrice ?? "$0.00/year"
        }
    }

    @MainActor
    func checkPremiumStatus() async {
        do {
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                if (transaction.productID == monthlyProductID || transaction.productID == yearlyProductID) && transaction.revocationDate == nil {
                    self.isPremium = true
                    UserDefaults.standard.set(true, forKey: "userIsPremium")
                    return
                }
            }
        } catch {
            print("Failed to check premium status: \(error)")
        }
    }
    
    @MainActor
    func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if (transaction.productID == monthlyProductID || transaction.productID == yearlyProductID) && transaction.revocationDate == nil {
                self.isPremium = true
                UserDefaults.standard.set(true, forKey: "userIsPremium")
            }
            
            await transaction.finish()
        }
    }
    
    func purchasePremium(subscriptionType: SubscriptionType) async throws -> Bool {
        let productId = subscriptionType == .monthly ? monthlyProductID : yearlyProductID
        
        guard let product = products.first(where: { $0.id == productId }) else {
            print("Product not found")
            return false
        }
        
        do {
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

    func restorePurchases() async {
        isLoading = true
        
        await checkPremiumStatus()
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func getSubscriptionDetails() async -> (expiryDate: Date?, productId: String?) {
        var expiryDate: Date? = nil
        var productId: String? = nil
        
        do {
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                if (transaction.productID == monthlyProductID || transaction.productID == yearlyProductID) {
                    if let expirationDate = transaction.expirationDate {
                        if expiryDate == nil || expirationDate > expiryDate! {
                            expiryDate = expirationDate
                            productId = transaction.productID
                        }
                    }
                }
            }
        } catch {
            print("Error fetching subscription details: \(error)")
        }
        
        return (expiryDate, productId)
    }
}
