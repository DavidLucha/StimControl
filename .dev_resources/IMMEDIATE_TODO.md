Non-laser room days:
String validation for readProtocol so you can (among other things) yell at people who put unnecessary brackets around the whole thing
DOCUMENTATION

**Fridays / Laser Room Days**
Configurable visualisation layout!!
- save preview plot settings to session params
- document them a non-coder is going to look at this and HATE it

Multi-saving is kiiinda fixed but its' still making a folder for the experiment and another one for _passive

Logic for not interrupting other sessions (taking over hardware) needs work

Logic for ending a session is a bit janky, creates bonus folders in the other direction now! (CameraComponent EndTrial specifically)

change errormsg function - put it somewhere else!

add time to daq channel names savings at start

check session params works (again)
add support for sub-targeting on DAQs (e.d. Widefield1-Trigger) - SHELVED. TOO HARD.

DAQs sometimes not stopping automatically: Internal Error: The hardware did not report that it had stopped before the timer ran out
TRAGICALLY I THINK THIS IS A FIRMWARE THING https://au.mathworks.com/matlabcentral/answers/90747-how-to-avoid-timeout-waiting-for-obj-to-stop 

https://au.mathworks.com/matlabcentral/answers/1989893-timeout-expired-before-operation-completed

Warning: Error occurred while executing the listener callback for event Custom
defined for class matlabshared.asyncio.internal.Channel:
Error using daq.internal.BaseClass/localizedError
Internal Error: Unexpected operation processHardwareStop occurred in state
AcquiredDataWaiting.


Cameras sometimes not having enough physical memory - fixed??
cameras saving a weird number of things - fixed??
- fix the over-saving bug (I think done but test)
- dry runs and stress testing (done?)
QST multi-stim stuff?


**CLARISSA NOTES**
post-trial summary of relevant data: frames sent vs frames received?
** A WARNING IF THEY DON'T MATCH

**Phill Notes (more for laser room)**
Phill feedback
- SUPER high latency when switching camera trigger modes to configure values (and really easy to fuck up & break if you don't know the idiosyncracies)
- don't allow trying to change trigger mode while running! I thought we were automatically changing that but apparently not
- make previews invisible when not previewing (e.g. on load)
- fix the auto layout, make preview frames selectable
- maybe make stop not clickable during trial? - stop doesn't work when the timer isn't working!! This is a problem!
- cameras are not loading exposure time from devices
- widefield trigger assigning past length of stim
- get rid of text overlay when hardware trigger is receiving frames?
- logic when running? Counting up in double negatives instead of down
- streamline setup on new computer with no presets (AND SAVING)
- remove selected colour when changing to session tag
- BUG DISCOVERED: cameras continually sending the same image after 5 trials of 3529 images each, 1min 60fps 10sec off
-reduce latency of preview - manually only plot every 10th frame instead of using library startpreview() - or look into config for this that only plots every xth frame ? Also the preview is stopping sometimes and the whole process is pretty intensive computationally.

