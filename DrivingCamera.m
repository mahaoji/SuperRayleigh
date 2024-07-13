
% Load TLCamera DotNet assembly. The assembly .dll is assumed to be in the 
% same folder as the scripts.
NET.addAssembly([pwd, '\Thorlabs.TSI.TLCamera.dll']);
disp('Dot NET assembly loaded.');
tlCameraSDK = Thorlabs.TSI.TLCamera.TLCameraSDK.OpenTLCameraSDK;
% Get serial numbers of connected TLCameras.
serialNumbers = tlCameraSDK.DiscoverAvailableCameras;
disp([num2str(serialNumbers.Count), ' camera was discovered.']);


%%

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
tlCamera.ExposureTime_us = 5000; % 5 ms
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

%% Shoot a picture
picCount = 10000;
for ii = 1:picCount
    % Each call to Start sends a software trigger.
    tlCamera.IssueSoftwareTrigger;
    
    % Wait for image buffer to be filled to prevent sending too many
    % software triggers.
    while (tlCamera.NumberOfQueuedFrames == 0)
        pause(0.01);
    end
    
    % If data processing in Matlab falls behind camera image
    % acquisition, the FIFO image frame buffer could be filled up, 
    % which would result in missed frames.
    if (tlCamera.NumberOfQueuedFrames > 1)
        disp(['Data processing falling behind acquisition. ' num2str(tlCamera.NumberOfQueuedFrames) ' remains']);
    end
    
    % Get the pending image frame. 
    imageFrame = tlCamera.GetPendingFrameOrNull;
    if ~isempty(imageFrame)
        frameCount = frameCount + 1;
        % For color images, the image data is in BGR format.
        imageData = imageFrame.ImageData.ImageData_monoOrBGR;
    
        disp(['Image frame number: ' num2str(imageFrame.FrameNumber)]);
    
        % TODO: custom image processing code goes here
        imageHeight = imageFrame.ImageData.Height_pixels;
        imageWidth = imageFrame.ImageData.Width_pixels;
        bitDepth = imageFrame.ImageData.BitDepth;
        maxOutput = uint16(2^bitDepth - 1);
            
        % Allocate memory for processed Intensity image output.
        outputIntensityData = NET.createArray('System.UInt16',imageHeight * imageWidth);
        % Calculate the Intensity image.
        polarizationProcessor.TransformToIntensity(polarPhase, imageData, int32(0), int32(0), imageWidth, imageHeight, ...
            bitDepth, maxOutput, outputIntensityData);
        % Display the Intensity image
        imageIntensity2D = reshape(uint16(outputIntensityData), [imageWidth, imageHeight]);
        IMData = imageIntensity2D';
        
        figure(1);title(['Intensity image. Optimization Step' int2str(frameCount)]);                    
        imagesc(IMData), colormap(gray), colorbar, axis image;
        % IM = uint8(255*double(IMData)/4095);
        % imwrite(IM,['DataSave\data_' int2str(Ind1) '_' int2str(Ind2) '_' int2str(Ind3) '_' int2str(Ind4) '_' int2str(Ind5) '.png']);
    end
end

%% exit the camera

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

