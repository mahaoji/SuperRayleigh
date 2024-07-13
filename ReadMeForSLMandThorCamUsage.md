this is for driving SLM to creat rayleigh speckles and driving camera to take photos
### step 1 open SLM
**Step1TMMeasurement.m** line 13-57& 106-147.After step 1 ,you can preview SLM phases on **SLM Display SDK**  
![alt text](/images/image.png)
### step 2 display other phases
load **/0619/PhaseMask_order-n.... .m** reyleigh phases files

run line147-159 in **Step4ApplySuperRayleighPhase.m** to change the phase 
```
test_pattern = SLMphase(:,:,50);%!!!!!!!!!!!!!!!!!!!!
% Measured on camera
SLM.pattern(SLM.range_y, SLM.range_x) = round(mod(SLM.background(SLM.range_y, SLM.range_x)+SLM.two_pi*kron(test_pattern,SLM.Mpx),SLM.two_pi));
% A = rand(N,N);
% SLM = SetSLM(SLM, A);
data = uint8(SLM.pattern);
handle = heds_load_data(data);
% Wait for the data to be processed internally to speed up the heds_show_datahandle(handle) call later:
heds_datahandle_waitfor(handle.id, heds_state.ReadyToRender);
% Make the data without overlay visible on SLM screen:
heds_show_datahandle(handle.id);
% Wait 2 seconds until we apply the beam manipulation to make the uploaded data visible first:
heds_utils_wait_s(2.0);
```
### step 3 adjust camera by **ThorCam**
![alt text](/images/image-1.png)
![alt text](/images/image-2.png)
#### adjust Exposure time 
![](/images/image-4.png)
#### save image handly
![alt text](/images/image-5.png)

then check it in matlab ,make sure not over exposured.check the colorbar: if it is range(1,4096) the image is over exposured. 
```
img=imread('test.tif');
figure;imagesc(img);
```
Find the speckle in the image and its position. take down X Y and W H
![alt text](/images/image-6.png)
### step 4 save image by code
close the ThorCam first.
#### init camera in matlab.
line 58-104 in **Step1TMMeasurement.m**
```
% Load TLCamera DotNet assembly. The assembly .dll is assumed to be in the 
% same folder as the scripts.
NET.addAssembly([pwd, '\Thorlabs.TSI.TLCamera.dll']);
disp('Dot NET assembly loaded.');
tlCameraSDK = Thorlabs.TSI.TLCamera.TLCameraSDK.OpenTLCameraSDK;
% Get serial numbers of connected TLCameras.
serialNumbers = tlCameraSDK.DiscoverAvailableCameras;
disp([num2str(serialNumbers.Count), ' camera was discovered.']);

% Open the first TLCamera using the serial number.
disp('Opening the first camera')
tlCamera = tlCameraSDK.OpenCamera(serialNumbers.Item(0), false);
% Check if the camera is Polarization camera.
cameraSensorType = tlCamera.CameraSensorType;
isPolarizationCamera = cameraSensorType == Thorlabs.TSI.TLCameraInterfaces.CameraSensorType.MonochromePolarized;
if (isPolarizationCamera)
    % Load polarization processing .NET assemblies
    NET.addAssembly([pwd, '\Thorlabs.TSI.PolarizationProcessor.dll']); 
    % Create polarization processor SDK.
    polarizationProcessorSDK = Thorlabs.TSI.PolarizationProcessor.PolarizationProcessorSDK;
    % Create polarization processor
    polarizationProcessor = polarizationProcessorSDK.CreatePolarizationProcessor;
    % Query the polar phase of the camera.
    polarPhase = tlCamera.PolarPhase;
end

% Set exposure time and gain of the camera.
tlCamera.ExposureTime_us = 3000; % 5 ms
% Set the FIFO frame buffer size. Default size is 1. 
tlCamera.MaximumNumberOfFramesToQueue = 5;

figure(1)

% Start software triggered image acquisition
disp('Starting software triggered image acquisition.');

% Set the number of frames per software trigger and start trigger
% acquisition
tlCamera.OperationMode = Thorlabs.TSI.TLCameraInterfaces.OperationMode.SoftwareTriggered;
tlCamera.FramesPerTrigger_zeroForUnlimited = 1;
tlCamera.Arm;
maxPixelValue = double(2^tlCamera.BitDepth - 1);
numberOfFramesToAcquire = 2;    
frameCount = 0;
```
#### change the ROI
change dim,X1,Y1 measured in step 3

line 5-11 in **Step1TMMeasurement.m**
```
in pixH = 2048; % number of pixels of the camera,
pixV = 2448;
dim=700;%The dimensions the shot must have
X1=700;%the starting X in the region of interest
Y1=580;%The starting Y in the region of interest

nAve=40;    % number of frames for camera average 
```
#### get image
run line160-163 in **Step4ApplySuperRayleighPhase.m** to change
```
IMDataTemp = photoShoot(tlCamera,polarizationProcessor,polarPhase);
IMDataTemp2 = IMDataTemp(Y1:Y1+dim-1,X1:X1+dim-1)-bgIM;
IMDataTemp2(IMDataTemp2<0) = 0;
I_m = IMDataTemp2;
```
### step 5 close SLM and Camera in matlab
run line 349-366 in **Step1TMMeasurement.m**
```
%% Close SLM and camera
% Please uncomment to close SDK at the end:
heds_utils_wait_s(2.0);
heds_slm_close

% Close camera
tlCamera.Disarm;
% Release the TLCamera
disp('Releasing the camera');clc
tlCamera.Dispose;
delete(tlCamera);

% Release the serial numbers
delete(serialNumbers);

% Release the TLCameraSDK.
tlCameraSDK.Dispose;
delete(tlCameraSDK);
```