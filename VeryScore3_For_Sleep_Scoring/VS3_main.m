function VS3_main
% VS3_MAIN VeryScore3: score mouse sleep (wake / NREM / REM) in 4-s epochs.
%
% VeryScore3 is the continuation of VeryScore2 (Romain Cardis & Anita Luthi,
% Luthi lab, University of Lausanne, 2018-2021; updates by Georgios Foustoukos
% 2023-2024). It reads and writes the same files as VeryScore2.
%
% Version 3.0 (2026, Alejandro Osorio-Forero with Claude): VeryScore2 1.6-1.8
% unified in one program (all files VS3_*), see CHANGELOG.md.
% - Preferences in the group 'VeryScore3' (VS3_pref), taken over from VeryScore2.
% - Save: names not ending in _t.mat no longer lose characters.
% - Import randomly no longer needs the Statistics toolbox.
% - Auto-scoring library: the shipped recordings plus your own, kept apart.
% - File > Convert Open Ephys recording (VS3_convertOpenEphys).
% - Tools > Summary figure: hypnogram, EEG sigma, temperature, photometry (VS3_summary).
% - The VeryScore3 logo: start screen, progress windows, Help > About (VS3_logo).
%
% History of VeryScore2:
% Version 1.5 addings.
% - Microarousal epoch corresponding to keyboard key 'm'
% - Treatment of last channel if it's too big (usually stimulation trace)
% -d Correction of a bug that did not let you import another file while one
% was already loaded making it mandatory to quit VS2 between files.
% - New Random import that will automatically ask and reload another file
% randomly from the baselected during the first import.
% - Added a menu to directly access the reduce file size (useful for
% files
% from INTAN
% recordings).
% - Correction of a 3bug that did not correctly show the last epoch of the
% scoring and the xlim of the main plot.
% - Retrocompatibility with the files containing old variable t
% - Add a failsafe if the scoring is not saved and the windows is closed
% -Added a f epoch that can be use for whatever like drawziness or else.
% The color is the wonderful purple because it's Najma's
%- Fixed a bug that prevented to edit file Infos because of the new
%configuration field containing the Intan configuration for the specific
%animals.
%
% Version 1.6 addings (2026, Alejo Osorio with Claude):
% - Thermal video temperature: Tools > Thermal video analyses an Optris
% .ravi recording (see VS3_thermalTool) and shows the temperature of the
% animal in a panel above the hypnogram. The result is stored as the variable
% 'Thermal' in the scoring file and shown again when the file is loaded.
%
% Version 1.7 addings (2026, Alejo Osorio with Claude):
% - Photometry: Tools > Photometry turns the selected trace (the raw,
% LED-modulated detector channel) into dF/F, see VS3_photometry. Two baselines,
% because it depends on the sensor: the purple (405 nm) signal fitted onto the
% signal, or the double-exponential decay of the signal itself. The result is
% stored as the variable 'Photometry' in the file and shown again at loading.
%
% Version 1.8 addings (2026, Alejo Osorio with Claude):
% - New auto-scoring (Tools > Auto-Scoring > Score this file), see
% VS3_autoScoreTool: EEG spectra and EMG >30 Hz, a model trained on a library
% of manually scored recordings and adapted to each recording, uncertain epochs
% left as 'b' for review (shift+B jumps to the next one). Corrected scorings can
% be added to the library. The VeryScore1 autoscore stays as "Classic".
%
% Romain Cardis 2021

%clear h
%close all
%clc

%% create main figure and menus
h = struct();
h.updt = '3.0';
h = VS3_display(h);
h.thermal = [];   % temperature of the thermal video (struct 'Thermal'), see VS3_thermalTool
h.Fs = [];        % sampling rate of the loaded file (Hz)
h.photometry = []; % dF/F of a photometry channel (struct 'Photometry'), see VS3_photometry

%% set menu callbacks

h.mainFig.CloseRequestFcn = @SureToClose;
h.issaved = 1;

% File
h.fileMenu_import.Callback = @importOne;
h.fileMenu_save.Callback = @saveScoring;
h.fileMenu_editInfo.Callback = @editInfos;
h.fileMenu_importrandom.Callback = @importRand;
h.fileMenu_convertOE.Callback = @convertOpenEphys;
h.fileMenu_reduce.Callback = @reduceFile;
h.fileMenu_rename.Callback = @renameFileToBt;
% Traces
h.tracesMenu_bipol.Callback = @bipol;
h.tracesMenu_filt.Callback = @filt;
h.tracesMenu_lockYlim.Callback = @lockYlim;
h.tracesMenu_ChangeGain.Callback = @changeGain1000;
h.tracesMenu_notch.Callback = @notching;
h.tracesMenu_Supress.Callback = @supressTraces;
h.tracesMenu_swapTraces.Callback = @swapT;
h.tracesMenu_reverse.Callback = @reverseAll;
h.tracesMenu_origain.Callback = @origain;

