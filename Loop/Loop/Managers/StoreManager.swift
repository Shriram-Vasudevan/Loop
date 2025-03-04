//
//  StoreManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/3/25.
//

import Foundation
import StoreKit

class StoreManager: ObservableObject {
    @Published var products: Set<Product> = []
    
    func getProducts() async {
        do {
            let ids = ["LoopPremium"]
            
            let products = try await Product.products(for: ids)
            self.products = Set(products)
        } catch {
            print(error.localizedDescription)
        }
    }
}
