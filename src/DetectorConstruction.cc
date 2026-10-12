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

// Cây cấu trúc liên kết của 6 đối tượng trong bộ nhớ
// [solidWorld] + [worldMat] ──> [logicWorld] ──> [physWorld] (Root Node)
//                                     │
//                                     └── (Chứa thể tích con)
//                                             │
// [solidNaI]   + [naiMat]   ──> [logicNaI]   ──> [PhysNaI] (Daughter Node)

G4VPhysicalVolume* DetectorConstruction::Construct() {
    auto* nist = G4NistManager::Instance();

    // World
    auto* worldMat = nist->FindOrBuildMaterial("G4_AIR");
    auto* solidWorld = new G4Box("SolidWorld", 0.5*m, 0.5*m, 0.5*m);
    auto* logicWorld = new G4LogicalVolume(solidWorld, worldMat, "LogicWorld");
    auto* physWorld = new G4PVPlacement(nullptr, G4ThreeVector(), logicWorld, "PhysWorld", nullptr, false, 0, true);

    // NaI Crystal (2" x 2" cylinder)
    auto* naiMat = nist->FindOrBuildMaterial("G4_SODIUM_IODIDE");
    auto* solidNaI = new G4Tubs("SolidNaI", 0.*cm, 2.54*cm, 2.54*cm, 0.*deg, 360.*deg);
    auto* logicNaI = new G4LogicalVolume(solidNaI, naiMat, "LogicNaI");
    new G4PVPlacement(nullptr, G4ThreeVector(0, 0, 10.*cm), logicNaI, "PhysNaI", logicWorld, false, 0, true);

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