% Tools
h.toolsMenu_autoScoreRun.Callback = @autoScoreRun;
h.toolsMenu_autoScoreAdd.Callback = @autoScoreAdd;
h.toolsMenu_autoScoreLib.Callback = @autoScoreLibrary;
h.toolsMenu_autoScoreClassic.Callback = @launchAuto;
h.toolsMenu_nameTraces.Callback = @reloadNames;
h.toolsMenu_takeSnap.Callback = @takeSnap;
h.toolsMenu_summary.Callback = @summaryFigure;
h.helpMenu_about.Callback = @(~,~) VS3_logo('about', h.updt);
% Tools > Thermal video
h.toolsMenu_thermalAnalyse.Callback = @thermalAnalyse;
h.toolsMenu_thermalShow.Callback = @thermalShowHide;
h.toolsMenu_thermalOffset.Callback = @thermalOffset;
h.toolsMenu_thermalEstimate.Callback = @thermalEstimate;
h.toolsMenu_thermalCalib.Callback = @thermalCalibrate;
h.toolsMenu_thermalPython.Callback = @thermalPython;
h.toolsMenu_thermalOpenEphys.Callback = @thermalOpenEphys;
% Tools > Photometry
h.toolsMenu_photoDFF.Callback = @photometryDFF;
h.toolsMenu_photoFigure.Callback = @photometryFigure;

% Width
h.widthMenu_8.Callback = @changeWidth;
h.widthMenu_16.Callback = @changeWidth;
h.widthMenu_24.Callback = @changeWidth;
h.widthMenu_32.Callback = @changeWidth;
h.widthMenu_40.Callback = @changeWidth;
h.widthMenu_48.Callback = @changeWidth;
h.widthMenu_96.Callback = @changeWidth;
h.widthMenu_384.Callback = @changeWidth;
% fishy

%% set keyboard function
h.mainFig.KeyPressFcn = @key;

