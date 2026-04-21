function EEG = VEP_recodeEvents(EEG)
%% Recode VEP events into experimental blocks
%
% This function:
% 1. Converts event types to numeric values if necessary
% 2. Retains only stimulus triggers of type 1 and 2
% 3. Detects block boundaries based on pauses > 2 seconds
% 4. Assigns each event to a block
% 5. Adds a descriptive block label to each event
%
% Assumptions:
% - Trigger codes 1 and 2 represent valid stimulus events
% - A pause > 2 s between a type-2 event and the next type-1 event marks a new block
% - The first block is labelled 'baseline'; subsequent blocks are labelled
% 'post_1', 'post_2', etc. assuming there is no modulation phase (Normann
% Control)
%
% Input:
%   EEG : EEGLAB EEG structure
%
% Output:
%   EEG : EEGLAB EEG structure with recoded events

    if isempty(EEG.event)
        error('EEG.event is empty.');
    end

    %% Convert event types to numeric if needed
    if ischar(EEG.event(1).type) || isstring(EEG.event(1).type)
        for n = 1:numel(EEG.event)
            convertedType = str2double(erase(string(EEG.event(n).type), 'condition '));
            if isnan(convertedType)
                error('Event type conversion failed for event %d: %s', n, string(EEG.event(n).type));
            end
            EEG.event(n).type = convertedType;
        end
    end

    %% Keep only triggers of type 1 and 2
    keepIdx = ismember([EEG.event.type], [1 2]);
    EEG.event = EEG.event(keepIdx);

    if isempty(EEG.event)
        error('No events with trigger type 1 or 2 remained after filtering.');
    end

    %% Identify block boundaries based on long pauses
    blockEnd = [];
    for e = 1:numel(EEG.event)-1
        isBoundary = EEG.event(e).type == 2 && ...
                     EEG.event(e+1).type == 1 && ...
                     (EEG.event(e+1).latency - EEG.event(e).latency) > EEG.srate * 2;
        if isBoundary
            blockEnd(end+1) = e; %#ok<AGROW>
        end
    end
    blockEnd(end+1) = numel(EEG.event); %#ok<AGROW>

    %% Assign block numbers
    blocks = 1:numel(blockEnd);
    b = 1;
    for e = 1:numel(EEG.event)
        if e > blockEnd(b)
            b = b + 1;
        end
        EEG.event(e).block = blocks(b);
    end

    %% Assign block labels
    for e = 1:numel(EEG.event)
        blockNum = EEG.event(e).block;
        if blockNum == 1
            EEG.event(e).blockType = 'baseline';
        else
            EEG.event(e).blockType = ['post_' num2str(blockNum - 1)];
        end
    end
end
