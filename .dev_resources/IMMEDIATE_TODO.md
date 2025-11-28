

**Non-laser room days**
String validation for readProtocol so you can (among other things) yell at people who put unnecessary brackets around the whole thing

**Fridays / Laser Room Days**
VALIDATION FOR PROTOCOL FILES

Configurable visualisation layout!!
- document them a non-coder is going to look at this and HATE it

add support for sub-targeting on DAQs (e.d. Widefield1-Trigger) - SHELVED. TOO HARD.

**CLARISSA NOTES**
post-trial summary of relevant data: frames sent vs frames received?
** A WARNING IF THEY DON'T MATCH

**Phill Notes (more for laser room)**
Phill feedback
- SUPER high latency when switching camera trigger modes to configure values (and really easy to fuck up & break if you don't know the idiosyncracies)
- don't allow trying to change trigger mode while running! I thought we were automatically changing that but apparently not
- make previews invisible when not previewing (e.g. on load)
- maybe make stop not clickable during trial? - stop doesn't work when the timer isn't working!! This is a problem!
- streamline setup on new computer with no presets (AND SAVING)

### Code Cleanup
- [ ] move ComponentID to ComponentProperties with generator function
- [ ] add [progress bar](https://au.mathworks.com/help/matlab/ref/uiprogressdlg.html) to loading screens?
- [ ] go through all the TODOs and get rid of commented code