%% callback functions

    function SureToClose(~,~)
        if h.issaved == 0
            an = questdlg('It seems you did not save your scoring, you are risking loosing it all like Najma once! Are you sure to close?', 'CAREFUL!','Yes, my scoring is worthless.', 'No wait! I will save!', 'No wait! I will save!');
            if strcmp(an, 'Yes, my scoring is worthless.')
                delete(h.mainFig)
            end
        else
            delete(h.mainFig)
        end
    end

    function reduceFile(~,~)
        ReduceBTfileSize(h.file)
    end

    function origain(~,~)
        h.bigplot.backToGain()
    end
    
    function takeSnap(~,~)
        figure
        f = axes();
        for i = 1:length(h.bigplot.graphLines)
            copyobj(h.bigplot.graphLines{i}, f)
        end
        title(h.filen)
        f.TickDir = 'out';
    end

    function summaryFigure(~,~)
        % hypnogram, EEG sigma activity, temperature and photometry of the whole recording (VS3_summary)
        b = h.bigplot.giveMeB();
        names = autoScoreNames();
        d = autoScoreDefaults(names); % the EEG chosen for the auto-scoring, if any
        [sel, ok] = listdlg('ListString', names, 'SelectionMode', 'single', 'InitialValue', d.eeg(1), ...
            'Name', 'Summary figure', 'PromptString', 'EEG channel for the sigma activity (10-15 Hz):', 'ListSize', [320 160]);
        if ~ok || isempty(sel); return; end
        st = '';
        ttl = h.filen;
        [~, base] = fileparts(h.filen);
        sfile = fullfile(h.path, [base, '_summary.fig']); % proposed when the summary is saved
        if h.rand == 1
            ttl = 'blind scoring'; % no file name, no date
            sfile = fullfile(h.path, 'summary.fig');
        elseif ismember('Infos', who(h.file))
            Infos = h.file.Infos;
            if isfield(Infos, 'StartTime'); st = Infos.StartTime; end
        end
        try
            VS3_summary('b', b, 'eeg', h.bigplot.oriTraces(sel, :), 'fs', 200, 'eegName', regexprep(names{sel}, '^\d+: ', ''), ...
                'thermal', h.thermal, 'photometry', h.photometry, 'startTime', st, 'title', ttl, 'navigate', @goToEpoch, ...
                'file', sfile);
        catch err
            errordlg(sprintf('The summary could not be made:\n%s', err.message), 'Summary figure');
        end
    end

    function goToEpoch(ep)
        % show epoch ep in the main window (a click in the summary figure)
        if ~isgraphics(h.mainFig) || ~isfield(h, 'bigplot'); return; end
        h.bigplot.position = min(max(round(ep), 1), numel(h.bigplot.bstate));
        h.bigplot.updatePlot()
        figure(h.mainFig)
    end

    function swapT(~,~)
        h.bigplot.swapTraces();
    end

    function supressTraces(~,~)  
        h.bigplot.supressTraces()
    end
    
    function reloadNames(~,~)
        varInfo = who(h.file);
        if ismember('Infos',varInfo)
            Infos = h.file.Infos;
            if isfield(Infos,'Channel')
                chanames = Infos.Channel;
                h.Channel = strsplit(chanames(~isspace(chanames)),',');
                h.bigplot.ChannelNames = h.Channel;
                h.bigplot.initiateNames()
            end
        end
        if ismember('traceName',varInfo)
            chanames = h.file.traceName;
            h.Channel = chanames;
            h.bigplot.ChannelNames = h.Channel;
            h.bigplot.initiateNames()
        end
    end

    function editInfos(~,~)
        varInfo = who(h.file);
        action = questdlg('Edit current Infos or add a new field?', 'There should be a better way no?', 'Edit', 'New', 'Edit');
        switch action
            case 'Edit'
                if ismember('Infos',varInfo)
                    Infos = h.file.Infos;
                    nam = fieldnames(Infos);
                    df = struct2cell(Infos);
                    ifc = find(strcmp(nam,'Configuration'));
                    conf = [];
                    if ~isempty(ifc) % files without the Intan Configuration field (e.g. Open Ephys) made this crash
                        conf = df{ifc};
                    end
                    nam(ifc) = [];
                    df(ifc) = [];
                    n = cellfun(@ischar, df);
                    df(~n) = cellfun(@num2str, df(~n),'UniformOutput',false);
                    an = inputdlg(nam, 'Edit Infos', [1,40], df);
                    if ~isempty(an)
                         nInfos = cell2struct(an,nam);
                         if ~isempty(ifc)
                            nInfos.Configuration = conf;
                         end
                         h.file.Infos = nInfos;
                    end
                else
                    errordlg('There is no Infos variable in the file!')
                end
                
            case 'New'
                if ismember('Infos',varInfo)
                    Infos = h.file.Infos;
                else
                    Infos = struct;
                end
                an = inputdlg({'New field name', 'Field content'}, 'Edit Infos', [1,40]);
                Infos.(char(an{1})) = an{2};
                h.file.Infos = Infos;
        end
    end

    function changeGain1000(~,~)
        an = questdlg('Plus or minus?','Quite dumb to ask like that no?','plus','minus','minus');
        h.bigplot.changeGain(an,1000);
    end

    function lockYlim(obj,~)
        if strcmp(obj.Checked, 'on')
            obj.Checked = 'off';
            h.bigplot.lockYlim = 0;
        else
            obj.Checked = 'on';
            h.bigplot.lockYlim = 1;
        end
        
    end

    function reverseAll(~,~)
        h.b = h.bigplot.giveMeB();
        posi = h.bigplot.position;
        wi = h.bigplot.width;
        rt = h.bigplot.realTrans; % the transitions you placed by hand (saved as bTrans)
        shown = ~isempty(h.bigplot.thermax) && isgraphics(h.bigplot.thermax);
        h.bigplot.deleteAxes()
        h.bigplot = VS3_tracesPlot(h,posi,wi);
        h.bigplot.realTrans = rt;
        h.bigplot.updatePlot()
        if ~isempty(h.thermal) && shown
            h.bigplot.showThermal(h.thermal)
        end
        thermalMenus()
        if ~isempty(h.photometry)
            h.bigplot.showDFF(h.photometry.channelIndex, h.photometry)
        end
    end

    function saveScoring(~,~)
        b = h.bigplot.giveMeB();
        h.file.b = b;
        h.file.bTrans = h.bigplot.realTrans;
        h.issaved = 1;
        % a scored file is called <name>_bt.mat: <name>_t.mat -> <name>_bt.mat, <name>.mat -> <name>_bt.mat
        [~, base] = fileparts(h.filen);
        if ~endsWith(base, '_bt')
            if endsWith(base, '_t'); base = base(1:end-2); end
            newName = [base, '_bt.mat'];
            movefile([h.path,h.filen],[h.path,newName],'f')
            h.filen = newName;
        end
        h.file = matfile([h.path, h.filen], 'writable', true);
        m = msgbox('Saved!');
        waitfor(m)
        if h.rand == 1 && h.curRandFile < length(h.filebatch)
            an = questdlg('Do you want to stay blind and import the next random file?', 'Keep it blind!', 'Yes, I''m a good scientist', 'No I want to cheat', 'Yes, I''m a good scientist');
            if strcmp(an, 'Yes, I''m a good scientist')
                h.curRandFile = h.curRandFile +1;
                h.filen = h.filebatch{h.randOrder(h.curRandFile)};
                import
            end
        elseif h.rand == 1
            msgbox('You are done with this batch. CONGRATS!')
            h.fileMenu_importrandom.Enable = 'on';
            h.fileMenu_import.Enable = 'on';
        end
    end
    
    function importRand(~,~)
        [h.filebatch, pathf] = uigetfile('*.mat','Select multiple files and i''ll choose one','multiselect','on');       
        if iscell(h.filebatch)
            h.randOrder = randperm(length(h.filebatch)); % random order (no Statistics toolbox needed)
            h.curRandFile = 1;
            h.filen = h.filebatch{h.randOrder(h.curRandFile)};
            h.path = pathf;
            h.rand = 1; % means rand is active
            h.fileMenu_import.Enable = 'off';
            h.fileMenu_importrandom.Enable = 'off';
            import
        else
            if h.filebatch == 0; return; end
            errordlg('You need to select multiple files and I''ll choose one randomly.')
        end
    end
    
    function importOne(~,~)
        h.rand = 0;
        import  
    end

    function convertOpenEphys(~,~)
        % Open Ephys binary recordings -> VeryScore files, see VS3_convertOpenEphys
        try
            files = VS3_convertOpenEphys();
        catch err
            errordlg(sprintf('The conversion failed:\n%s', err.message), 'Open Ephys conversion');
            return
        end
        if numel(files) ~= 1 || (isfield(h, 'rand') && h.rand == 1); return; end
        [~, n, e] = fileparts(files{1});
        an = questdlg(sprintf('Open %s%s now?', n, e), 'Open Ephys conversion', 'Open', 'Not now', 'Open');
        if ~strcmp(an, 'Open'); return; end
        if isfield(h, 'bigplot') && h.issaved == 0
            an = questdlg('The scoring of the file that is open is not saved. Open the converted file anyway?', ...
                'CAREFUL!', 'Open anyway', 'Cancel', 'Cancel');
            if ~strcmp(an, 'Open anyway'); return; end
        end
        h.rand = 0;
        h.pendingFile = files{1};
        import
    end
    
    function import(~,~)
        % function to import a file into the software and create the plots
        if h.rand == 0
            if isfield(h, 'pendingFile') && ~isempty(h.pendingFile) % a file just converted (convertOpenEphys)
                [pathf, n, e] = fileparts(h.pendingFile);
                filen = [n, e];
                pathf = [pathf, filesep];
                h.pendingFile = '';
            else
                [filen, pathf] = uigetfile('*.mat','Select your file to score');
                if filen == 0; return; end
            end
            h.filen = filen;
            h.path = pathf;
        end
        w = VS3_logo('waitbar', 0, 'Your file is being loaded', 'Name', 'VeryScore3');
        h.file = matfile([h.path, h.filen], 'writable', true);
        try
            traces = h.file.traces;
        catch
            t = h.file.t;
            traces = [t(1:end/2);t(end/2+1:end)];
        end
        
        if max(traces(end,:)) > 3
            traces(end,:) = traces(end,:)/4000; % if it's a stimulation trace
        end
        if h.rand == 0
            h.mainFig.Name = ['VeryScore3 v', h.updt,' - Scoring file: ',h.filen];
        else
            h.mainFig.Name = ['VeryScore3 v', h.updt,' - Scoring file: RANDOM! HA!'];
        end
        varInfo = who(h.file);
        
        % Get sampling rate
        if ismember('Infos',varInfo)
            Infos = h.file.Infos;
            if isfield(Infos,'Fs')
                sr = Infos.Fs;
                if ischar(sr)
                    sr = str2double(sr);
                end
            else
                sr = questdlg('What is the sampling rate of the traces?', 'Please inform', '200 Hz', '1000 Hz', '200 Hz');
                sr = strsplit(sr,' ');
                sr = str2double(sr{1});
                Infos.Fs = num2str(sr);
                h.file.Infos = Infos;
            end
            if isfield(h,'Channel') % in case the Channel field is still present from a previous file.
                h = rmfield(h, 'Channel');
            end
            if isfield(Infos,'Channel')
                chanames = Infos.Channel;
                if iscell(chanames)
                    chanames=chanames{1};
                end
                h.Channel = strsplit(chanames(~isspace(chanames)),',');
                
            end
        else
            sr = questdlg('What is the sampling rate of the traces?', 'Please inform', '200 Hz', '1000 Hz', '200 hz');
            sr = strsplit(sr,' ');
            sr = str2double(sr{1});
            Infos = struct('Fs',num2str(sr));
            h.file.Infos = Infos;
        end
        h.Fs = sr;
        deciFactor = sr/200;
        [si,~] = size(traces); 
        h.tra = [];
        for i = 1:si
            waitbar(i/si,w)
            ntra = decimate(traces(i,:),deciFactor,'fir');
            if max(ntra > 0.08) % it's likely a stimulation trace 0-3.3 V
                ntra = ntra/1000;  
            end
            h.tra = [h.tra; ntra]; % set gain here in case you lost
        end
        clear('traces')
        close(w)
        if ismember('b', varInfo)
            h.b = h.file.b;
        else
            h.b = repmat('b', 1, floor(length(h.tra)/800));
        end
  
        if isfield(h,'bigplot')
            h.bigplot.deleteAxes()
        end
        if isfield(h, 'splash') % the start screen
            delete(h.splash(isgraphics(h.splash)));
            h.splash = [];
        end
        
        h.bigplot = VS3_tracesPlot(h,1,10);
        
        if ismember('bTrans', varInfo)
            h.bigplot.realTrans = h.file.bTrans;
        end

        % Temperature of the thermal video, if this file was already analysed (Tools > Thermal video)
        h.thermal = [];
        if ismember('Thermal', varInfo)
            try
                h.thermal = h.file.Thermal;
                h.bigplot.showThermal(h.thermal)
            catch err
                h.thermal = [];
                warning('VS3:thermal', 'The temperature stored in the file could not be displayed: %s', err.message)
            end
        end
        thermalMenus()

        % dF/F of a photometry channel, if it was already computed for this file (Tools > Photometry)
        h.photometry = [];
        if ismember('Photometry', varInfo)
            try
                P = h.file.Photometry;
                if isfield(P, 'dff') && isfield(P, 'time') && isfield(P, 'channelIndex')
                    h.photometry = P;
                    h.bigplot.showDFF(P.channelIndex, P)
                    nm = regexprep(h.bigplot.ChannelNames{P.channelIndex}, ' dF/F$', '');
                    if isfield(P, 'channel') && ~isempty(regexp(nm, '\S', 'once')) && ~strcmpi(strtrim(nm), strtrim(P.channel)) ...
                            && ~startsWith(nm, 'Trace ')
                        warning('VS3:photometry', 'The dF/F stored in the file was computed on "%s" but channel %d is now called "%s".', ...
                            P.channel, P.channelIndex, nm)
                    end
                end
            catch err
                h.photometry = [];
                warning('VS3:photometry', 'The dF/F stored in the file could not be displayed: %s', err.message)
            end
        end
        photometryMenus()
        
        % Activate Menus
        h.fileMenu_save.Enable = 'on';
        h.toolsMenu.Enable = 'on';
        h.tracesMenu.Enable = 'on';
        h.widthMenu.Enable = 'on';
        h.fileMenu_editInfo.Enable = 'on';
        h.fileMenu_reduce.Enable = 'on';
    end

