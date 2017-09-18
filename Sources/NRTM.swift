//
//  NRTM.swift
//  tome2nrtm
//
//  Created by Gereon Steffens on 10.09.17.
//

import Foundation

struct NRTM {
    
    enum Role: String, Encodable {
        case runner
        case corp
    }
    
    struct Player: Encodable {
        let id: Int
        let name: String
        let runnerFaction: String
        let runnerIdentity: String
        let corpFaction: String
        let corpIdentity: String
        let forfeit: Bool
        
        let rank: Int
        let matchPoints: Int
        let strengthOfSchedule: NSDecimalNumber
        let extendedStrengthOfSchedule: NSDecimalNumber
        
        init(fromTome participant: TOME.Participant) {
            self.id = participant.pk
            self.name = participant.name
            self.runnerFaction = participant.runnerFaction
            self.runnerIdentity = participant.runnerIdentity
            self.corpFaction = participant.corpFaction
            self.corpIdentity = participant.corpIdentity
            self.forfeit = !participant.isActive
            
            self.rank = participant.rank
            self.matchPoints = participant.score
            self.strengthOfSchedule = participant.strengthOfSchedule
            self.extendedStrengthOfSchedule = participant.extendedStrengthOfSchedule
        }
    }
    
    struct EliminationPlayer: Encodable {
        let id: Int
        let name: String
        let rank: Int
        let seed: Int
    }
    
    struct SwissResult: Encodable {
        let id: Int
        let runnerScore: Int
        let corpScore: Int
    }
    
    struct EliminationResult: Encodable {
        let id: Int
        let role: Role
        let winner: Bool
    }
    
    enum Result: Encodable {
        case swiss(SwissResult)
        case elimination(EliminationResult)
        
        var id: Int {
            switch self {
            case .swiss(let result): return result.id
            case .elimination(let result): return result.id
            }
        }
        
        func encode(to encoder: Encoder) throws {
            switch self {
            case .swiss(let result):
                try result.encode(to: encoder)
            case .elimination(let result):
                try result.encode(to: encoder)
            }
        }
    }
    
    struct Game: Encodable {
        let table: Int
        let player1: Result
        let player2: Result
        let eliminationGame: Bool
        
        init(table: Int, player1: SwissResult, player2: SwissResult) {
            self.table = table
            self.player1 = Result.swiss(player1)
            self.player2 = Result.swiss(player2)
            self.eliminationGame = false
        }
        
        init(table: Int, player1: EliminationResult, player2: EliminationResult) {
            self.table = table
            self.player1 = Result.elimination(player1)
            self.player2 = Result.elimination(player2)
            self.eliminationGame = true
        }
    }
    
    struct Round: Encodable {
        var games: [Game]
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(games)
        }
    }
    
    struct Tournament: Encodable {
        let name: String
        
        let players: [Player]
        let eliminationPlayers: [EliminationPlayer]
        let rounds: [Round]
        
        let preliminaryRounds: Int
        let cutToTop: Int
    }
    
}

extension NRTM.Tournament {
    
    private static func splitScore(_ total: Int) -> (Int, Int) {
        if total < 4 {
            return (total, 0)
        } else {
            return (3, total - 3)
        }
    }

    private static func swissRounds(_ swiss: TOME.Tournament) -> [NRTM.Round] {
        var rounds = [NRTM.Round]()
        for round in 1 ... swiss.currentRound {
            let matches = swiss.matches.filter { $0.round == round }
            
            var games = [NRTM.Game]()
            for match in matches {
                let matchParticipants = swiss.matchParticipants.filter { $0.matchPk == match.pk }
                
                if matchParticipants.count == 2 {
                    let player1 = matchParticipants[0]
                    let player2 = matchParticipants[1]
                    
                    let (r1, c1) = splitScore(player1.pointsEarned)
                    let p1result = NRTM.SwissResult(id: player1.participantPk, runnerScore: r1, corpScore: c1)
                    
                    let (r2, c2) = splitScore(player2.pointsEarned)
                    let p2result = NRTM.SwissResult(id: player2.participantPk, runnerScore: r2, corpScore: c2)
                    
                    assert(r1+c1+r2+c2 < 7)
                    let game = NRTM.Game(table: match.orderIndex + 1, player1: p1result, player2: p2result)
                    games.append(game)
                } else {
                    // record a BYE
//                    let player1 = matchParticipants[0]
//                    let p1result = NRTM.SwissResult(id: player1.pk, runnerScore: 3, corpScore: 3)
//
//                    let p2result = NRTM.SwissResult(id: 0, runnerScore: 0, corpScore: 0)
//                    let game = NRTM.Game(table: match.orderIndex + 1, player1: p1result, player2: p2result)
//                    games.append(game)
                }
            }
            
            let round = NRTM.Round(games: games)
            rounds.append(round)
        }
        return rounds
    }
    
