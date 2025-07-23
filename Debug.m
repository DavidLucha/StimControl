function [p, g, cam, d] = Debug()
%DEBUG Summary of this function goes here
%   Detailed explanation goes here
baseDir = [pwd filesep 'StimControl'];
protocolPath = [baseDir filesep 'protocolfiles' filesep 'TempandVibe.stim'];
hardwareParamPath = [baseDir filesep 'paramfiles' filesep 'HardwareParams.json'];
daqConfigPath = [baseDir filesep 'paramfiles' filesep 'Default_OuterLab_DaqChanParams.csv'];

[p, g] = readProtocol(protocolPath);
objs = readHardwareParams(hardwareParamPath);
cam = objs.camera1;
d = objs.daq1;
d.Configure('ChannelConfig', daqConfigPath);
%PHYSICAL WIRE CONNECTIONS:
% camera pin 1 (internal line 3) mapped to DAQ DP0/line3
% camera pin 3 (internal line 4) mapped to DAQ DP0/line2
% DAQ DP0/line4 mapped to servo GPIO
% servo datasheet: https://docs.rs-online.com/0e85/0900766b8123f8d7.pdf / https://au.rs-online.com/web/p/servo-motors/7813058?srsltid=AfmBOopKocPD062pUHUuFPPraNo7g-xsPgzbgYuBNcmzeX2-aAlwksn6
% DAQ datasheet: https://www.ni.com/docs/en-US/bundle/usb-6001-specs/resource/374369a.pdf 
% camera datasheet: https://docs.baslerweb.com/aca1440-220um 
end