%% Thermal video (temperature) functions, see VS3_thermalTool
    function thermalMenus()
        % enable / check the thermal menu items according to the current state
        has = ~isempty(h.thermal);
        shown = has && ~isempty(h.bigplot.thermax) && isgraphics(h.bigplot.thermax);
        onoff = {'off', 'on'};
        h.toolsMenu_thermalShow.Enable = onoff{has+1};
        h.toolsMenu_thermalShow.Checked = onoff{shown+1};
        h.toolsMenu_thermalOffset.Enable = onoff{has+1};
        h.toolsMenu_thermalEstimate.Enable = onoff{has+1};
    end

    function applyThermal(A)
        h.thermal = A;
        h.bigplot.showThermal(A)
        thermalMenus()
    end

    function d = thermalDefaults()
        % options of the previous analysis of this file, used as defaults for the next one
        d = {'blind', h.rand == 1};
        if isempty(h.thermal); return; end
        if isfield(h.thermal, 'offset')
            src = '';
            if isfield(h.thermal, 'offsetSource'); src = h.thermal.offsetSource; end
            if any(startsWith(src, {'offset typed', 'from the EEG start time typed', 'estimated from the movement'}))
                d = [d, {'offset', h.thermal.offset}];          % your choice: kept
            else
                d = [d, {'previousOffset', h.thermal.offset}];  % the EEG start time of the file wins, if it has one
            end
        end
        if isfield(h.thermal, 'roiMethod'); d = [d, {'roiMethod', h.thermal.roiMethod}]; end
        if isfield(h.thermal, 'roiParams') && isfield(h.thermal.roiParams, 'N'); d = [d, {'N', h.thermal.roiParams.N}]; end
    end

    function thermalAnalyse(~,~)
        % select a .ravi (or converted .h5), extract the temperature and align it with the epochs
        if ~isempty(h.thermal)
            an = questdlg('A temperature analysis already exists for this file. Run it again and replace it?', 'Thermal video', 'Yes', 'No', 'No');
            if ~strcmp(an, 'Yes'); return; end
        end
        b = h.bigplot.giveMeB();
        d = thermalDefaults();
        try
            [A, ok] = VS3_thermalTool('analyse', h.file.Properties.Source, 'Fs', h.Fs, 'nEpochs', length(b), 'b', b, d{:});
        catch err
            errordlg(sprintf('The thermal analysis failed:\n%s', err.message), 'Thermal video')
            return
        end
        if ok; applyThermal(A); end
    end

    function thermalShowHide(obj,~)
        if isempty(h.thermal); return; end
        if strcmp(obj.Checked, 'on')
            h.bigplot.hideThermal()
        else
            h.bigplot.showThermal(h.thermal)
        end
        thermalMenus()
    end

    function thermalRealign(newOffset, src)
        % newOffset in seconds, or the EEG start time (datetime / text); src = where it comes from
        if nargin < 2; src = ''; end
        b = h.bigplot.giveMeB();
        try
            [A, ok] = VS3_thermalTool('realign', h.file.Properties.Source, h.thermal, newOffset, 'Fs', h.Fs, 'nEpochs', length(b), 'source', src);
        catch err
            errordlg(sprintf('The re-alignment failed:\n%s', err.message), 'Thermal video')
            return
        end
        if ok; applyThermal(A); end
    end

    function thermalOffset(~,~)
        % new offset in seconds, or as the EEG start time (the video start time is in the file)
        if isempty(h.thermal); return; end
        [newOffset, ok, src] = VS3_thermalTool('offsetDialog', h.thermal);
        if ~ok; return; end
        thermalRealign(newOffset, src)
    end

    function thermalEstimate(~,~)
        if isempty(h.thermal); return; end
        b = h.bigplot.giveMeB();
        try
            [est, out] = VS3_thermalTool('estimateOffset', h.file.Properties.Source, h.thermal, 'b', b, 'plot', true);
        catch err
            errordlg(sprintf('The offset could not be estimated:\n%s', err.message), 'Thermal video')
            return
        end
        cur = h.thermal.offset;
        ccCur = out.cc(out.lags == round(cur));
        if isempty(ccCur); ccCur = NaN; end
        near = out.lags(out.cc >= out.ccMax - 0.01); % offsets that fit about as well
        src = '';
        if isfield(h.thermal, 'offsetSource'); src = h.thermal.offsetSource; end
        if out.ccMax < 0.3
            msgbox(sprintf(['The movement in the video does not follow the wake epochs well enough to estimate the ', ...
                'offset (best correlation %.2f). The current offset (%g s) is kept.'], out.ccMax, cur), 'Video / EEG offset');
            return
        end
        txt = sprintf(['The movement in the video matches the wake epochs best with an offset of %+d s (correlation %.2f, ', ...
            'peak ratio %.2f); offsets from %+d to %+d s fit about as well. The current offset is %g s (%s), correlation %.2f.'], ...
            est, out.ccMax, out.peakRatio, min(near), max(near), cur, src, ccCur);
        if startsWith(src, 'from the EEG start time')
            txt = sprintf(['%s\n\nThe current offset comes from the start times of the two recordings, which is usually more ', ...
                'precise than this estimate (a few seconds).'], txt);
        end
        an = questdlg(sprintf('%s\n\nRe-align the temperature with %+d s?', txt, est), 'Video / EEG offset', 'Yes', 'No', 'No');
        if strcmp(an, 'Yes'); thermalRealign(est, 'estimated from the movement in the video'); end
    end

    function thermalCalibrate(~,~)
        % add the camera's Kennlinie (energy -> degC) table to a converted video, then re-analyse
        h5 = '';
        if ~isempty(h.thermal) && isfield(h.thermal, 'source') && isfile(h.thermal.source)
            h5 = h.thermal.source;
        end
        try
            [ok, h5] = VS3_thermalTool('calibrate', h5);
        catch err
            errordlg(sprintf('Adding the calibration failed:\n%s', err.message), 'Thermal video')
            return
        end
        if ~ok; return; end
        an = questdlg('Calibration added. Run the temperature analysis again now to get values in degC?', 'Thermal video', 'Yes', 'Later', 'Yes');
        if ~strcmp(an, 'Yes'); return; end
        b = h.bigplot.giveMeB();
        d = thermalDefaults();
        try
            [A, ok] = VS3_thermalTool('analyse', h.file.Properties.Source, 'video', h5, 'Fs', h.Fs, 'nEpochs', length(b), 'b', b, d{:});
        catch err
            errordlg(sprintf('The thermal analysis failed:\n%s', err.message), 'Thermal video')
            return
        end
        if ok; applyThermal(A); end
    end

    function thermalOpenEphys(~,~)
        % read the EEG start time from the Open Ephys recording of this file, store it in Infos.StartTime
        startDir = VS3_pref('get', 'openEphysDir', h.path);
        if ~isfolder(startDir); startDir = h.path; end
        [f, p] = uigetfile({'sync_messages.txt', 'Open Ephys sync_messages.txt'}, ...
            'Select sync_messages.txt in the Open Ephys recording of this file (experiment*\recording*)', fullfile(startDir, 'sync_messages.txt'));
        if isequal(f, 0); return; end
        VS3_pref('set', 'openEphysDir', p);
        try
            t = VS3_thermalTool('eegStartOpenEphys', fullfile(p, f));
        catch err
            errordlg(sprintf('Could not read the start time:\n%s', err.message), 'Thermal video')
            return
        end
        ts = char(string(t, 'yyyy-MM-dd HH:mm:ss.SSS'));
        if ismember('Infos', who(h.file)); Infos = h.file.Infos; else; Infos = struct; end
        Infos.StartTime = ts;
        h.file.Infos = Infos;
        msg = sprintf(['First EEG sample recorded at %s (clock of the Open Ephys PC).\n', ...
            'Stored as Infos.StartTime in the file: the thermal analysis uses it from now on.'], ts);
        if ~isempty(h.thermal) && isfield(h.thermal, 'videoStart') && ~isnat(h.thermal.videoStart)
            off = seconds(t - h.thermal.videoStart);
            an = questdlg(sprintf('%s\n\nThe video started at %s, so the offset is %.3f s (current: %g s). Re-align the temperature now?', ...
                msg, char(string(h.thermal.videoStart, 'yyyy-MM-dd HH:mm:ss.SSS')), off, h.thermal.offset), 'Thermal video', 'Yes', 'No', 'Yes');
            if strcmp(an, 'Yes'); thermalRealign(t, 'from the Open Ephys recording'); end
        else
            msgbox(msg, 'Thermal video')
        end
    end

    function thermalPython(~,~)
        [f, p] = uigetfile({'python.exe', 'python.exe'}, 'Select the python.exe used to convert .ravi videos (needs numpy and h5py)');
        if isequal(f, 0); return; end
        [ok, info] = VS3_thermalTool('checkPython', fullfile(p, f));
        if ok
            msgbox(sprintf('Python found and remembered:\n%s', info), 'Thermal video')
        else
            errordlg(sprintf('This Python cannot import numpy and h5py:\n%s\n\nInstall them with:  pip install numpy h5py', info), 'Thermal video')
        end
    end

