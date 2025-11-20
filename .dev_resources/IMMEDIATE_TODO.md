
Configurable visualisation layout!!
- save preview plot settings to session params
- document them a non-coder is going to look at this and HATE it

Multi-saving is kiiinda fixed but its' still making a folder for the experiment and another one for _passive
Start passive isn't available until you pick a protocl, but picking a protocol where some of the harware isn't connected throws an error. Make it finish failing to load and then enable start passive.

Logic for not interrupting other sessions needs work

Logic for ending a session is a bit janky, creates bonus folders in the other direction now! (CameraComponent EndTrial specifically)

change errormsg function - put it somewhere else!

add time to daq channel names savings at start

check session params works (again)
add support for sub-targeting on DAQs (e.d. Widefield1-Trigger)


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

