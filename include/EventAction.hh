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