%% Photometry (dF/F) functions, see VS3_photometry
    function photometryMenus()
        % the overview figure needs a result made by VS3_photometry
        onoff = {'off', 'on'};
        has = ~isempty(h.photometry) && isfield(h.photometry, 'baseline') && isfield(h.photometry, 'method');
        h.toolsMenu_photoFigure.Enable = onoff{has+1};
    end

    function photometryDFF(~,~)
        % dF/F of the selected trace, computed from the full-rate channel of the file
        sele = find(h.bigplot.selectedTraces);
        if length(sele) ~= 1
            errordlg('Select the photometry trace first: click on it, one trace only.', 'Photometry');
            return
        end
        ud = h.bigplot.graphLines{sele}.UserData;
        if length(ud) ~= 2
            errordlg('Select a recorded channel, not the difference of two traces.', 'Photometry');
            return
        end
        name = regexprep(h.bigplot.ChannelNames{sele}, ' dF/F$', '');
        old = [];
        if ~isempty(h.photometry) && isfield(h.photometry, 'channelIndex') && h.photometry.channelIndex ~= ud(2)
            % one dF/F per file: the stored one is replaced
            oldName = sprintf('channel %d', h.photometry.channelIndex);
            if isfield(h.photometry, 'channel'); oldName = h.photometry.channel; end
            an = questdlg(sprintf(['The file already holds the dF/F of %s (one photometry channel per file). ', ...
                'Replace it by the dF/F of %s?'], oldName, name), 'Photometry', 'Replace', 'Cancel', 'Cancel');
            if ~strcmp(an, 'Replace'); return; end
            old = h.photometry.channelIndex;
        end
        try
            [P, ok] = VS3_photometry('analyse', h.file.Properties.Source, ud(2), 'name', name, 'Fs', h.Fs, 'blind', h.rand == 1);
        catch err
            errordlg(sprintf('The dF/F could not be computed:\n%s', err.message), 'Photometry');
            return
        end
        if ~ok; return; end
        if ~isempty(old)
            % the channel that held the previous dF/F shows its raw trace again
            rows = find(cellfun(@(g) numel(g.UserData) == 2 && g.UserData(2) == old, h.bigplot.graphLines));
            for r = rows(:)'; h.bigplot.rawTrace(r); end
            h.bigplot.initiateNames()
        end
        h.photometry = P;
        h.bigplot.showDFF(sele, P)
        photometryMenus()
    end

    function photometryFigure(~,~)
        % carrier amplitudes, baseline and dF/F of the whole recording
        if isempty(h.photometry); return; end
        ttl = '';
        if h.rand == 0; ttl = h.filen; end
        if isfield(h.photometry, 'channel'); ttl = strtrim([ttl, '   ', h.photometry.channel]); end
        VS3_photometry('figure', h.photometry, ttl);
    end

