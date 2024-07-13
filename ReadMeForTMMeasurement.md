## TM measurement
this is used for transmission matrix measurement

### step 1 Creates streaks on the SLM
run line 1-57&106-138 in **Step1TMMeasurement.m** 

this will creats streaks on the SLM,and it will focus on the Fourier plane

you can change the variable in line 131 for different streaks
```
data = uint8(SLM.background);
```

### step 2 adjust camera by **ThorCam**
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

#### adjust camera place to the fourier plane


### step 3 close SLM in matlab;close Thorlab software
run line 351-352 in **Step1TMMeasurement.m** 
```
heds_utils_wait_s(2.0);
heds_slm_close;
```
close ThorCam window handly

### step 4 adjust ROI
change dim,X1,Y1 measured in step 2

line 5-11 in **Step1TMMeasurement.m** , **Step3TestIM.m** and **Step4ApplySuperRayleighPhase.m**
```
in pixH = 2048; % number of pixels of the camera,
pixV = 2448;
dim=700;%The dimensions the shot must have
X1=700;%the starting X in the region of interest
Y1=580;%The starting Y in the region of interest

nAve=40;    % number of frames for camera average 
```
### step 5 Measurement
close all lights and screens in the room 

run **Step1OverallControl.m**

it will last for hours 
### step 6 TM post processing and analyse it
run **Step2TMPostProcessing.m** to average the TM measured and get TM

run **Step3TestIM.m** to check the TM_filt;normally the correlation is (0.9,1)





