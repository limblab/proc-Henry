%% First, load a pair of data files
clc
clear
% Load the pre-Cypro file
load('E:\data\Groot_WM\20210402\sorted\20210402_Groot_preCypro_WM_002-01.mat');
preCypro_xds = xds;
clear xds
% Load the post-Cypro file
load('E:\data\Groot_WM\20210402\sorted\20210402_Groot_postCypro_WM001-01.mat');
postCypro_xds = xds;
clear xds
%% Second, print the target centers, in order to have an idea about what to specify later
[pre_target_centers_x, pre_target_centers_y] = get_target_centers(preCypro_xds);
[post_target_centers_x, post_target_centers_y] = get_target_centers(postCypro_xds);
disp('Please take a look at the returned variables in Workspace!');
%% Third, list all the unit names in a variable in Workspace, to get an idea about what we have in both files
disp('Check the variable preCypro_unit_names in Workspace!');
preCypro_unit_names = preCypro_xds.unit_names;

disp('Check the variable postCypro_unit_names in Workspace!');
postCypro_unit_names = postCypro_xds.unit_names;
%% Fourth, do PSTH plots with the preCypro file
% Set up params for the preCypro file
params = struct( ...
    'event','trial_gocue', ...
    'condition_type','target_center_x', ...
    'condition', -4.5, ...
    'trial_num',11, ...
    'before_event',0.2, ...
    'after_event',1, ...
    'bin_size',0.05, ...
    'hist_plot_type', 'line');

unit_name = 'elec62_1';
k = find_unit_in_xds(preCypro_xds, unit_name);
if isempty(k) == 1
    disp('Cannot find the unit with the given unit_name.')
else
    disp('Good to go!')
end
peri_event_raster_and_hist(preCypro_xds, params, unit_name, 100)
%% Fifth, do PSTH plots with the postCypro file
% Set up params for the postCypro file
params = struct( ...
    'event','trial_gocue', ...
    'condition_type','target_center_x', ...
    'condition', -5, ...
    'trial_num',11, ...
    'before_event',0.2, ...
    'after_event',1, ...
    'bin_size',0.05, ...
    'hist_plot_type', 'line');

unit_name = 'elec62_1';
k = find_unit_in_xds(postCypro_xds, unit_name);
if isempty(k) == 1
    disp('Cannot find the unit with the given unit_name.')
else
    disp('Good to go!')
end
peri_event_raster_and_hist(postCypro_xds, params, unit_name, 100)

%%
function [target_centers_x, target_centers_y] = get_target_centers(dataset)
idx_in_table = find(contains(dataset.trial_info_table_header, 'tgtCenter')|...
                        contains(dataset.trial_info_table_header, 'tgtCtr'));
target_centers = dataset.trial_info_table(:, idx_in_table);
target_centers_x = zeros(length(target_centers), 1);
target_centers_y = zeros(length(target_centers), 1);
for i = 1:length(target_centers)
    target_centers_x(i, 1) = target_centers{i}(1);
    target_centers_y(i, 1) = target_centers{i}(2);
end
end

function k = find_unit_in_xds(dataset, unit_name)
existence = strfind(dataset.unit_names, unit_name);
for i = 1:length(existence)
    if isempty(existence{i}) == 1
        temp(i) = 0;
    elseif existence{i} == 1
        temp(i) = 1;
    end
end
k = find(temp == 1);
if length(k) == 0
    error('Cannot find the unit with the given label in this file.');
else
    disp(k);
end
end