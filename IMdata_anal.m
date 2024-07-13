%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code created by SeungYun Han on Feb 1, 2024
% For correcting the image shift of Peng's IMdata.mat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load('IMdata.mat')

I = abs(output).^2;

% Set target range
center = [300 300]; hw = 200; % half width
range_x = center(1)-hw:center(1)+hw;
range_y = center(2)-hw:center(2)+hw;

% Intensities at the target region
A0 = I;
A = I(range_x, range_y);
B = I_m(range_x, range_y);


% Target region intensity
figure(1)
imagesc(B), rec, colorbar
title('Measured')


fprintf('Correlation before shift correction: %f\n', corr2(A, B))

% Get shift correction
Ashift = ShiftFind2(A0, B, range_x, range_y);

% Target region intensity
figure(2)
imagesc(Ashift), rec, colorbar
title('Using TM, shift corrected')

fprintf('Correlation after shift correction: %f\n', corr2(Ashift,B))


function rec
daspect([1 1 1]);
end
