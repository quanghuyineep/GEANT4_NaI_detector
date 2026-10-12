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
