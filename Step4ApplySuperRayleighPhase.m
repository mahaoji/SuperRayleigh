pixH = 2048; % number of pixels of the camera,
pixV = 2448;
dim=750;%The dimensions the shot must have
X1=1280;%the starting X in the region of interest
Y1=780;%The starting Y in the region of interest

nAve=20;    % number of frames for camera average

%% initial SLM
SLM.Nx=3840; % horizontal
SLM.Ny=2160; % vertical
SLM.fringe = 4;         % fringe period for 1st order diffraction
SLM.fringe_updown = 2;  % fringe period for diffracting away other terms
SLM.MpxNum=32;  % Macropixel number at one side
SLM.MpxSize=64; % Macropixel size (=2*fringe_dx or dy)
N = SLM.MpxNum;
SLM.up_length=56;       %(2160-32*64)/2
SLM.down_length=56;     %(2160-32*64)/2
SLM.left_length=896;    %(3840-32*64)/2
SLM.right_length=896;   %(3840-32*64)/2
SLM.pitch_size = 64;   %the macro pixel pitch size
SLM.two_pi= 147; %The measure value of 2pi

SLM.Mpx = ones(SLM.MpxSize,SLM.MpxSize);    % Macropixel pattern

% Diffract away other background region
A = ones(SLM.Ny/SLM.fringe_updown/2,1);
B = ones(SLM.fringe_updown*2, SLM.Nx);
B(1:end/2,:) = 0;
SLM.background = zeros(SLM.Ny, SLM.Nx);
SLM.background = round(SLM.two_pi/2*kron(A,B));
SLM.Phase_corr = zeros(size(SLM.background)); % If don't want to correct

center = [0,0];
SLM.center = center;
SLM.range_x = (SLM.left_length+1:SLM.Nx-SLM.right_length) + SLM.center(2);
SLM.range_y = (SLM.up_length+1:SLM.Ny-SLM.down_length) + SLM.center(1);

SLM.background = round(mod(SLM.background + double(SLM.Phase_corr), SLM.two_pi));
SLM.background00 = SLM.background;
% SLM.background = mod(SLM.background + ab_corr, SLM.two_pi); % Add Zernike
SLM.background0 = SLM.background;   % save for later
SLM.pattern = SLM.background;       % initialize SLM pattern

% Set diffraction grating for 1st order
A = ones(SLM.MpxNum,SLM.MpxNum*SLM.MpxSize/SLM.fringe/2);
B = ones(SLM.MpxSize,SLM.fringe*2);
B(:,1:end/2) = 0;
SLM.background(SLM.range_y,SLM.range_x) = round(SLM.two_pi/2*kron(A,B));
SLM.background(SLM.range_y,SLM.range_x) = mod(SLM.background(SLM.range_y,SLM.range_x)...
    + double(SLM.Phase_corr(SLM.range_y,SLM.range_x-4)), SLM.two_pi);
% SLM.background = mod(SLM.background + ab_corr, SLM.two_pi);

%% Initial Camera

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
tlCamera.ExposureTime_us = 1000; % 5 ms
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


%% Driving the SLM
% Uses the built-in function to prepare the SLM.
% Import SDK:
add_heds_path;
% Check if the installed SDK supports the required API version
heds_requires_version(5);
% Make some enumerations available locally to avoid too much code:
heds_types;
% Detect SLMs and open a window on the selected SLM:
heds_slm_init;
% Open the SLM preview window in non-scaled mode:
% This might have an impact on performance, especially in "Capture SLM screen" mode.
% Please adapt the file show_slm_preview.m if preview window is not at the right position or even not visible.
% show_slm_preview(0.0, heds_slmpreview_flags.ShowZernikeRadius);

% Show image file data on SLM:
% filename = ['C:\Users\DynamicRM\Desktop\PhaseLockingProject\GrayMirrorUniform.png'];
% Configure beam manipulation in physical units:
wavelength_nm = 632.7;  % wavelength of incident laser light
% steering_angle_x_deg = 0;
% steering_angle_y_deg = 0;
% focal_length_mm = 200; % No use in this code
%         heds_show_data_fromfile(filename);
% handle = heds_load_data_fromfile(filename);

data = uint8(SLM.background0);
handle = heds_load_data(data);
% Wait for the data to be processed internally to speed up the heds_show_datahandle(handle) call later:
heds_datahandle_waitfor(handle.id, heds_state.ReadyToRender);
% Make the data without overlay visible on SLM screen:
heds_show_datahandle(handle.id);
% Wait 2 seconds until we apply the beam manipulation to make the uploaded data visible first:
heds_utils_wait_s(1.0);

% Record the background image

IMDataTemp =  photoShoot(tlCamera,polarizationProcessor,polarPhase);
bgIM = IMDataTemp(Y1:Y1+dim-1,X1:X1+dim-1);
figure(1);title(['Intensity image. Optimization Step' int2str(frameCount)]);                    
        imagesc(bgIM), colormap(gray), colorbar, axis image;
cam.bg = bgIM;


%% Test TM
% load('test_pattern.mat');
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
%%
IMDataTemp = photoShoot(tlCamera,polarizationProcessor,polarPhase);
IMDataTemp2 = IMDataTemp(Y1:Y1+dim-1,X1:X1+dim-1)-bgIM;
IMDataTemp2(IMDataTemp2<0) = 0;
I_m = IMDataTemp2;
figure(2);title(['Test TM image.']);                    
        imagesc(IMDataTemp2), colormap(gray), colorbar, axis image;

        
%% Using TM
input = exp(complex(0,2*pi*test_pattern)); %A
input = reshape(input', [N^2, 1]);
output = TM_filt*input;
output = reshape(output, [dim, dim])';

figure(3), 
subplot(121), imagesc(I_m); title('Measured'); axis image;
% caxis([0 4096])
subplot(122), imagesc((abs(output).^2)); title('Using TM'); axis image;
% caxis([0 4096])
corr2(I_m,abs(output).^2)

%% Save test pattern for reference

% save(['measurement\Im_' datestr(datetime, 'mmddyy_HHMMSS') '.mat'],'I_m');


%% Close SLM and camera
% Please uncomment to close SDK at the end:
heds_utils_wait_s(2.0);
heds_slm_close

% Close camera
tlCamera.Disarm;
% Release the TLCamera
disp('Releasing the camera');
tlCamera.Dispose;
delete(tlCamera);

% Release the serial numbers
delete(serialNumbers);

% Release the TLCameraSDK.
tlCameraSDK.Dispose;
delete(tlCameraSDK);

%% function and utilities

function IMData = photoShoot(tlCamera,polarizationProcessor,polarPhase)

    picCount = 20;
    IMData = zeros(2048,2448);
    for ii = 1:picCount
        % Each call to Start sends a software trigger.
        tlCamera.IssueSoftwareTrigger;
        % Wait for image buffer to be filled to prevent sending too many
        % software triggers.
        while (tlCamera.NumberOfQueuedFrames == 0)
            pause(0.01);
            tlCamera.IssueSoftwareTrigger;
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
            % For color images, the image data is in BGR format.
            imageData = imageFrame.ImageData.ImageData_monoOrBGR;
            % disp(['Image frame number: ' num2str(imageFrame.FrameNumber)]);
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
            TempData = imageIntensity2D';
            IMData = IMData + double(TempData);
            
        end
    end
    IMData = IMData/picCount;
end
