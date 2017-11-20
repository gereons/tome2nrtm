//
//  TOMEData.swift
//  tome2nrtm
//
//  Created by Gereon Steffens on 16.09.17.
//
//  Raw data structures and JSON decoding keys for all structures in the TOME Export file that we're interested in
//

import Foundation

class ScoreCache {
    
    enum ScoreType: String {
        case avg
        case sos
        case xsos
    }
    
    private var cache = [String: NSDecimalNumber]()
    
    func store(_ value: NSDecimalNumber, for key: (Int, ScoreType)) {
        let str = "\(key.0)-\(key.1.rawValue)"
        self.cache[str] = value
    }
    
    func get(for key: (Int, ScoreType)) -> NSDecimalNumber? {
        let str = "\(key.0)-\(key.1.rawValue)"
        return self.cache[str]
    }
    
    func reset() {
        self.cache.removeAll()
    }
}

extension TOME {
    
    class Tournament: Decodable {
        let pk: Int
        let formatPk: Int
        let settingsPk: Int
        let parentPk: Int?
        let name: String
        let currentRound: Int
        let cutSize: Int?
        let dashboardCount: Int
        
        var matches = [Match]()
        var participants = [Participant]()
        var matchParticipants = [MatchParticipant]()
        
        var scoreCache = ScoreCache()
        
        enum CodingKeys: String, CodingKey {
            case pk
            case formatPk = "format_pk"
            case settingsPk = "settings_pk"
            case parentPk = "parent_pk"
            case name
            case currentRound = "current_round"
            case cutSize = "cut_size"
            case dashboardCount = "dashboard_count"
        }
    }
    
    class Participant: Decodable {
        let pk: Int
        let tournamentPk: Int?
        
        let firstName: String?
        let lastName: String?
        
        let runnerFaction: String
        let runnerIdentity: String
        let corpFaction: String
        let corpIdentity: String
        
        let seed: Int               // ???
        let rewardByes: Int         // 0 or 1, 1st round superbye?
        let hasReceivedBye: Bool
        let isActive: Bool          // false == dropped
        let tiebreaker: Double      // random number, use to break ties if score, sos and xsos are equal
        
        fileprivate(set) var score = 0
        fileprivate(set) var rank = 0
        fileprivate var tournament: Tournament! = nil
        
        var name: String {
            if let first = self.firstName, let last = self.lastName {
                return "\(first) \(last)"
            }
            return "n/a"
        }
        
        enum CodingKeys: String, CodingKey {
            case pk
            case tournamentPk = "tournament_pk"
            case firstName = "first_name"
            case lastName = "last_name"
            case runnerFaction = "faction"
            case runnerIdentity = "identity"
            case corpFaction = "faction2"
            case corpIdentity = "identity2"
            case seed
            case rewardByes = "reward_byes"
            case hasReceivedBye = "has_received_bye"
            case isActive = "is_active"
            case tiebreaker
        }
    }
    
    class Match: Decodable {
        let pk: Int
        let tournamentPk: Int?
        let round: Int
        let orderIndex: Int     // table number
        
        enum CodingKeys: String, CodingKey {
            case pk
            case tournamentPk = "tournament_pk"
            case round
            case orderIndex = "order_index"
        }
    }
    
    class MatchParticipant: Decodable {
        let pk: Int
        let participantPk: Int?
        let matchPk: Int
        let pointsEarned: Int?
        let tableSeat: Int      // 0 or 1
        
        enum CodingKeys: String, CodingKey {
            case pk
            case participantPk = "participant_pk"
            case matchPk = "match_pk"
            case pointsEarned = "points_earned"
            case tableSeat = "table_seat"
        }
    }

}

extension TOME.Participant {
    
    var averageScore: NSDecimalNumber {
        if let avg = tournament.scoreCache.get(for: (self.pk, .avg)) {
            return avg
        }
        
        var pointsEarned = NSDecimalNumber.zero
        var matchesPlayed = NSDecimalNumber.zero
        
        tournament.enumerateMatches { matchParticipants in
            if matchParticipants.count == 2 {
                let p1 = matchParticipants[0]
                let p2 = matchParticipants[1]
                
                if self.pk == p1.participantPk {
                    pointsEarned += p1.pointsEarned!
                    matchesPlayed += 1
                } else if self.pk == p2.participantPk {
                    pointsEarned += p2.pointsEarned!
                    matchesPlayed += 1
                }
            } else {
                let p1 = matchParticipants[0]
                if p1.participantPk == self.pk {
                    pointsEarned += 6
                    matchesPlayed += 1
                }
            }
        }
        
        let result = matchesPlayed > 0 ? pointsEarned / matchesPlayed : NSDecimalNumber.zero
        tournament.scoreCache.store(result, for: (self.pk, .avg))
        return result
    }
    
    var strengthOfSchedule: NSDecimalNumber {
        if let sos = tournament.scoreCache.get(for: (self.pk, .sos)) {
            return sos
        }
        
        var sumOfAverageScores = NSDecimalNumber.zero
        var opponents = NSDecimalNumber.zero
        
        tournament.enumerateMatches { matchParticipants in
            if matchParticipants.count == 2 {
                let p1 = matchParticipants[0]
                let p2 = matchParticipants[1]
                
                if self.pk == p1.participantPk {
                    sumOfAverageScores += tournament.participant(for: p2.participantPk!)!.averageScore
                    opponents += 1
                } else if self.pk == p2.participantPk {
                    sumOfAverageScores += tournament.participant(for: p1.participantPk!)!.averageScore
                    opponents += 1
                }
            }
        }
        
        let result = opponents > 0 ? sumOfAverageScores / opponents : NSDecimalNumber.zero
        tournament.scoreCache.store(result, for: (self.pk, .sos))
        return result
    }
    
