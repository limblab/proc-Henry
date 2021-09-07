#%% Load one file and do pre-processing
import numpy as np
import fnmatch, os
from xds import lab_data_DSPW_EMG
import pickle

base_path = 'H:/Pop_drug/20210902/WS/'
baseline_file = 'Pop_20210902_WS_baseline_001.pkl'
noon_file = 'Pop_20210902_WS_post_lex_001.pkl'

with open ( base_path + baseline_file, 'rb' ) as fp:
    baseline = pickle.load(fp)
with open ( base_path + noon_file, 'rb' ) as fp:
    noon = pickle.load(fp)    

EMG_names = baseline.EMG_names
    
bin_size = 0.025 # Change the bin size here
smooth_size = 0.05 # Change the smooth window size here

baseline.update_bin_data(bin_size)  
baseline.smooth_binned_spikes(bin_size, 'gaussian', smooth_size)

noon.update_bin_data(bin_size)  
noon.smooth_binned_spikes(bin_size, 'gaussian', smooth_size)

# Getting the data in trials
baseline_spike = baseline.get_trials_data_spike_counts('R', 'gocue_time', 0.5, 'gocue_time', 1.5)
baseline_EMG = baseline.get_trials_data_EMG('R', 'gocue_time', 0.5, 'gocue_time', 1.5)
# baseline_EMG = [each[:, EMG_channel] for each in baseline_EMG]

noon_spike = noon.get_trials_data_spike_counts('R', 'gocue_time', 0.5, 'gocue_time', 1.5)
noon_EMG = noon.get_trials_data_EMG('R', 'gocue_time', 0.5, 'gocue_time', 1.5)

#%% Training EMG decoders
from wiener_filter import format_data_from_trials, train_wiener_filter, test_wiener_filter, vaf
from wiener_filter import train_nonlinear_wiener_filter, test_nonlinear_wiener_filter
from sklearn.metrics import explained_variance_score, r2_score
from util import print_EMG_acc_across_sess

# Training the baseline decoder
train_x, train_y = baseline_spike[0:80], baseline_EMG[0:80]# Now train_x and train_y are lists, each element corresponds to one trial.
test_x, test_y = baseline_spike[80:120], baseline_EMG[80:120]
train_x, train_y = format_data_from_trials(train_x, train_y, 10) # After formatting now train_x and train_y are numpy arrays 
H_baseline = train_wiener_filter(train_x, train_y, 1)
# ------ Testing the baseline decoder on baseline data --------
test_x, test_y = format_data_from_trials(test_x, test_y, 10) 
test_y_pred = test_wiener_filter(test_x, H_baseline)
print_EMG_acc_across_sess('baseline', 'baseline', test_y, test_y_pred, EMG_names)

# Training the noon decoder
train_x, train_y = noon_spike[0:80], noon_EMG[0:80]
test_x, test_y = noon_spike[80:120], noon_EMG[80:120]
train_x, train_y = format_data_from_trials(train_x, train_y, 10)
H_noon = train_wiener_filter(train_x, train_y, 1)
# ------ Testing the noon decoder on noon data --------
test_x, test_y = format_data_from_trials(test_x, test_y, 10) 
test_y_pred = test_wiener_filter(test_x, H_noon)
print_EMG_acc_across_sess('noon', 'noon', test_y, test_y_pred, EMG_names)
#%% Testing the decoders across dataset
test_x, test_y = noon_spike[80:120], noon_EMG[80:120]
test_x, test_y = format_data_from_trials(test_x, test_y, 10) 

test_y_pred1 = test_wiener_filter(test_x, H_baseline)
print_EMG_acc_across_sess('baseline', 'noon', test_y, test_y_pred1, EMG_names)

test_y_pred2 = test_wiener_filter(test_x, H_noon)
print_EMG_acc_across_sess('noon', 'noon', test_y, test_y_pred2, EMG_names)
#%% Plotting
import seaborn as sns
import matplotlib
from matplotlib import rcParams
import matplotlib.pyplot as plt

rcParams['font.family'] = 'Arial'
rcParams['pdf.fonttype'] = 42
rcParams['ps.fonttype'] = 42

plt.figure('EMG with different decoder', figsize = (20, 5))
plt.title('Pop_WS_20210902')
for i in range(len(EMG_names)):
    ax = plt.subplot(2, 8, i+1)
    ax.set_title(EMG_names[i])
    plt.scatter(test_y_pred1[:, i], test_y_pred2[:, i], c = 'dimgray', s = 5)
    plt.xlim([0, 100])
    plt.ylim([0, 100])
    plt.tight_layout()
    ax.plot(ax.get_xlim(), ax.get_ylim(), ls="--", color = 'gray')








