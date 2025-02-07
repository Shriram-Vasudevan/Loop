//
//  DailyQuoteManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 2/7/25.
//

import SwiftUI

struct Quote: Identifiable, Codable {
    let id = UUID()
    let text: String
    let author: String
}

struct QuoteHistory: Codable {
    let quoteId: UUID
    let date: Date
}

struct DailyQuoteCache: Codable {
    let quote: Quote
    let date: Date
}

class QuoteManager: ObservableObject {
    static let shared = QuoteManager()
    
    @Published private(set) var currentQuote: Quote
    
    private let quotes: [Quote] = [
        Quote(text: "The unexamined life is not worth living.", author: "Socrates"),
        Quote(text: "Between stimulus and response there is a space. In that space is our power to choose our response.", author: "Viktor E. Frankl"),
        Quote(text: "Everything can be taken from a man but one thing: the last of human freedoms - to choose one's attitude in any given set of circumstances.", author: "Viktor E. Frankl"),
        Quote(text: "Life can only be understood backwards; but it must be lived forwards.", author: "Søren Kierkegaard"),
        Quote(text: "We do not learn from experience. We learn from reflecting on experience.", author: "John Dewey"),
        Quote(text: "Your vision will become clear only when you can look into your own heart.", author: "Carl Jung"),
        Quote(text: "Until you make the unconscious conscious, it will direct your life and you will call it fate.", author: "Carl Jung"),
        Quote(text: "The first step toward change is awareness.", author: "Nathaniel Branden"),
        Quote(text: "Self-awareness gives you the capacity to learn from your mistakes as well as your successes.", author: "Lawrence Bossidy"),
        Quote(text: "The journey into self-love and self-acceptance must begin with self-examination.", author: "Brené Brown"),
        Quote(text: "The more reflective you are, the more effective you are.", author: "Hall and Simeral"),
        Quote(text: "Knowing yourself is the beginning of all wisdom.", author: "Aristotle"),
        Quote(text: "The only journey is the one within.", author: "Rainer Maria Rilke"),
        Quote(text: "What lies behind us and what lies before us are tiny matters compared to what lies within us.", author: "Ralph Waldo Emerson"),
        Quote(text: "Everything that irritates us about others can lead us to an understanding of ourselves.", author: "Carl Jung"),
        Quote(text: "The quieter you become, the more you can hear.", author: "Ram Dass"),
        Quote(text: "Awareness is the greatest agent for change.", author: "Eckhart Tolle"),
        Quote(text: "The ability to observe without evaluating is the highest form of intelligence.", author: "Jiddu Krishnamurti"),
        Quote(text: "Self-reflection is the school of wisdom.", author: "Baltasar Gracián"),
        Quote(text: "Know thyself.", author: "Ancient Greek Aphorism"),
        Quote(text: "The most difficult thing in life is to know yourself.", author: "Thales"),
        Quote(text: "Your visions will become clear only when you can look into your own heart.", author: "Carl Jung"),
        Quote(text: "By three methods we may learn wisdom: by reflection, which is noblest; by imitation, which is easiest; and by experience, which is the bitterest.", author: "Confucius"),
        Quote(text: "There is no greater journey than the one that you must take to discover all of the mysteries that lie within you.", author: "Michelle Sandlin"),
        Quote(text: "The more you know yourself, the more clarity there is.", author: "Yogi Bhajan"),
        Quote(text: "Self-reflection is a humbling process.", author: "Melissa Daimler"),
        Quote(text: "Time spent in self-reflection is never wasted - it is an intimate date with yourself.", author: "Paul TP Wong"),
        Quote(text: "The journey of self-discovery is the journey of a lifetime.", author: "Laurette Rondeau"),
        Quote(text: "Honest self-reflection opens your mind to reprogramming.", author: "Ilchi Lee"),
        Quote(text: "The deepest secret is that life is not a process of discovery, but a process of creation.", author: "Neale Donald Walsch"),
        Quote(text: "If you want to conquer the anxiety of life, live in the moment, live in the breath.", author: "Amit Ray"),
        Quote(text: "Who looks outside, dreams; who looks inside, awakes.", author: "Carl Jung"),
        Quote(text: "The purpose of our lives is to be happy.", author: "Dalai Lama"),
        Quote(text: "Yesterday I was clever, so I wanted to change the world. Today I am wise, so I am changing myself.", author: "Rumi"),
        Quote(text: "The only person you are destined to become is the person you decide to be.", author: "Ralph Waldo Emerson"),
        Quote(text: "To think about your life is to create it.", author: "Neale Donald Walsch"),
        Quote(text: "Growth is the only evidence of life.", author: "John Henry Newman"),
        Quote(text: "Within you lies a capacity for self-transformation that is limitless.", author: "Sharon Salzberg"),
        Quote(text: "Change is not something that we should fear. Rather, it is something that we should welcome.", author: "BKS Iyengar"),
        Quote(text: "Every moment is a fresh beginning.", author: "T.S. Eliot"),
        Quote(text: "In the midst of movement and chaos, keep stillness inside of you.", author: "Deepak Chopra"),
        Quote(text: "Life is a series of natural and spontaneous changes.", author: "Lao Tzu"),
        Quote(text: "The real voyage of discovery consists not in seeking new landscapes, but in having new eyes.", author: "Marcel Proust"),
        Quote(text: "Transformation is a process, and as life happens there are tons of ups and downs.", author: "Rick Warren"),
        Quote(text: "Look deep into nature, and then you will understand everything better.", author: "Albert Einstein"),
        Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
        Quote(text: "What you get by achieving your goals is not as important as what you become by achieving your goals.", author: "Zig Ziglar"),
        Quote(text: "Life is 10% what happens to you and 90% how you react to it.", author: "Charles R. Swindoll"),
        Quote(text: "The most important relationship in your life is the relationship you have with yourself.", author: "Diane Von Furstenberg"),
        Quote(text: "You cannot find peace by avoiding life.", author: "Virginia Woolf"),
        Quote(text: "Each day is a new opportunity to learn more about yourself.", author: "Louise Hay"),
        Quote(text: "The way we choose to see the world creates the world we see.", author: "Barry Neil Kaufman"),
        Quote(text: "When you're different, sometimes you don't see the millions of people who accept you for what you are.", author: "Jodi Picoult"),
        Quote(text: "Happiness is not something ready made. It comes from your own actions.", author: "Dalai Lama"),
        Quote(text: "The most fundamental aggression to ourselves, the most fundamental harm we can do to ourselves, is to remain ignorant by not having the courage to look at ourselves honestly.", author: "Pema Chödrön"),
        Quote(text: "Your task is not to seek for love, but merely to seek and find all the barriers within yourself that you have built against it.", author: "Rumi"),
        Quote(text: "When I let go of what I am, I become what I might be.", author: "Lao Tzu"),
        Quote(text: "The privilege of a lifetime is to become who you truly are.", author: "Carl Jung"),
        Quote(text: "We must be willing to let go of the life we've planned, so as to have the life that is waiting for us.", author: "Joseph Campbell"),
        Quote(text: "The goal of life is to make your heartbeat match the beat of the universe, to match your nature with Nature.", author: "Joseph Campbell"),
        Quote(text: "Your life is a sacred journey. It is about change, growth, discovery, movement, transformation.", author: "Caroline Adams"),
        Quote(text: "The only person you should try to be better than is the person you were yesterday.", author: "Anonymous"),
        Quote(text: "Don't let yesterday take up too much of today.", author: "Will Rogers"),
        Quote(text: "Whatever you are doing, be present with it fully.", author: "Eckhart Tolle"),
        Quote(text: "Life begins where fear ends.", author: "Osho"),
        Quote(text: "The wound is the place where the Light enters you.", author: "Rumi"),
        Quote(text: "You are not a drop in the ocean. You are the entire ocean in a drop.", author: "Rumi"),
        Quote(text: "The universe is not outside of you. Look inside yourself; everything that you want, you already are.", author: "Rumi"),
        Quote(text: "Be like a tree and let the dead leaves drop.", author: "Rumi"),
        Quote(text: "Stop acting so small. You are the universe in ecstatic motion.", author: "Rumi"),
        Quote(text: "What you seek is seeking you.", author: "Rumi"),
        Quote(text: "Silence is the language of god, all else is poor translation.", author: "Rumi"),
        Quote(text: "Don't be satisfied with stories, how things have gone with others. Unfold your own myth.", author: "Rumi"),
        Quote(text: "Set your life on fire. Seek those who fan your flames.", author: "Rumi"),
        Quote(text: "These pains you feel are messengers. Listen to them.", author: "Rumi"),
        Quote(text: "Let silence take you to the core of life.", author: "Rumi"),
        Quote(text: "All that you seek is already within you.", author: "Ram Dass"),
        Quote(text: "In the end, just three things matter: How well we have lived, How well we have loved, How well we have learned to let go.", author: "Jack Kornfield"),
        Quote(text: "Peace comes from within. Do not seek it without.", author: "Buddha"),
        Quote(text: "No one saves us but ourselves. No one can and no one may. We ourselves must walk the path.", author: "Buddha"),
        Quote(text: "You yourself, as much as anybody in the entire universe, deserve your love and affection.", author: "Buddha"),
        Quote(text: "The mind is everything. What you think you become.", author: "Buddha"),
        Quote(text: "Every morning we are born again. What we do today is what matters most.", author: "Buddha"),
        Quote(text: "Nothing ever exists entirely alone; everything is in relation to everything else.", author: "Buddha"),
        Quote(text: "You only lose what you cling to.", author: "Buddha"),
        Quote(text: "Three things cannot be long hidden: the sun, the moon, and the truth.", author: "Buddha"),
        Quote(text: "To understand everything is to forgive everything.", author: "Buddha"),
        Quote(text: "Happiness does not depend on what you have or who you are. It solely relies on what you think.", author: "Buddha"),
        Quote(text: "An unexamined faith is not worth having, for fundamentalism and uncritical certitude entail the rejection of the divine gift of reason.", author: "Os Guinness"),
        Quote(text: "The longest journey is the journey inward.", author: "Dag Hammarskjöld"),
        Quote(text: "Sometimes you have to kind of die inside in order to rise from your own ashes and believe in yourself and love yourself to become a new person.", author: "Gerard Way"),
        Quote(text: "The most important kind of freedom is to be what you really are.", author: "Jim Morrison"),
        Quote(text: "Change the way you look at things and the things you look at change.", author: "Wayne W. Dyer"),
        Quote(text: "Life will give you whatever experience is most helpful for the evolution of your consciousness.", author: "Eckhart Tolle"),
        Quote(text: "The past has no power over the present moment.", author: "Eckhart Tolle"),
        Quote(text: "Life is the dancer and you are the dance.", author: "Eckhart Tolle"),
        Quote(text: "Realize deeply that the present moment is all you ever have.", author: "Eckhart Tolle"),
        Quote(text: "Sometimes letting things go is an act of far greater power than defending or hanging on.", author: "Eckhart Tolle"),
        Quote(text: "To love is to recognize yourself in another.", author: "Eckhart Tolle"),
        Quote(text: "Life isn't as serious as the mind makes it out to be.", author: "Eckhart Tolle"),
        Quote(text: "Whatever the present moment contains, accept it as if you had chosen it.", author: "Eckhart Tolle"),
        Quote(text: "You find peace not by rearranging the circumstances of your life, but by realizing who you are at the deepest level.", author: "Eckhart Tolle"),
        Quote(text: "Sometimes inner peace is about accepting that you can't control everything around you.", author: "Anonymous"),
        Quote(text: "In today's rush, we all think too much, seek too much, want too much, and forget about the joy of just being.", author: "Eckhart Tolle")
    ]
    