    var extendedStrengthOfSchedule: NSDecimalNumber {
        if let xsos = tournament.scoreCache.get(for: (self.pk, .xsos)) {
            return xsos
        }
        
        var sumOfSoS = NSDecimalNumber.zero
        var opponents = NSDecimalNumber.zero
        
        tournament.enumerateMatches { matchParticipants in
            if matchParticipants.count == 2 {
                let p1 = matchParticipants[0]
                let p2 = matchParticipants[1]
                
                if self.pk == p1.participantPk {
                    sumOfSoS += tournament.participant(for: p2.participantPk!)!.strengthOfSchedule
                    opponents += 1
                } else if self.pk == p2.participantPk {
                    sumOfSoS += tournament.participant(for: p1.participantPk!)!.strengthOfSchedule
                    opponents += 1
                }
            }
        }
        
        let result = opponents > 0 ? sumOfSoS / opponents : NSDecimalNumber.zero
        tournament.scoreCache.store(result, for: (self.pk, .xsos))
        return result
    }
    
}

extension TOME.Tournament {
    
    func participant(for pk: Int) -> TOME.Participant? {
        if let index = participants.index(where: { $0.pk == pk }) {
            return participants[index]
        }
        return nil
    }
    
    func enumerateMatches(handler: ([TOME.MatchParticipant])->()) {
        for round in 1 ... self.currentRound {
            let matches = self.matches.filter { $0.round == round }
            
            for match in matches {
                let matchParticipants = self.matchParticipants.filter { $0.matchPk == match.pk }
                
                handler(matchParticipants)
            }
        }
    }
    
    func calculateScores() -> [TOME.Participant] {
        self.scoreCache.reset()
        
        self.participants.forEach {
            $0.tournament = self
            $0.score = 0
        }
        
        self.enumerateMatches { matchParticipants in
            if matchParticipants.count == 1 {
                let player1 = self.participant(for: matchParticipants[0].participantPk!)
                player1?.score += 6
            } else {
                assert(matchParticipants.count == 2)
                
                let player1 = self.participant(for: matchParticipants[0].participantPk!)
                let player2 = self.participant(for: matchParticipants[1].participantPk!)
                
                player1?.score += matchParticipants[0].pointsEarned!
                player2?.score += matchParticipants[1].pointsEarned!
            }
        }
        
        let players = self.participants.sorted { p1, p2 in
            if p1.score == p2.score {
                if p1.strengthOfSchedule == p2.strengthOfSchedule {
                    if p1.extendedStrengthOfSchedule == p2.extendedStrengthOfSchedule {
                        return p1.tiebreaker > p2.tiebreaker
                    } else {
                        return p1.extendedStrengthOfSchedule > p2.extendedStrengthOfSchedule
                    }
                } else {
                    return p1.strengthOfSchedule > p2.strengthOfSchedule
                }
            } else {
                return p1.score > p2.score
            }
        }
        
        for i in 0 ..< players.count {
            players[i].rank = i + 1
        }
        
        return players
    }
    
    func printRanking(_ players: [TOME.Participant]) {
        let fmt = NumberFormatter()
        fmt.roundingMode = .halfUp
        fmt.minimumFractionDigits = 5
        fmt.minimumIntegerDigits = 1
        
        for i in 0..<players.count {
            let player = players[i]
            
            if player.averageScore.isNaN {
                continue
            }
            
            let avgScore = fmt.string(from: player.averageScore as NSNumber)!
            let sos = fmt.string(from: player.strengthOfSchedule as NSNumber)!
            let xsos = fmt.string(from: player.extendedStrengthOfSchedule as NSNumber)!
            
            printErr("\(i+1) p=\(player.score) \(player.name) avg=\(avgScore) sos=\(sos) xsos=\(xsos) \(player.isActive) \(player.pk)")
        }
    }
    
    func debugPrint() {
        print("Tournament: \(self.name) \(self.pk)")
        print("  \(self.participants.count) players")
        
        for round in 1 ... self.currentRound {
            print("Round \(round)")
            let matches = self.matches.filter { $0.round == round }.sorted { $0.orderIndex < $1.orderIndex }
            print("  Matches: \(matches.count)")
            for match in matches {
                let opponents = self.matchParticipants.filter { $0.matchPk == match.pk }
                let opp = opponents.flatMap { self.participant(for: $0.participantPk!)?.name }.joined(separator: " vs ")
                let result = opponents.map { String($0.pointsEarned!) }.joined(separator: ":")
                if match.orderIndex == -1 {
                    assert(opponents.count == 1)
                    print("  Bye: \(opp)")
                } else {
                    assert(opponents.count == 2)
                    let table = match.orderIndex + 1
                    print("  Table \(table): Opponents: \(opp) \(result)")
                }
            }
        }
        
        let players = self.calculateScores()
        self.printRanking(players)
    }
    
}
