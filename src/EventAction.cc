#include "EventAction.hh"
#include "G4Event.hh"
#include "G4SDManager.hh"
#include "G4THitsMap.hh"
#include "G4AnalysisManager.hh"
#include "G4SystemOfUnits.hh"

EventAction::EventAction(RunAction*) {}

void EventAction::BeginOfEventAction(const G4Event*) {}

void EventAction::EndOfEventAction(const G4Event* event) {
    if (fCollID == -1) {
        fCollID = G4SDManager::GetSDMpointer()->GetCollectionID("NaIDetector/EdepScorer");
    }

    auto* hce = event->GetHCofThisEvent();
    if (!hce) return;

    auto* hitsMap = static_cast<G4THitsMap<G4double>*>(hce->GetHC(fCollID));
    if (!hitsMap) return;

    G4double totalEdep = 0.;
    for (const auto& pair : *hitsMap->GetMap()) {
        totalEdep += *pair.second;
    }

    if (totalEdep > 0.) {
        auto* analysisManager = G4AnalysisManager::Instance();
        analysisManager->FillH1(0, totalEdep);
        analysisManager->FillNtupleDColumn(0, totalEdep / MeV);
        analysisManager->AddNtupleRow();
    }
}