    private static func lookupPlayer(_ name: String, in participants: [TOME.Participant]) -> TOME.Participant {
        if let index = participants.index(where: { $0.name == name }) {
            return participants[index]
        }
        fatalError("player \(name) not found in swiss participants")
    }
    
    private static func eliminationRounds(_ elims: TOME.Tournament, swissParticipants: [TOME.Participant]) -> [NRTM.Round] {
        var eliminationRounds = [NRTM.Round]()
        for round in 1 ... elims.currentRound {
            let matches = elims.matches.filter { $0.round == round }
            
            var games = [NRTM.Game]()
            for match in matches {
                let matchParticipants = elims.matchParticipants.filter { $0.matchPk == match.pk }
                
                if matchParticipants.count == 2 {
                    let player1 = matchParticipants[0]
                    let player2 = matchParticipants[1]
                    
                    let p1name = elims.participant(for: player1.participantPk)?.name ?? "n/a"
                    let p2name = elims.participant(for: player2.participantPk)?.name ?? "n/a"
                    
                    let p1 = self.lookupPlayer(p1name, in: swissParticipants)
                    let p2 = self.lookupPlayer(p2name, in: swissParticipants)
                    
                    let p1result = NRTM.EliminationResult(id: p1.pk, role: .runner, winner: player1.pointsEarned == 3)
                    let p2result = NRTM.EliminationResult(id: p2.pk, role: .runner, winner: player2.pointsEarned == 3)
                    let game = NRTM.Game(table: match.orderIndex + 1, player1: p1result, player2: p2result)
                    games.append(game)
                }
            }
            
            let round = NRTM.Round(games: games)
            eliminationRounds.append(round)
        }
        return eliminationRounds
    }
    
    static func eliminationPlayers(_ elimParticipants: [TOME.Participant], swissParticipants: [TOME.Participant]) -> [NRTM.EliminationPlayer] {
        var players = [NRTM.EliminationPlayer]()
        
        for (r, elimPlayer) in elimParticipants.enumerated() {
            let lookup = self.lookupPlayer(elimPlayer.name, in: swissParticipants)
            let p = NRTM.EliminationPlayer(id: lookup.pk, name: lookup.name, rank: r + 1, seed: lookup.rank)
            players.append(p)
        }
        return players
    }
    
    static func create(from tome: TOME) -> NRTM.Tournament {
        let swiss = tome.swissTournament
        let swissParticipants = swiss.calculateScores()
        
        let players: [NRTM.Player] = swissParticipants.filter { !$0.strengthOfSchedule.isNaN }.map { NRTM.Player(fromTome: $0) }
        let swissRounds = self.swissRounds(swiss)
        
        var allRounds = swissRounds
        var eliminationPlayers = [NRTM.EliminationPlayer]()
        
        if let elims = tome.doubleEliminationTournament {
            let eliminationRounds = self.eliminationRounds(elims, swissParticipants: swissParticipants)
            allRounds.append(contentsOf: eliminationRounds)
            
            let elimParticipants = elims.calculateScores()
            eliminationPlayers = self.eliminationPlayers(elimParticipants, swissParticipants: swissParticipants)
        }
        
        let result = NRTM.Tournament(name: swiss.name,
                                     players: players,
                                     eliminationPlayers: eliminationPlayers,
                                     rounds: allRounds,
                                     preliminaryRounds: swiss.currentRound,
                                     cutToTop: swiss.cutSize ?? 0)
        return result
    }
}
