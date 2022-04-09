clc;
clear;
close all;

% % load data from file
% load('raw data/raw.mat');
% 
% % table to double
% nomotion = table2array(nomotion);
% running = table2array(running);
% sitstand = table2array(sitstand);
% turnleft = table2array(turnleft);
% walking = table2array(walking);

% load data from csv
nomotion = csvread('raw data/0_nomotion.csv');
sitstand = csvread('raw data/1_sit&stand.csv');
walking = csvread('raw data/2_walking.csv');
running = csvread('raw data/3_running.csv');
turnleft = csvread('raw data/4_turnleft.csv');
turnright = csvread('raw data/5_turnright.csv');

% shuffle data by row
x_nomotion = nomotion(randperm(size(nomotion,1)),:);
x_sitstand = sitstand(randperm(size(sitstand,1)),:);
x_walking = walking(randperm(size(walking,1)),:);
x_running = running(randperm(size(running,1)),:);
x_turnleft = turnleft(randperm(size(turnleft,1)),:);
x_turnright = turnright(randperm(size(turnright,1)),:);

% gernerate labels
y_nomotion = 0 * ones(size(x_nomotion,1),1);
y_sitstand = 1 * ones(size(x_sitstand,1),1);
y_walking = 2 * ones(size(x_walking,1),1);
y_running = 3 * ones(size(x_running,1),1);
y_turnleft = 4 * ones(size(x_turnleft,1),1);
y_turnright = 5 * ones(size(x_turnright,1),1);

% concatenate data
x = [x_nomotion; x_running; x_sitstand; x_turnleft; x_walking; x_turnright];
y = [y_nomotion; y_running; y_sitstand; y_turnleft; y_walking; y_turnright];

% shuffle data by row
randoms= randperm(size(x,1));
x = x(randoms,:);
y = y(randoms,:);

% split data into training and testing
x_train = x(1:floor(size(x,1)*0.8),:);
y_train = y(1:floor(size(y,1)*0.8),:);
x_test = x(floor(size(x,1)*0.8)+1:end,:);
y_test = y(floor(size(y,1)*0.8)+1:end,:);

% save data to posture_6_data.mat
save('posture_6_data.mat','x_train','y_train','x_test','y_test');