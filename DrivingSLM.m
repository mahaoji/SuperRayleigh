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

%% generate different pattern
data = uint8(128*ones(2160,3480));

%% continued
handle = heds_load_data(data);
% Wait for the data to be processed internally to speed up the heds_show_datahandle(handle) call later:
heds_datahandle_waitfor(handle.id, heds_state.ReadyToRender);
% Make the data without overlay visible on SLM screen:
heds_show_datahandle(handle.id);
% Wait 2 seconds until we apply the beam manipulation to make the uploaded data visible first:
heds_utils_wait_s(2.0);


% Please uncomment to close SDK at the end:
heds_utils_wait_s(2.0);
heds_slm_close


