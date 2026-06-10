function ERPout = VEP_extractERPs(EEG)
%% Extract VEP component amplitudes and latencies
%
% This function extracts VEP component measures from epoched EEG data.
%
% Extracted components:
% - C1: minimum amplitude at Oz within 50-100 ms
% - P1: maximum amplitude at Oz within 70-130 ms
% - N1a: minimum amplitude at Oz within 120-170 ms
% - N1b: mean amplitude across P7/P8 within 150-190 ms
% - P2: mean amplitude across Oz/POz within 225-280 ms
% - P1-N1a peak-to-peak difference
%
% Assumptions:
% - EEG.data is epoched in [channels x time x epochs] format
% - EEG.times is in milliseconds
% - EEG.epoch contains eventtype information corresponding to each epoch
% - Event types encode block membership numerically (e.g. 1 = baseline,
%   2..N = post blocks)
%
% Input:
%   EEG : EEGLAB EEG structure
%
% Output:
%   ERPout : struct containing averaged waveforms and extracted measures

    %% Channel lookup
    ozChan  = find(strcmpi({EEG.chanlocs.labels}, 'Oz'));
    p7Chan  = find(strcmpi({EEG.chanlocs.labels}, 'P7'));
    p8Chan  = find(strcmpi({EEG.chanlocs.labels}, 'P8'));
    pozChan = find(strcmpi({EEG.chanlocs.labels}, 'POz'));

    if isempty(ozChan) || isempty(p7Chan) || isempty(p8Chan) || isempty(pozChan)
        error('Required channels (Oz, P7, P8, POz) were not all found.');
    end

    %% Time windows (ms)
    timewindow.C1  = find_time_window(EEG.times,  50, 100);
    timewindow.P1  = find_time_window(EEG.times,  70, 130);
    timewindow.N1a = find_time_window(EEG.times, 120, 170);
    timewindow.N1b = find_time_window(EEG.times, 150, 190);
    timewindow.P2  = find_time_window(EEG.times, 225, 280);

    %% Output metadata
    ERPout.subID = EEG.filename;
    ERPout.extractionDate = char(datetime('today'));
    ERPout.timewindow = timewindow;
    ERPout.times = EEG.times;

    %% Extract epoch/block labels
    blockCodes = get_epoch_types(EEG);

    if numel(blockCodes) ~= size(EEG.data, 3)
        error('Number of epoch labels does not match number of EEG epochs.');
    end

    uniqueBlocks = unique(blockCodes(~isnan(blockCodes)));
    nBlocks = numel(uniqueBlocks);

    %% Extract single-trial data [epochs x time]
    ozTrials  = squeeze(EEG.data(ozChan,  :, :))';
    p7Trials  = squeeze(EEG.data(p7Chan,  :, :))';
    p8Trials  = squeeze(EEG.data(p8Chan,  :, :))';
    pozTrials = squeeze(EEG.data(pozChan, :, :))';

    n1bTrials = (p7Trials + p8Trials) / 2;
    p2Trials  = (ozTrials + pozTrials) / 2;

    %% Block labels
    ERPout.VEPavg.blockLabels = cell(1, nBlocks);
    ERPout.VEPraw.blockLabels = cell(1, nBlocks);

    for iBlock = 1:nBlocks
        b = uniqueBlocks(iBlock);

        if b == 1
            label = 'baseline';
        else
            label = sprintf('post_%d', b - 1);
        end

        ERPout.VEPavg.blockLabels{iBlock} = label;
        ERPout.VEPraw.blockLabels{iBlock} = label;

        blockIdx = blockCodes == b;

        if ~any(blockIdx)
            ERPout.VEPavg.blocks{iBlock} = NaN(1, numel(EEG.times));
            ERPout.VEPraw.blocks{iBlock} = NaN;
            ERPout.VEPavg.C1.amp{iBlock} = NaN;
            ERPout.VEPavg.C1.loc{iBlock} = NaN;
            ERPout.VEPavg.C1.lat{iBlock} = NaN;
            ERPout.VEPavg.P1.amp{iBlock} = NaN;
            ERPout.VEPavg.P1.loc{iBlock} = NaN;
            ERPout.VEPavg.P1.lat{iBlock} = NaN;
            ERPout.VEPavg.N1a.amp{iBlock} = NaN;
            ERPout.VEPavg.N1a.loc{iBlock} = NaN;
            ERPout.VEPavg.N1a.lat{iBlock} = NaN;
            ERPout.VEPavg.N1b.amp{iBlock} = NaN;
            ERPout.VEPavg.P2.amp{iBlock} = NaN;
            ERPout.VEPavg.P1N1a_p2p{iBlock} = NaN;
            continue;
        end

        avgWave = mean(ozTrials(blockIdx, :), 1, 'omitnan');
        ERPout.VEPavg.blocks{iBlock} = avgWave;
        ERPout.VEPraw.blocks{iBlock} = ozTrials(blockIdx, :);

        [ERPout.VEPavg.C1.amp{iBlock}, C1pos] = min(avgWave(timewindow.C1));
        ERPout.VEPavg.C1.loc{iBlock} = timewindow.C1(C1pos);
        ERPout.VEPavg.C1.lat{iBlock} = EEG.times(ERPout.VEPavg.C1.loc{iBlock});

        [ERPout.VEPavg.P1.amp{iBlock}, P1pos] = max(avgWave(timewindow.P1));
        ERPout.VEPavg.P1.loc{iBlock} = timewindow.P1(P1pos);
        ERPout.VEPavg.P1.lat{iBlock} = EEG.times(ERPout.VEPavg.P1.loc{iBlock});

        [ERPout.VEPavg.N1a.amp{iBlock}, N1apos] = min(avgWave(timewindow.N1a));
        ERPout.VEPavg.N1a.loc{iBlock} = timewindow.N1a(N1apos);
        ERPout.VEPavg.N1a.lat{iBlock} = EEG.times(ERPout.VEPavg.N1a.loc{iBlock});

        ERPout.VEPavg.N1b.amp{iBlock} = mean(n1bTrials(blockIdx, timewindow.N1b), 'all', 'omitnan');
        ERPout.VEPavg.P2.amp{iBlock}  = mean(p2Trials(blockIdx, timewindow.P2), 'all', 'omitnan');

        ERPout.VEPavg.P1N1a_p2p{iBlock} = ...
            ERPout.VEPavg.P1.amp{iBlock} - ERPout.VEPavg.N1a.amp{iBlock};
    end
end

function idx = find_time_window(times, tStart, tEnd)
    [~, idx1] = min(abs(times - tStart));
    [~, idx2] = min(abs(times - tEnd));
    idx = idx1:idx2;
end

function blockCodes = get_epoch_types(EEG)
    nEpochs = numel(EEG.epoch);
    blockCodes = nan(nEpochs, 1);

    for i = 1:nEpochs
        evt = EEG.epoch(i).eventtype;

        if iscell(evt)
            evt = evt{1};
        end

        if isstring(evt) || ischar(evt)
            evt = str2double(string(evt));
        end

        if isnumeric(evt) && isscalar(evt)
            blockCodes(i) = evt;
        end
    end
end