    private var quoteHistory: [QuoteHistory] = []
        
    private let userDefaults = UserDefaults.standard
    private let currentQuoteKey = "currentDailyQuote"
    private let quoteHistoryKey = "quoteHistory"
    
    private init() {
        self.currentQuote = Quote(text: "Loading...", author: "")
        loadQuoteHistory()
        
        if !loadTodaysQuote() {
            selectNewRandomQuote()
        }
    }
    
    private func loadQuoteHistory() {
        if let data = userDefaults.data(forKey: quoteHistoryKey),
           let history = try? JSONDecoder().decode([QuoteHistory].self, from: data) {
            quoteHistory = history
        }
    }
    
    private func saveQuoteHistory() {
        if let encoded = try? JSONEncoder().encode(quoteHistory) {
            userDefaults.set(encoded, forKey: quoteHistoryKey)
        }
    }
    
    private func loadTodaysQuote() -> Bool {
        guard let data = userDefaults.data(forKey: currentQuoteKey),
              let cachedQuote = try? JSONDecoder().decode(DailyQuoteCache.self, from: data) else {
            return false
        }
        
        if Calendar.current.isDateInToday(cachedQuote.date) {
            currentQuote = cachedQuote.quote
            return true
        }
        
        return false
    }
    
    private func saveCurrentQuote() {
        let cacheEntry = DailyQuoteCache(quote: currentQuote, date: Date())
        if let encoded = try? JSONEncoder().encode(cacheEntry) {
            userDefaults.set(encoded, forKey: currentQuoteKey)
        }
    }
    
    func selectNewRandomQuote() {
        let calendar = Calendar.current
        let twentyDaysAgo = calendar.date(byAdding: .day, value: -20, to: Date()) ?? Date()
        
        let recentQuoteIds = quoteHistory
            .filter { $0.date > twentyDaysAgo }
            .map { $0.quoteId }
        
        let availableQuotes = quotes.filter { quote in
            !recentQuoteIds.contains(quote.id)
        }
        

        let newQuote = availableQuotes.isEmpty ? quotes.randomElement() : availableQuotes.randomElement()
        
        if let newQuote = newQuote {
            currentQuote = newQuote
            
            let historyEntry = QuoteHistory(quoteId: newQuote.id, date: Date())
            quoteHistory.append(historyEntry)
            
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            quoteHistory = quoteHistory.filter { $0.date > thirtyDaysAgo }
            
            saveCurrentQuote()
            saveQuoteHistory()
        }
    }
}

extension UserDefaults {
    func set(_ value: Any?, for key: String) {
        set(value, forKey: key)
        synchronize()
    }
}

