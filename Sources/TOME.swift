//
//  TOME.swift
//  tome2nrtm
//
//  Created by Gereon Steffens on 16.09.17.
//

import Foundation

struct TOME: Decodable {
    
    static let supportedVersion = "1.0.5"
    
    enum CodingKeys: String, CodingKey {
        case metadataVersion
        case entityGroupMap
    }
    
    enum EntityGroupMapKeys: String, CodingKey {
        case tournaments = "Tournament:#"
        case matches = "Match:#"
        case matchParticipants = "MatchParticipant:#"
        case participants = "Participant:#"
    }
    
    enum EntitiesKey: String, CodingKey {
        case entities
    }
    
    let metadataVersion: String
    
    let tournaments: [TOME.Tournament]
    let matches: [TOME.Match]
    let participants: [TOME.Participant]
    let matchParticipants: [TOME.MatchParticipant]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let entitiesMap = try container.nestedContainer(keyedBy: EntityGroupMapKeys.self, forKey: .entityGroupMap)
        
        let tournamentEntities = try entitiesMap.nestedContainer(keyedBy: EntitiesKey.self, forKey: .tournaments)
        self.tournaments = try tournamentEntities.decode([TOME.Tournament].self, forKey: .entities)
        
        let matchEntities = try entitiesMap.nestedContainer(keyedBy: EntitiesKey.self, forKey: .matches)
        self.matches = try matchEntities.decode([TOME.Match].self, forKey: .entities)
        
        let participantEntities = try entitiesMap.nestedContainer(keyedBy: EntitiesKey.self, forKey: .participants)
        self.participants = try participantEntities.decode([TOME.Participant].self, forKey: .entities)
        
        let matchParticipantEntities = try entitiesMap.nestedContainer(keyedBy: EntitiesKey.self, forKey: .matchParticipants)
        self.matchParticipants = try matchParticipantEntities.decode([TOME.MatchParticipant].self, forKey: .entities)
        
        self.metadataVersion = try container.decode(String.self, forKey: .metadataVersion)
    }
    
    private var tournamentMap = [Int: TOME.Tournament]()
    private var participantMap = [Int: TOME.Participant]()
    private var matchMap = [Int: TOME.Match]()
    private var matchParticipantMap = [Int: TOME.MatchParticipant]()
    
    private mutating func initializeMaps() {
        self.tournaments.forEach { self.tournamentMap[$0.pk] = $0 }
        self.participants.forEach { self.participantMap[$0.pk] = $0 }
        self.matches.forEach { self.matchMap[$0.pk] = $0 }
        self.matchParticipants.forEach { self.matchParticipantMap[$0.pk] = $0 }
        
        for tournament in self.tournaments {
            tournament.matches = self.matches.filter { $0.tournamentPk == tournament.pk }
            tournament.participants = self.participants.filter { $0.tournamentPk == tournament.pk }
            let matchPks = tournament.matches.map { $0.pk }
            tournament.matchParticipants = self.matchParticipants.filter { matchPks.contains($0.matchPk) }
        }
    }
    
    static func create(from data: Data) -> TOME? {
        do {
            let decoder = JSONDecoder()
            var export = try decoder.decode(TOME.self, from: data)
            
            if export.metadataVersion != TOME.supportedVersion {
                printErr("unsupported metadataVersion \(export.metadataVersion)")
                return nil
            }
            
            export.initializeMaps()
            return export
        } catch let error {
            printErr("json decoding error: \(error)")
        }
        return nil
    }
    
}


extension TOME {

    func printSwiss() {
        self.swissTournament.debugPrint()
    }
    
    func printElimination() {
        if let elims = self.doubleEliminationTournament {
            elims.debugPrint()
        }
    }
    
    var swissTournament: TOME.Tournament {
        if let index = self.tournaments.index(where: { $0.parentPk == nil }) {
            return self.tournaments[index]
        }
        
        die("no swiss tournament found")
    }
    
    var doubleEliminationTournament: TOME.Tournament? {
        if let index = self.tournaments.index(where: { $0.parentPk != nil }) {
            return self.tournaments[index]
        }
        return nil
    }
    
}