% autoscore
    function launchAuto(~,~)
        % classic VeryScore1 autoscore on the selected EEG and EMG traces
        h.bigplot.autoscore()
        h.issaved = 0;
    end

%% Auto-scoring (version 2), see VS3_autoScoreTool
    function names = autoScoreNames()
        % names of the original channels (rows of oriTraces)
        n = size(h.bigplot.oriTraces, 1);
        names = arrayfun(@(i) sprintf('Trace %d', i), 1:n, 'UniformOutput', false);
        if isfield(h, 'Channel') && numel(h.Channel) == n
            names = h.Channel;
        elseif ismember('traceName', who(h.file))
            tn = h.file.traceName;
            if iscell(tn) && numel(tn) == n; names = tn; end
        end
        names = cellfun(@(s, i) sprintf('%d: %s', i, s), names(:)', num2cell(1:n), 'UniformOutput', false);
    end

    function d = autoScoreDefaults(names)
        % last choice for the same channel names, else by name, else EMG = 1-2 and EEG = 3-4
        n = numel(names);
        d = struct('eeg', 1, 'emg', min(2, n), 'keepScored', false, 'review', 0.6);
        if n >= 4; d.eeg = [3 4]; d.emg = [1 2]; end
        isE = find(contains(names, 'EEG', 'IgnoreCase', true));
        isM = find(contains(names, 'EMG', 'IgnoreCase', true));
        if ~isempty(isE) && ~isempty(isM); d.eeg = isE(1:min(2,end)); d.emg = isM(1:min(2,end)); end
        if VS3_pref('is', 'autoScore')
            p = VS3_pref('get', 'autoScore');
            if isfield(p, 'names') && isequal(p.names, names); d.eeg = p.eeg; d.emg = p.emg; end
            if isfield(p, 'review'); d.review = p.review; end
        end
    end

    function autoScoreRun(~,~)
        b = h.bigplot.giveMeB();
        names = autoScoreNames();
        nScored = sum(b ~= 'b');
        d = autoScoreDefaults(names);
        d.keepScored = nScored > 0 && nScored < 0.5*numel(b); % a partly scored file: learn from it
        [o, ok] = VS3_autoScoreTool('dialog', names, nScored, numel(b), d);
        if ~ok; return; end
        VS3_pref('set', 'autoScore', struct('names', {names}, 'eeg', o.eeg, 'emg', o.emg, 'review', o.review));
        tra = h.bigplot.oriTraces;
        w = VS3_logo('waitbar', 0, 'Auto-scoring...', 'Name', 'Auto-scoring');
        try
            [b, R] = VS3_autoScoreTool('score', tra(o.eeg,:), tra(o.emg,:), b, ...
                'keepScored', o.keepScored, 'review', o.review, 'waitbar', w);
        catch err
            if isvalid(w); close(w); end
            errordlg(sprintf('The auto-scoring failed:\n%s', err.message), 'Auto-scoring')
            return
        end
        if isvalid(w); close(w); end
        h.bigplot.initiateB(b)
        h.bigplot.hypnoline.YData = h.bigplot.bstate;
        h.bigplot.updatePlot()
        h.issaved = 0;
        msg = sprintf(['Wake %.1f %%, NREM %.1f %%, REM %.1f %%.\n%d uncertain epochs left unscored (b): ', ...
            'shift+B jumps to the next one.\n\nMethod: %s.\nWake/sleep muscle tone from %s.'], ...
            100*R.fraction, R.nReview, R.method, R.emgFeature);
        if R.nUser > 0; msg = sprintf('%s\nLearned from the %d epochs you had scored.', msg, R.nUser); end
        msgbox(msg, 'Auto-scoring')
    end

    function autoScoreAdd(~,~)
        % add the (corrected) scoring of this file to the library, so that the model learns it
        b = h.bigplot.giveMeB();
        if mean(b ~= 'b') < 0.8
            errordlg('Score (or correct) at least 80 % of the file first: only finished scorings should go in the library.', 'Auto-scoring')
            return
        end
        names = autoScoreNames();
        d = autoScoreDefaults(names);
        d.mode = 'library';
        [o, ok] = VS3_autoScoreTool('dialog', names, 0, numel(b), d);
        if ~ok; return; end
        [~, name] = fileparts(h.filen);
        w = VS3_logo('waitbar', 0.3, 'Computing the features...', 'Name', 'Auto-scoring library');
        try
            tra = h.bigplot.oriTraces;
            F = VS3_autoScoreTool('features', tra(o.eeg,:), tra(o.emg,:), 200, numel(b));
            VS3_autoScoreTool('addToLibrary', F, b, name, sprintf('EEG %s, EMG %s', strjoin(names(o.eeg), ' + '), strjoin(names(o.emg), ' + ')));
        catch err
            if isvalid(w); close(w); end
            errordlg(sprintf('Could not add it to the library:\n%s', err.message), 'Auto-scoring')
            return
        end
        if isvalid(w); close(w); end
        if h.rand == 1; name = 'This recording'; end % stay blind
        msgbox(sprintf('%s is now in your auto-scoring library (%d recordings in all).', name, numel(VS3_autoScoreTool('library'))), 'Auto-scoring')
    end

    function autoScoreLibrary(~,~)
        % show the library (shipped recordings + yours), optionally remove some of yours
        lib = VS3_autoScoreTool('library');
        if isempty(lib); msgbox('The library is empty.', 'Auto-scoring'); return; end
        origin = {'yours', 'shipped'};
        items = arrayfun(@(e) sprintf('[%s]  %s  |  %d EEG, %d EMG  |  W %d  N %d  R %d  |  added %s  %s', origin{e.shipped+1}, e.name, ...
            numel(e.eeg), numel(e.emg), sum(e.y==1), sum(e.y==2), sum(e.y==3), e.added, e.note), lib, 'UniformOutput', false);
        [sel, ok] = listdlg('ListString', items, 'SelectionMode', 'multiple', 'ListSize', [760 250], 'Name', 'Auto-scoring library', ...
            'PromptString', {['Your recordings: ', VS3_autoScoreTool('libraryFile')], ...
            'Select some of YOUR recordings to remove them, or Cancel to keep everything:'}, ...
            'OKString', 'Remove selected', 'InitialValue', []);
        if ~ok || isempty(sel); return; end
        if any([lib(sel).shipped])
            errordlg('The shipped recordings cannot be removed here, only yours.', 'Auto-scoring')
            return
        end
        an = questdlg(sprintf('Remove %d of your recording(s) from the library?', numel(sel)), 'Auto-scoring', 'Remove', 'Cancel', 'Cancel');
        if strcmp(an, 'Remove'); lib(sel) = []; VS3_autoScoreTool('saveLibrary', lib); end
    end

% Change width function
    function changeWidth(obj,~)
        h.widthMenu_8.Checked = 'off';
        h.widthMenu_16.Checked = 'off';
        h.widthMenu_24.Checked = 'off';
        h.widthMenu_32.Checked = 'off';
        h.widthMenu_40.Checked = 'off';
        h.widthMenu_48.Checked = 'off';
        h.widthMenu_96.Checked = 'off';
        h.widthMenu_384.Checked = 'off';
        newWidth = obj.UserData;
        obj.Checked = 'on';
        h.bigplot.changeWidth(newWidth)
    end

%% Traces functions
    function bipol(~,~)
        h.bigplot.bipolarize()
    end

    function filt(~,~)
        req = questdlg('Choose y''a type o''filter', 'Choose one', 'High-pass 0.75Hz', 'High-pass 25 Hz', 'Low-pass 25 Hz', 'High-pass 0.75Hz');
        switch req
            case 'High-pass 0.75Hz'; [a,b] = cheby2(7,40, 0.75/100, 'high');
            case 'High-pass 25 Hz'; [a,b] = cheby2(7,40, 25/100, 'high');
            case 'Low-pass 25 Hz'; [a,b] = cheby2(7,40, 25/100, 'low');
        end
        h.bigplot.filterTrace(a,b)
    end

    function notching(~,~)
        req = questdlg('Choose y''a type o''notch', 'Choose one', '50 Hz', '60 Hz', '50 Hz');
        switch req
            case '50 Hz'; [a,b] = cheby2(7,40, [46,54]/100, 'stop');
            case '60 Hz'; [a,b] = cheby2(7,40, [56,64]/100, 'stop');
        end
        h.bigplot.filterTrace(a,b)
    end

%% Navigation functions
    function goPrev(~,~)
        pos = h.bigplot.position;
        if pos-1 > 0
            h.bigplot.position = pos-1;
        end
        h.bigplot.updatePlot()
    end

    function goNext(~,~)
        pos = h.bigplot.position;
        if pos+1 <= length(h.b)
            h.bigplot.position = pos+1;
            h.bigplot.updatePlot()
        end
    end

%% Keyboard shortcut
    function key(~,evnt)%works only when datacursor mode is off
        if strcmp(evnt.Modifier, 'shift') == 1
            switch evnt.Key
                case 'uparrow'; h.bigplot.moveTrace('up')
                case 'downarrow'; h.bigplot.moveTrace('dn')
                case 'w'; h.bigplot.goTrans('nextW')
                case 'n'; h.bigplot.goTrans('nextN')
                case 'r'; h.bigplot.goTrans('nextR')
                case 'm'; h.bigplot.goTrans('nextM')
                case 'f'; h.bigplot.goTrans('nextF')
                case 'b'; h.bigplot.goTrans('nextB') % next unscored / uncertain epoch
            end
        elseif strcmp(evnt.Modifier, 'control') == 1 
            switch evnt.Key
                case 'z'; disp('not there yet')
            end
        else
            switch evnt.Key
                case 'a'; goPrev()
                case 'd'; goNext()
                case 'uparrow'; h.bigplot.changeGain('plus',1)
                case 'downarrow'; h.bigplot.changeGain('minus',1)
                case 'w'; h.bigplot.changeB('w'); h.issaved = 0;             
                case '1'; h.bigplot.changeB('1'); h.issaved = 0;
                case 'n'; h.bigplot.changeB('n'); h.issaved = 0;            
                case '2'; h.bigplot.changeB('2'); h.issaved = 0;
                case 'r'; h.bigplot.changeB('r'); h.issaved = 0;
                case '3'; h.bigplot.changeB('3'); h.issaved = 0;
                case 'leftarrow'; h.bigplot.goTrans('prev')
                case 'rightarrow'; h.bigplot.goTrans('next')
                case 'm'; h.bigplot.changeB('m'); h.issaved = 0;
                case 'f'; h.bigplot.changeB('f'); h.issaved = 0;
                    % here to custom epochs
            end
        end
    end

end
