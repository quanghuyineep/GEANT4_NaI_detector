#include "RunAction.hh"
#include "G4AnalysisManager.hh"
#include "G4SystemOfUnits.hh"

RunAction::RunAction() {
    auto* analysisManager = G4AnalysisManager::Instance();
    analysisManager->SetDefaultFileType("root");
    analysisManager->SetVerboseLevel(1);
    analysisManager->SetFileName("output_nai");

    // Tạo Histogram phổ năng lượng (0 đến 1.5 MeV, 1024 kênh)
    analysisManager->CreateH1("Edep", "Energy Deposition in NaI", 1024, 0., 1.5 * MeV);
    
    // Tạo Ntuple lưu năng lượng từng event
    analysisManager->CreateNtuple("Events", "NaI Event Data");
    analysisManager->CreateNtupleDColumn("Edep_MeV");
    analysisManager->FinishNtuple();
}

void RunAction::BeginOfRunAction(const G4Run*) {
    auto* analysisManager = G4AnalysisManager::Instance();
    analysisManager->OpenFile();
}

void RunAction::EndOfRunAction(const G4Run*) {
    auto* analysisManager = G4AnalysisManager::Instance();
    analysisManager->Write();
    analysisManager->CloseFile();
}
