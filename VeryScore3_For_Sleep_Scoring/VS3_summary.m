function [fig, S] = VS3_summary(varargin)
%VS3_SUMMARY Overview of a recording: hypnogram, EEG sigma activity, temperature and photometry.
%
%   [fig, S] = VS3_summary('b', b, 'eeg', x, 'fs', 200, ...)      (Tools > Summary figure)
%
% Panels, on one time axis (hours since the first sample), zoomed together:
%   1. hypnogram (wake / NREM / REM; artifacts with their state, microarousals with wake)
%   2. sigma activity of the EEG: power in the sigma band (10-15 Hz) of every 4-s epoch, in % of its
%      mean over NREM epochs (of the median when no NREM is scored); NREM in green: 3-epoch moving
%      median (keeps the ~1-min infraslow fluctuations, damps single-epoch peaks) over the values of
%      every epoch (light); artifact epochs (1/2/3) left out
%   3. temperature of the thermal video, when given (one value per epoch, per frame in grey)
%   4. photometry dF/F, when given (20 Hz in grey, 10-s mean in colour; the start left out of the
%      baseline fit shaded)
% and the time spent in each state, the number of bouts and their mean duration.
%
% Options (name/value):
%   'b'           scoring, one letter per 4-s epoch (w n r, 1 2 3 artifacts, m microarousal, f, b unscored)
%   'eeg', 'fs'   EEG trace for the sigma activity and its sampling rate (default 200 Hz, as displayed)
%   'eegName'     name of that channel
%   'sigmaBand'   [10 15] Hz
%   'thermal'     struct Thermal of the file (VS3_thermalTool), or []
%   'photometry'  struct Photometry of the file (VS3_photometry), or []
%   'startTime'   time of the first sample (text or datetime), shown in the axis label ('' = unknown)
%   'title'       title of the figure (file name; '' in blind mode)
%   'navigate'    function handle fcn(epoch): a click in the figure calls it (VeryScore3 jumps there)
%   'visible'     'on' (default) | 'off'
% S holds what is drawn: time (h) and state of every epoch, sigma (% and raw power), the temperature
% and photometry series, and S.stats (minutes, %, bouts and mean bout duration per state).
%
% Alejandro Osorio-Forero with Claude, 2026, for VeryScore3.

o = struct('b', '', 'eeg', [], 'fs', 200, 'eegName', 'EEG', 'sigmaBand', [10 15], 'thermal', [], ...
    'photometry', [], 'startTime', '', 'title', '', 'navigate', [], 'visible', 'on');
for k = 1:2:numel(varargin)
    if ~isfield(o, varargin{k}); error('VS3_summary:option', 'Unknown option ''%s''.', varargin{k}); end
    o.(varargin{k}) = varargin{k + 1};
