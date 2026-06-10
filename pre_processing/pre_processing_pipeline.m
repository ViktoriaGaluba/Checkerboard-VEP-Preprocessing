%% Preprocessing pipeline for checkerboard reversal paradigm
%
% This script implements the core EEG preprocessing steps used for the
% Normann et al. 2007 protocol.
%
% Requirements:
% - MATLAB
% - EEGLAB on MATLAB path
% - pop_loadcurry support
% - Custom functions in ../functions:
%       - VEP_recodeEvents.m
%       - VEP_extractERPs.m
%
% Repository structure expected:
% repository_root/
%   preprocessing/
%     pre_processing_pipeline.m   <- this script
%   functions/
%     VEP_recodeEvents.m
%     VEP_extractERPs.m
%   data/
%     raw_data_1b/
%   output/
%     normann_control/
%       pre_processed_data/
%       ERPs/
%
% Note:
% Before running, make sure EEGLAB is available on the MATLAB path.
% If needed, specify the channel location file below.

clear; clc;

%% ----------------------- Path setup -----------------------
script_dir = fileparts(mfilename('fullpath'));
repo_root  = fullfile(script_dir, '..');

% Input/output directories
inpath      = fullfile(repo_root, 'raw_data');
savepath    = fullfile(repo_root, 'preprocessed_data');
ERPsavepath = fullfile(repo_root, 'erp_output');

% Custom functions
addpath(fullfile(repo_root, 'functions'));

% Optional: specify EEGLAB path here if it is not already on the MATLAB path
eeglab_path = '';
if ~isempty(eeglab_path)
    addpath(eeglab_path);
end

% Optional: specify the channel location lookup file
% Example:
% chanloc_file = fullfile(eeglab_path, 'plugins', 'dipfit', 'standard_BESA', 'standard-10-5-cap385.elp');
chanloc_file = '';
if isempty(chanloc_file)
    warning(['No channel location file specified. ' ...
             'Please set "chanloc_file" if channel lookup is required.']);
end

% Create output folders if they do not exist
if ~exist(savepath, 'dir')
    mkdir(savepath);
end
if ~exist(ERPsavepath, 'dir')
    mkdir(ERPsavepath);
end

%% --------------------- Processing Configuration ----------------------
LP = 40;                    % low-pass cutoff in Hz
HP = 0.5;                   % high-pass cutoff in Hz
epochRejThresh = 100;       % epoch rejection threshold in µV
epochWindow = [-0.1 0.45];  % epoch window in seconds
baselineWindow = [-100 0];  % baseline window in ms
latencyShiftSec = 0.02;     % 20 ms electronic latency correction

% File selection
filePattern = '*.cdt';
filenameFilter = 'ADD FILENAME FILTER'; % <- if needed

%% ---------------------- File list -------------------------
all_files = dir(fullfile(inpath, filePattern));
filelist = all_files(contains({all_files.name}, filenameFilter));

if isempty(filelist)
    error('No matching .cdt files found in: %s', inpath);
end

%% ---------------------- Start EEGLAB ----------------------
eeglab;

%% -------------------- Processing loop ---------------------
for p = 1:numel(filelist)

    subject_file = filelist(p).name;
    subject = extractBefore(subject_file, '.cdt');

    fprintf('Processing subject %d/%d: %s\n', p, numel(filelist), subject);

    %% Load Curry file
    EEG = pop_loadcurry(fullfile(inpath, [subject '.cdt']), 'CurryLocations', 'off');
    EEG.filename = subject;

    %% Correct for electronic latency
    for e = 1:numel(EEG.event)
        EEG.event(e).latency = EEG.event(e).latency + (latencyShiftSec * EEG.srate);
    end

    %% Recode events
    EEG = VEP_recodeEvents(EEG);

    %% Set channel locations
    if ~isempty(chanloc_file)
        EEG = pop_chanedit(EEG, 'lookup', chanloc_file);
    end

    %% Filtering
    EEG = pop_eegfiltnew(EEG, 'hicutoff', LP);
    EEG = pop_eegfiltnew(EEG, 'locutoff', HP);

    %% Epoching
    cond = cellstr(string(unique([EEG.event.type])));
    EEG = pop_epoch(EEG, cond, epochWindow, 'epochinfo', 'yes');

    %% Baseline correction
    EEG = pop_rmbase(EEG, baselineWindow, []);

    %% Epoch rejection at Oz
    chanOz = find(strcmpi({EEG.chanlocs.labels}, 'Oz'));
    if isempty(chanOz)
        error('Oz channel not found for subject: %s', subject);
    end

    EEG = pop_eegthresh(EEG, 1, chanOz, ...
        -epochRejThresh, epochRejThresh, epochWindow(1), epochWindow(2), 2, 0);

    EEG = eeg_rejsuperpose(EEG, 1, 0, 1, 0, 0, 0, 0, 0);
    EEG.report.nEpochsRemoved = sum(EEG.reject.rejthresh);
    EEG.report.EpochsRemoved = find(EEG.reject.rejthresh);
    EEG = pop_rejepoch(EEG, find(EEG.reject.rejglobal), 0);

    fprintf('  Rejected %d epochs\n', EEG.report.nEpochsRemoved);

    %% Save preprocessed EEG
    save(fullfile(savepath, [subject '_VEP.mat']), 'EEG');

    %% Extract ERP output
    VEP_output = VEP_extractERPs(EEG);

    %% Save ERP output
    save(fullfile(ERPsavepath, [subject '_VEP_ERP.mat']), 'VEP_output');

    fprintf('  Saved EEG and ERP outputs for %s\n', subject);
end

fprintf('Processing complete.\n');
