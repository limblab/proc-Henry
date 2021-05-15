function peri_event_raster_and_hist(dataset, params, unit_num, y_lim_hist)
%------- Inputs ---------
% dataset: the data structure containing the neural data and trial
% information

% params: parameters for plotting and calculating

% unit_num: the number of the unit needing to analyze. The program can
% identify the type of this input arg, and determine what to do based on
% the type information. This arg can be either a number or a char string

% y_lim_hist: if given, the y-limit of the histogram plot will be set

%------------------------
% Setting the title of the figure
%------------------------
title_str = struct(...
    'condition', '',...
    'cue', '',...
    'condition_type', '');
%------------------------
% Parsing the params for calculating and plotting
%------------------------    
event = params.event;
condition_type = params.condition_type;
condition = params.condition;
trial_num = params.trial_num;
before_event = params.before_event;
after_event = params.after_event;
bin_size = params.bin_size;

%------------------------
% Reading the spike timings from the dataset
%------------------------    
if strcmp(class(unit_num), 'char') == 0 % if unit_num is a number
   spikes = dataset.spikes{1, unit_num};
else  % if unit_num is a char string, like 'elec75_1'
    existence = strfind(dataset.unit_names, unit_num);
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
        spikes = dataset.spikes{1, k};
    end
end

%------------------------
% Finding the indices of trials with the specified condition
%------------------------    
if strcmp(condition_type, 'target_dir')
    trial_idx = find((dataset.trial_target_dir == condition)&...
        (dataset.trial_result == 'R'));% Only including successful trials
    title_str.condition_type = 'target direction at';
    title_str.condition = strcat(string(condition), '\circ');
elseif strcmp(condition_type, 'target_center_x')||strcmp(condition_type, 'target_center_y')
    idx_in_table = find(contains(dataset.trial_info_table_header, 'tgtCenter')|...
                        contains(dataset.trial_info_table_header, 'tgtCtr'));
    target_centers = dataset.trial_info_table(:, idx_in_table);
    target_centers_x = zeros(length(target_centers), 1);
    target_centers_y = zeros(length(target_centers), 1);
    for i = 1:length(target_centers)
        target_centers_x(i, 1) = target_centers{i}(1);
        target_centers_y(i, 1) = target_centers{i}(2);
    end
    if strcmp(condition_type, 'target_center_x')
        trial_idx = find((target_centers_x == condition)&...
             (dataset.trial_result == 'R'));
        title_str.condition_type = 'target center X at';
        title_str.condition = string(condition);
    elseif strcmp(condition_type, 'target_center_y')
        trial_idx = find((target_centers_y == condition)&...
             (dataset.trial_result == 'R'));
        title_str.condition_type = 'target center Y at';
        title_str.condition = string(condition);
    end
end
%------------------------
% Picking the timings for the events to be aligned
%------------------------    
if strcmp(event, 'trial_start')
    event_time = dataset.trial_start_time(trial_idx);
    title_str.cue = 'start';
elseif strcmp(event, 'trial_end')
    event_time = dataset.trial_end_time(trial_idx);
    title_str.cue = 'end';
elseif strcmp(event, 'trial_gocue')
    event_time = dataset.trial_gocue_time(trial_idx);
    title_str.cue = 'gocue';
end

t = event_time(1:trial_num);
t1 = t - before_event; 
t2 = t + after_event;

% Getting the spike timestamps based on the behavior timings above
trial_spike = struct([]);
for i = 1:length(t)
    trial_spike{i, 1} = spikes(find((spikes>t1(i))&(spikes<t2(i))));
end

figure
% Plotting peri-event rasters on the upper pannel of the the figure
subplot(211);
for i = 1:length(trial_spike)
    plot(trial_spike{i, 1} - t(i), ones(1, length(trial_spike{i, 1}))*i,... 
    'marker', '|', 'color', 'k', 'linestyle', 'none');
    hold on
end
xlim([-before_event, after_event]);
ylim([0, trial_num+1])
ylims = ylim;
title(join([dataset.unit_names{k}, ', aligned with ', title_str.cue, ', ', ...
      title_str.condition_type, title_str.condition]), 'fontsize', 12);
line([0, 0], [ylims(1), ylims(2)], 'linewidth', 2, 'color', 'blue');
axis off

n_bins = round((after_event + before_event)/bin_size);
hists = zeros(length(trial_spike), n_bins);
for i = 1:length(trial_spike)
    [hists(i, :), edges] = histcounts(trial_spike{i, 1}, n_bins);
end
avg_hists = mean(hists, 1)/bin_size;

% Plotting peri-event histogram on the lower pannel of the figure
subplot(212)
time = -before_event:bin_size:after_event;
time = time(1:end-1) + bin_size/2;
if strcmp(params.hist_plot_type, 'bar')
    bar(time, avg_hists);
elseif strcmp(params.hist_plot_type, 'line')
    plot(time, avg_hists, 'linewidth', 2)
end
ylabel('Firing rate (Hz)', 'fontsize', 12);
xlabel('Time', 'fontsize', 12);
xlim([-before_event, after_event]);
if nargin > 3
    ylim([0, y_lim_hist])
end
box off


    







