#!/bin/bash
set -e

PROJECT_DIR="sim_nai"
mkdir -p "$PROJECT_DIR/src" "$PROJECT_DIR/include"

# 1. CMakeLists.txt
cat << 'FILE' > "$PROJECT_DIR/CMakeLists.txt"
cmake_minimum_required(VERSION 3.16)
project(sim_nai)

find_package(Geant4 REQUIRED ui_all vis_all)
include(${Geant4_USE_FILE})

file(GLOB SOURCES ${PROJECT_SOURCE_DIR}/src/*.cc)
file(GLOB HEADERS ${PROJECT_SOURCE_DIR}/include/*.hh)

add_executable(sim_nai sim_nai.cc ${SOURCES} ${HEADERS})
target_link_libraries(sim_nai ${Geant4_LIBRARIES})
FILE

# 2. sim_nai.cc (main)
cat << 'FILE' > "$PROJECT_DIR/sim_nai.cc"
#include "G4RunManagerFactory.hh"
#include "G4UImanager.hh"
#include "G4VisExecutive.hh"
#include "G4UIExecutive.hh"
#include "FTFP_BERT.hh"

#include "DetectorConstruction.hh"
#include "ActionInitialization.hh"

int main(int argc, char** argv) {
    G4UIExecutive* ui = nullptr;
    if (argc == 1) {
        ui = new G4UIExecutive(argc, argv);
    }

    auto* runManager = G4RunManagerFactory::CreateRunManager(G4RunManagerType::Default);
    runManager->SetUserInitialization(new DetectorConstruction());
    
    auto* physicsList = new FTFP_BERT();
    runManager->SetUserInitialization(physicsList);
    runManager->SetUserInitialization(new ActionInitialization());

    auto* visManager = new G4VisExecutive();
    visManager->Initialize();

    auto* UImanager = G4UImanager::GetUIpointer();

    if (!ui) {
        G4String command = "/control/execute ";
        G4String fileName = argv[1];
        UImanager->ApplyCommand(command + fileName);
    } else {
        UImanager->ApplyCommand("/control/execute init_vis.mac");
        ui->SessionStart();
        delete ui;
    }

    delete visManager;
    delete runManager;
    return 0;
}
FILE

# 3. DetectorConstruction.hh & .cc
cat << 'FILE' > "$PROJECT_DIR/include/DetectorConstruction.hh"
#ifndef DETECTOR_CONSTRUCTION_HH
#define DETECTOR_CONSTRUCTION_HH

#include "G4VUserDetectorConstruction.hh"
#include "globals.hh"

class G4VPhysicalVolume;

class DetectorConstruction : public G4VUserDetectorConstruction {
public:
    DetectorConstruction() = default;
    ~DetectorConstruction() override = default;
    G4VPhysicalVolume* Construct() override;
    void ConstructSDandField() override;
};
#endif
FILE

cat << 'FILE' > "$PROJECT_DIR/src/DetectorConstruction.cc"
#include "DetectorConstruction.hh"
#include "G4NistManager.hh"
#include "G4Box.hh"
#include "G4Tubs.hh"
#include "G4LogicalVolume.hh"
#include "G4PVPlacement.hh"
#include "G4SystemOfUnits.hh"
#include "G4SDManager.hh"
#include "G4MultiFunctionalDetector.hh"
#include "G4PSEnergyDeposit.hh"

G4VPhysicalVolume* DetectorConstruction::Construct() {
    auto* nist = G4NistManager::Instance();

    // World
    auto* worldMat = nist->FindOrBuildMaterial("G4_AIR");
    auto* solidWorld = new G4Box("SolidWorld", 0.5*m, 0.5*m, 0.5*m);
    auto* logicWorld = new G4LogicalVolume(solidWorld, worldMat, "LogicWorld");
    auto* physWorld = new G4PVPlacement(nullptr, G4ThreeVector(), logicWorld, "PhysWorld", nullptr, false, 0);

    // NaI Crystal (2" x 2" cylinder)
    auto* naiMat = nist->FindOrBuildMaterial("G4_SODIUM_IODIDE");
    auto* solidNaI = new G4Tubs("SolidNaI", 0.*cm, 2.54*cm, 2.54*cm, 0.*deg, 360.*deg);
    auto* logicNaI = new G4LogicalVolume(solidNaI, naiMat, "LogicNaI");
    new G4PVPlacement(nullptr, G4ThreeVector(0, 0, 10.*cm), logicNaI, "PhysNaI", logicWorld, false, 0);

    return physWorld;
}

void DetectorConstruction::ConstructSDandField() {
    auto* sdManager = G4SDManager::GetSDMpointer();
    auto* naiDetector = new G4MultiFunctionalDetector("NaIDetector");
    auto* edepScorer = new G4PSEnergyDeposit("EdepScorer");
    naiDetector->RegisterPrimitive(edepScorer);
    sdManager->AddNewDetector(naiDetector);
    SetSensitiveDetector("LogicNaI", naiDetector);
}
FILE

# 4. ActionInitialization.hh & .cc
cat << 'FILE' > "$PROJECT_DIR/include/ActionInitialization.hh"
#ifndef ACTION_INITIALIZATION_HH
#define ACTION_INITIALIZATION_HH

#include "G4VUserActionInitialization.hh"

class ActionInitialization : public G4VUserActionInitialization {
public:
    ActionInitialization() = default;
    ~ActionInitialization() override = default;
    void BuildForMaster() const override;
    void Build() const override;
};
#endif
FILE

cat << 'FILE' > "$PROJECT_DIR/src/ActionInitialization.cc"
#include "ActionInitialization.hh"
#include "PrimaryGeneratorAction.hh"
#include "RunAction.hh"
#include "EventAction.hh"

void ActionInitialization::BuildForMaster() const {
    SetUserAction(new RunAction());
}

void ActionInitialization::Build() const {
    SetUserAction(new PrimaryGeneratorAction());
    auto* runAction = new RunAction();
    SetUserAction(runAction);
    SetUserAction(new EventAction(runAction));
}
FILE

# 5. PrimaryGeneratorAction.hh & .cc (Nguồn bức xạ Cs-137 hoặc Co-60)
cat << 'FILE' > "$PROJECT_DIR/include/PrimaryGeneratorAction.hh"
#ifndef PRIMARY_GENERATOR_ACTION_HH
#define PRIMARY_GENERATOR_ACTION_HH

#include "G4VUserPrimaryGeneratorAction.hh"
#include "G4ParticleGun.hh"

class PrimaryGeneratorAction : public G4VUserPrimaryGeneratorAction {
public:
    PrimaryGeneratorAction();
    ~PrimaryGeneratorAction() override;
    void GeneratePrimaries(G4Event* event) override;
private:
    G4ParticleGun* fParticleGun{nullptr};
};
#endif
FILE

cat << 'FILE' > "$PROJECT_DIR/src/PrimaryGeneratorAction.cc"
#include "PrimaryGeneratorAction.hh"
#include "G4ParticleTable.hh"
#include "G4SystemOfUnits.hh"

PrimaryGeneratorAction::PrimaryGeneratorAction() {
    fParticleGun = new G4ParticleGun(1);
    auto* particle = G4ParticleTable::GetParticleTable()->FindParticle("gamma");
    fParticleGun->SetParticleDefinition(particle);
    fParticleGun->SetParticleEnergy(661.7 * keV); // Cs-137 peak
    fParticleGun->SetParticlePosition(G4ThreeVector(0., 0., 0.));
    fParticleGun->SetParticleMomentumDirection(G4ThreeVector(0., 0., 1.));
}

PrimaryGeneratorAction::~PrimaryGeneratorAction() {
    delete fParticleGun;
}

void PrimaryGeneratorAction::GeneratePrimaries(G4Event* event) {
    fParticleGun->GeneratePrimaryVertex(event);
}
FILE

# 6. RunAction.hh & .cc (Ghi phổ ra ROOT và CSV)
cat << 'FILE' > "$PROJECT_DIR/include/RunAction.hh"
#ifndef RUN_ACTION_HH
#define RUN_ACTION_HH

#include "G4UserRunAction.hh"
#include "globals.hh"

class G4Run;

class RunAction : public G4UserRunAction {
public:
    RunAction();
    ~RunAction() override = default;
    void BeginOfRunAction(const G4Run*) override;
    void EndOfRunAction(const G4Run*) override;
};
#endif
FILE

cat << 'FILE' > "$PROJECT_DIR/src/RunAction.cc"
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
FILE

# 7. EventAction.hh & .cc
cat << 'FILE' > "$PROJECT_DIR/include/EventAction.hh"
#ifndef EVENT_ACTION_HH
#define EVENT_ACTION_HH

#include "G4UserEventAction.hh"
#include "globals.hh"

class RunAction;

class EventAction : public G4UserEventAction {
public:
    EventAction(RunAction* runAction);
    ~EventAction() override = default;
    void BeginOfEventAction(const G4Event*) override;
    void EndOfEventAction(const G4Event*) override;
private:
    G4int fCollID{-1};
};
#endif
FILE

cat << 'FILE' > "$PROJECT_DIR/src/EventAction.cc"
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
FILE

# 8. File Macro điều khiển
cat << 'FILE' > "$PROJECT_DIR/run.mac"
/run/initialize
/run/printProgress 10000
/run/beamOn 100000
FILE

cat << 'FILE' > "$PROJECT_DIR/init_vis.mac"
/control/verbose 1
/run/verbose 1
/vis/open OGL 600x600-0+0
/vis/drawVolume
/vis/viewer/set/viewpointVector 1 1 1
/vis/scene/add/trajectories smooth
/vis/scene/endOfEventAction accumulate
FILE

echo "========================================="
echo "Đã tạo xong trọn vẹn dự án tại: $PROJECT_DIR"
echo "========================================="
