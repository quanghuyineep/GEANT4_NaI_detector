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