end
b = char(o.b(:)');
nEp = numel(b);
if nEp == 0; error('VS3_summary:noScoring', 'No epochs to summarize.'); end
epLen = 4;                                            % s
tEp = ((1:nEp) - 0.5) * epLen / 3600;                 % epoch centres, hours

colW = [.8 .2 .2]; colN = [.4 .6 .2]; colR = [.8 .6 .2]; colPhot = [0 .45 .74]; colTherm = [.75 .15 .1];

% ---- states ----
state = zeros(1, nEp);                                % 3 wake, 2 NREM, 1 REM, 0 unscored / other
state(ismember(b, 'w1m')) = 3;
state(ismember(b, 'n2')) = 2;
state(ismember(b, 'r3')) = 1;
artifact = ismember(b, '123');
S = struct('time', tEp, 'state', state, 'b', b);
S.stats = stateStats(b, state, epLen);

% ---- sigma activity ----
S.sigma = [];
if ~isempty(o.eeg)
    [S.sigmaPower, S.sigma, S.sigmaRef] = sigmaActivity(o.eeg, o.fs, nEp, o.sigmaBand, state, artifact);
end

% ---- figure ----
hasT = isstruct(o.thermal) && isfield(o.thermal, 'valueEpoch') && ~isempty(o.thermal.valueEpoch);
hasP = isstruct(o.photometry) && isfield(o.photometry, 'dff') && isfield(o.photometry, 'time') && ~isempty(o.photometry.dff);
panels = {'hypno'};
if ~isempty(S.sigma); panels{end + 1} = 'sigma'; end
if hasT; panels{end + 1} = 'thermal'; end
if hasP; panels{end + 1} = 'photometry'; end
np = numel(panels);
ttl = 'Summary';
if ~isempty(o.title); ttl = ['Summary - ', o.title]; end
fig = figure('Name', ttl, 'NumberTitle', 'off', 'Color', 'w', 'Visible', o.visible, ...
    'Units', 'pixels', 'Position', [80 60 1400 180 + 170 * np]);
left = 0.07; width = 0.66; top = 0.94; gap = 0.035;
h1 = 0.12;                                            % hypnogram height (normalized)
hRest = (top - 0.08 - h1 - gap * (np - 1)) / max(np - 1, 1);
ax = gobjects(1, np);
y = top;
for i = 1:np
    hi = hRest; if i == 1; hi = h1; end
    if np == 1; hi = h1 * 2; end
    y = y - hi;
    ax(i) = axes('Parent', fig, 'Position', [left, y, width, hi], 'TickDir', 'out', 'Box', 'off', 'FontSize', 9);
    y = y - gap;
    hold(ax(i), 'on')
end
xEnd = nEp * epLen / 3600;

for i = 1:np
    a = ax(i);
    switch panels{i}
        case 'hypno'
            % thin grey stairs for the transitions, thick coloured segments for the states
            lv = state; lv(lv == 0) = NaN;
            xs = (0:nEp) * epLen / 3600;
            stairs(a, xs, [lv, lv(end)], 'Color', [.6 .6 .6], 'LineWidth', 0.5);
            levels = [3 2 1]; cols = {colW, colN, colR};
            for k = 1:3
                e = find(state == levels(k));
                if isempty(e); continue; end
                X = [(e - 1); e; nan(size(e))] * epLen / 3600;
                Y = repmat(levels(k), 3, numel(e)); Y(3, :) = NaN;
                line(a, X(:), Y(:), 'Color', cols{k}, 'LineWidth', 5);
            end
            m = find(b == 'm');
            if ~isempty(m)
                plot(a, tEp(m), 3.35 * ones(size(m)), 'v', 'MarkerSize', 3, 'Color', [.3 .3 .3], 'MarkerFaceColor', [.3 .3 .3]);
            end
            a.YLim = [0.5 3.6]; a.YTick = 1:3; a.YTickLabel = {'REM', 'NREM', 'Wake'};
            title(a, ttl, 'Interpreter', 'none', 'FontWeight', 'normal', 'FontSize', 10);
        case 'sigma'
            v = S.sigma;
            vs = movmedian(v, 3, 'omitnan');               % single-epoch peaks damped
            S.sigmaSmooth = vs;
            vn = v; vn(state ~= 2) = NaN;
            vsn = vs; vsn(state ~= 2) = NaN;
            plot(a, tEp, v, 'Color', [.85 .85 .85], 'LineWidth', 0.5);
            plot(a, tEp, vn, 'Color', 0.45 * colN + 0.55, 'LineWidth', 0.5);
            plot(a, tEp, vsn, 'Color', colN * 0.8, 'LineWidth', 0.9);
            ref = 'mean NREM';
            if ~any(state == 2 & ~artifact); ref = 'median'; end
            ylabel(a, sprintf('sigma %g-%g Hz\n%% of %s', o.sigmaBand, ref));
            a.YLim = robustLim(vsn(isfinite(vsn)), vs(isfinite(vs)), [0.5 99.5]);
            text(a, 1, 1.02, o.eegName, 'Units', 'normalized', 'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', [.4 .4 .4], 'Interpreter', 'none');
        case 'thermal'
            A = o.thermal;
            if isfield(A, 't2Hz') && isfield(A, 'value2Hz') && ~isempty(A.t2Hz)
                plot(a, A.t2Hz(:)' / 3600, A.value2Hz(:)', 'Color', [.82 .82 .82], 'LineWidth', 0.5);
            end
            ve = nan(1, nEp); n = min(nEp, numel(A.valueEpoch)); ve(1:n) = A.valueEpoch(1:n);
            plot(a, tEp, ve, 'Color', colTherm, 'LineWidth', 0.8);
            unit = 'counts';
            if isfield(A, 'unit') && strcmpi(A.unit, 'degC'); unit = [char(176) 'C']; end
            meth = 'ROI'; if isfield(A, 'roiMethod'); meth = A.roiMethod; end
            ylabel(a, sprintf('temperature\n(%s)', unit));
            a.YLim = robustLim(ve(isfinite(ve)), ve(isfinite(ve)), [0.5 99.5]);
            text(a, 1, 1.02, sprintf('thermal video, %s', meth), 'Units', 'normalized', 'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', [.4 .4 .4], 'Interpreter', 'none');
            S.thermal = struct('time', tEp, 'value', ve, 'unit', unit);
        case 'photometry'
            P = o.photometry;
            tp = double(P.time(:)') / 3600;
            d = double(P.dff(:)'); d(~isfinite(d)) = NaN;
            fsP = 1 / median(diff(double(P.time(:))));
            ds = movmean(d, max(1, round(10 * fsP)), 'omitnan');
            skip = 0;
            if isfield(P, 'params') && isfield(P.params, 'skipStart'); skip = P.params.skipStart / 3600; end
            fitted = tp > skip;
            yl = robustLim(ds(fitted & isfinite(ds)), d(fitted & isfinite(d)), [0.5 99.5]);
            if skip > 0
                patch(a, [0 skip skip 0], yl([1 1 2 2]), [.93 .93 .93], 'EdgeColor', 'none');
            end
            plot(a, tp, d, 'Color', [.82 .82 .82], 'LineWidth', 0.5);
            plot(a, tp, ds, 'Color', colPhot, 'LineWidth', 0.8);
            ylabel(a, sprintf('dF/F (%%)\n%s', methodLabel(P)));
            a.YLim = yl;
            ch = 'photometry'; if isfield(P, 'channel'); ch = ['photometry, ', P.channel]; end
            text(a, 1, 1.02, ch, 'Units', 'normalized', 'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', [.4 .4 .4], 'Interpreter', 'none');
            S.photometry = struct('time', tp, 'dff', d, 'dff10s', ds);
    end
    a.XLim = [0 xEnd];
    if i < np; a.XTickLabel = []; end
end
xl = 'hours since the first sample';
st = startText(o.startTime);
if ~isempty(st); xl = sprintf('hours since %s', st); end
xlabel(ax(end), xl);
linkaxes(ax, 'x');
ax(1).XLim = [0 xEnd];

% ---- click to navigate in VeryScore3 ----
if ~isempty(o.navigate)
    for i = 1:np
        set(ax(i), 'ButtonDownFcn', @(src, ev) goTo(src, o.navigate, nEp, epLen));
        set(allchild(ax(i)), 'HitTest', 'off');
    end
end

% ---- statistics ----
annotation(fig, 'textbox', [0.75, 0.08, 0.24, 0.86], 'String', statsText(S.stats, nEp, epLen), ...
    'EdgeColor', 'none', 'FontName', 'Consolas', 'FontSize', 9, 'VerticalAlignment', 'top', 'Interpreter', 'none');
end

%% ======================================================================= helpers
function [p, pct, ref] = sigmaActivity(x, fs, nEp, band, state, artifact)
% power in the band of every 4-s epoch (Welch, 2-s Hann windows, half overlap), in % of the NREM mean
L = 4 * fs;
n = min(nEp, floor(numel(x) / L));
X = reshape(double(x(1:n * L)), L, n);
X = X - mean(X, 1);
[pw, f] = pwelch(X, hann(2 * fs), fs, 2 * fs, fs);
inBand = f >= band(1) & f <= band(2);
p = nan(1, nEp);
p(1:n) = sum(pw(inBand, :), 1) * (f(2) - f(1));
p(artifact) = NaN;
use = state == 2 & isfinite(p);
if any(use); ref = mean(p(use)); else; ref = median(p(isfinite(p))); end
pct = 100 * p / ref;
end

function st = stateStats(b, state, epLen)
% minutes, % of the scored time, bouts and mean bout duration of each state
names = {'Wake', 'NREM', 'REM'}; lv = [3 2 1];
scored = state > 0;
st = struct('state', names, 'minutes', 0, 'percent', 0, 'bouts', 0, 'meanBout', NaN);
for k = 1:3
    is = state == lv(k);
    st(k).minutes = sum(is) * epLen / 60;
    st(k).percent = 100 * sum(is) / max(1, sum(scored));
    d = diff([0, is, 0]);
    starts = find(d == 1); ends = find(d == -1);
    st(k).bouts = numel(starts);
    if ~isempty(starts); st(k).meanBout = mean(ends - starts) * epLen; end
end
st(1).microarousals = sum(b == 'm');
st(1).artifactEpochs = sum(ismember(b, '123'));
st(1).unscoredEpochs = sum(~scored);
end

function s = statsText(st, nEp, epLen)
scoredPct = 100 * (1 - st(1).unscoredEpochs / nEp);
lines = {sprintf('Recording  %.2f h (%d epochs)', nEp * epLen / 3600, nEp), ...
    sprintf('Scored     %.1f %%', scoredPct), '', ...
    sprintf('%-5s %6s %7s %6s %8s', 'State', '%', 'min', 'bouts', 'mean (s)')};
for k = 1:3
    lines{end + 1} = sprintf('%-5s %6.1f %7.1f %6d %8.1f', st(k).state, st(k).percent, st(k).minutes, st(k).bouts, st(k).meanBout); %#ok<AGROW>
end
lines = [lines, {'', sprintf('Microarousals    %d', st(1).microarousals), ...
    sprintf('Artifact epochs  %d', st(1).artifactEpochs), sprintf('Unscored epochs  %d', st(1).unscoredEpochs)}];
s = strjoin(lines, newline);
end

function yl = robustLim(main, all, pr)
% y limits from the percentiles of the main values (fallback: all values), with a margin
v = main;
if numel(v) < 10; v = all; end
if isempty(v); yl = [0 1]; return; end
yl = prctile(v, pr);
if ~(yl(2) > yl(1)); yl = [min(v) max(v)]; end
if ~(yl(2) > yl(1)); yl = yl(1) + [-1 1]; end
yl = yl + [-1 1] * 0.08 * diff(yl);
end

function s = startText(t)
s = '';
if isempty(t); return; end
try
    if ~isdatetime(t); t = datetime(char(t), 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS'); end
    s = char(string(t, 'HH:mm:ss (yyyy-MM-dd)'));
catch
    s = char(string(t));
end
end

function s = methodLabel(P)
s = '';
if isfield(P, 'method')
    if strcmp(P.method, 'purple'); s = 'purple baseline'; else; s = 'exponential baseline'; end
end
end

function goTo(src, fcn, nEp, epLen)
x = src.CurrentPoint(1, 1);                           % hours
ep = min(max(floor(x * 3600 / epLen) + 1, 1), nEp);
try
    fcn(ep);
catch
end
end
