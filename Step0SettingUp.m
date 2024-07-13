pixH = 2048; % number of pixels of the camera,
pixV = 2448;
dim=199;%The dimensions the shot must have
X1=145;%179; %173;%45;%the starting X in the region of interest
Y1=125;%137;%40;%The starting Y in the region of interest

nAve=40;    % number of frames for camera average

%% initial SLM
SLM.Nx=3840; % horizontal
SLM.Ny=2160; % vertical
SLM.fringe = 4;         % fringe period for 1st order diffraction
SLM.fringe_updown = 2;  % fringe period for diffracting away other terms
SLM.MpxNum=32;  % Macropixel number at one side
SLM.MpxSize=64; % Macropixel size (=2*fringe_dx or dy)

SLM.up_length=56;       %(2160-32*64)/2
SLM.down_length=56;     %(2160-32*64)/2
SLM.left_length=896;    %(3840-32*64)/2
SLM.right_length=896;   %(3840-32*64)/2
SLM.pitch_size = 64;   %the macro pixel pitch size
SLM.two_pi= 255; %The measure value of 2pi

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

data = uint8(SLM.background);
handle = heds_load_data(data);
% Wait for the data to be processed internally to speed up the heds_show_datahandle(handle) call later:
heds_datahandle_waitfor(handle.id, heds_state.ReadyToRender);
% Make the data without overlay visible on SLM screen:
heds_show_datahandle(handle.id);
% Wait 2 seconds until we apply the beam manipulation to make the uploaded data visible first:
heds_utils_wait_s(1.0);


%%

N = SLM.MpxNum;
% Set the pattern on SLM
A = rand(SLM.MpxNum,SLM.MpxNum);    % the pattern we want
SLM.pattern(SLM.range_y, SLM.range_x) = round(mod(SLM.background(SLM.range_y, SLM.range_x)+SLM.two_pi*kron(A,SLM.Mpx),SLM.two_pi));

data = uint8(SLM.pattern);
handle = heds_load_data(data);
% Wait for the data to be processed internally to speed up the heds_show_datahandle(handle) call later:
heds_datahandle_waitfor(handle.id, heds_state.ReadyToRender);
% Make the data without overlay visible on SLM screen:
heds_show_datahandle(handle.id);
% Wait 2 seconds until we apply the beam manipulation to make the uploaded data visible first:
heds_utils_wait_s(2.0);


%% Close SLM and camera
% Please uncomment to close SDK at the end:
heds_utils_wait_s(2.0);
heds_slm_close



