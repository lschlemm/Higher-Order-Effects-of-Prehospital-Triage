%% Prehospital stroke triage - higher order effects
% Ludwig Schlemm, 2018
% v 3.0.0
% subroutine display of results


% Definitions
nRuns = 50;
maxCSC = 4;
maxPSC = 10;

geographicArea = 'circle';
% geographicArea = 'square';
% geographicArea = 'Berlin';

metric = 'Euclidean';
% metric = 'Manhattan';
% metric = 'google';

pgm_medianPSC = zeros(maxPSC, nRuns, maxCSC);
pgm_medianCSC = zeros(maxPSC, nRuns, maxCSC);

perc_pgm = zeros(maxPSC, nRuns, maxCSC);
perc_ST = zeros(maxPSC, nRuns, maxCSC);
perc_HOT = zeros(maxPSC, nRuns, maxCSC);


for nCSC = 1: maxCSC
    for nPSC = 2: maxPSC
    % load files
    fileName = ['../output/' geographicArea '/' metric '/' num2str(nRuns) '/' geographicArea '_' metric '_' num2str(nCSC) '_' num2str(nPSC) '_' num2str(nRuns)];
    load(fileName)
    clear fileName
    
    perc_ST(nPSC, :, nCSC) = perc_STArray;  % relative size region with secondary transfer
    perc_HOT(nPSC, :, nCSC) = perc_HOTArray; % relative size region with higher order triage
    pgm_medianPSC(nPSC, :, nCSC) = pgm_medianArray(:,1); % spatial median benefit/harm ratio
    pgm_medianCSC(nPSC, :, nCSC) = pgm_medianArray(:,2); % spatial median benefit/harm ratio
    perc_pgm(nPSC, :, nCSC) = perc_pgmArray; % relative size of sub-region with spatial median benefit/harm ratio > benefitFactor
    end
end
pgm_medianPSC = pgm_medianPSC(2:end,:,:);
pgm_medianCSC = pgm_medianCSC(2:end,:,:);
perc_pgm = perc_pgm(2:end,:,:);
perc_ST = perc_ST(2:end,:,:);
perc_HOT = perc_HOT(2:end,:,:);

%% plot boxplots of relative sizes of triage sub-regions
figure1 = figure('Color',[1 1 1], 'Units','Centimeter', 'Position', [7 5 8 12]);
h1 = tight_subplot(2,1,[.02 .03],[.08 .02],[.16 .01]);
axes(h1(1));
aboxplot(perc_ST)
box off
colormap('bone');

set(gca, 'XTickLabel', {'', '', ''}, 'FontWeight', 'bold')
ylim([0 1])
set(gca, 'YTick', [.2 .4 .6 .8])
set(gca, 'YTickLabel', [20 40 60 80])

yl = ylabel('%A_{>1}','FontWeight', 'bold');
% yl = ylabel('%(# of triage options > 1)','FontWeight', 'bold');
yl = ylabel('% of geographical area','FontWeight', 'bold');

p = get(yl, 'position');
set(yl,'position', [0.15, p(2), p(3)])
clear p yl


sprintf('perc ST median: max / min \n')
perc_ST_med = median(perc_ST,2);
perc_ST_med = reshape(perc_ST_med, [],1);
max(perc_ST_med)
min(perc_ST_med)

axes(h1(2))
aboxplot(perc_HOT)
box off
colormap('bone');
% set(gca, 'XTickLabel', {'CSC=1', 'CSC=2', 'CSC=3', 'CSC=4'}, 'FontWeight', 'bold')
set(gca, 'XTickLabel', {'1', '2', '3', '4'}, 'FontWeight', 'bold')
xlabel('Number of CSCs','FontWeight', 'bold')
ylim([0 1])
set(gca, 'YTick', [.2 .4 .6 .8])
set(gca, 'YTickLabel', [20 40 60 80])
yl = ylabel('%A_{>2}','FontWeight', 'bold');
% yl = ylabel('%(# of triage options > 2)','FontWeight', 'bold');
yl = ylabel('% of geographical area','FontWeight', 'bold');

p = get(yl, 'position');
set(yl,'position', [0.15, p(2), p(3)])
clear p yl

sprintf('perc HOT median: max / min \n')
perc_HOT_med = median(perc_HOT,2);
perc_HOT_med = reshape(perc_HOT_med, [],1);
max(perc_HOT_med)
min(perc_HOT_med)

% legend
cm = colorgrad(9);
xStart = 3;
yStart = .88;
l = .3;
w = 2;
xOffset = .2;
yOffset = .06;
for i=1:9
    col = ceil(i/3)-1;
    row = mod(i-1, 3);
    line([xStart xStart+l]+(l+xOffset)*col, [yStart yStart]-yOffset*row, 'Color', cm(i,:), 'LineWidth', w);
    text(xStart+l+(l+xOffset)*col + xOffset/4, yStart-yOffset*row, num2str(i+1), 'FontSize', 7)
end
text(xStart, yStart+0.08, sprintf('# of PSCs'), 'FontWeight', 'bold', 'FontSize', 8)
% export_fig(sprintf('..\\Figures\\BoxplotFigures\\Figure_1_%s_%s', [geographicArea, metric]), '-nocrop', '-tif', '-r600')

%% plot boxplots of spatial medians of benefit harm ratios
figure2 = figure('Color',[1 1 1], 'Units','Centimeter', 'Position', [7 5 8 12]);
h2 = tight_subplot(2,1,[.02 .03],[.08 .02],[.16 .01]);
axes(h2(1));
aboxplot(pgm_medianPSC)
box off
colormap('bone');
set(gca, 'XTickLabel', {'', '', ''}, 'FontWeight', 'bold');
ylim([0 3])
set(gca, 'YTick', [.5 1 1.5 2 2.5])
set(gca, 'YTickLabel', [.5 1 1.5 2 2.5])
yl = ylabel('median BHR_{PSC}','FontWeight', 'bold');
p = get(yl, 'position');
set(yl,'position', [0.15, p(2), p(3)])
clear p yl

sprintf('perc pgm_pos  max / min \n')
perc_pgm_med = median(perc_pgm,2);
perc_pgm_med = reshape(perc_pgm_med, [],1);
max(perc_pgm_med)
min(perc_pgm_med)

pgm_medianPSC_med = reshape(pgm_medianPSC, [],1);
sprintf('percentile pgm_medianPSC all \n')
prctile(pgm_medianPSC_med, [0 25 50 75 100])

pgm_medianPSC_s = pgm_medianPSC(4,:,2);
sprintf('percentile pgm_medianPSC 2 CSC / 5 PSC \n')
prctile(pgm_medianPSC_s, [0 25 50 75 100])



axes(h2(2));
aboxplot((pgm_medianCSC))
box off
colormap('bone');
set(gca, 'XTickLabel', {'1', '2', '3', '4'}, 'FontWeight', 'bold')
xlabel('Number of CSCs','FontWeight', 'bold')
ylim([0 3])
set(gca, 'YTick', [.5 1 1.5 2 2.5])
set(gca, 'YTickLabel', [.5 1 1.5 2 2.5])
yl = ylabel('median BHR_{CSC}','FontWeight', 'bold');
p = get(yl, 'position');
set(yl,'position', [0.15, p(2), p(3)])
clear p yl


pgm_medianCSC_med = reshape(pgm_medianCSC, [],1);
sprintf('percentile pgm_medianCSC all \n')
prctile(pgm_medianCSC_med, [0 25 50 75 100])

pgm_medianCSC_s = pgm_medianCSC(4,:,2);
sprintf('percentile pgm_medianCSC 2 CSC / 5 PSC \n')
prctile(pgm_medianCSC_s, [0 25 50 75 100])

% legend
axes(h2(2));
cm = colorgrad(9);
xStart = 3;
yStart = 2.5;
l = .3;
w = 2;
xOffset = .2;
yOffset = .18;
for i=1:9
    col = ceil(i/3)-1;
    row = mod(i-1, 3);
    line([xStart xStart+l]+(l+xOffset)*col, [yStart yStart]-yOffset*row, 'Color', cm(i,:), 'LineWidth', w);
    text(xStart+l+(l+xOffset)*col + xOffset/4, yStart-yOffset*row, num2str(i+1), 'FontSize', 7)
end
text(xStart, yStart+0.22, sprintf('# of PSCs'), 'FontWeight', 'bold', 'FontSize', 8)
% export_fig(sprintf('..\\Figures\\BoxplotFigures\\Figure_2_%s_%s', [geographicArea, metric]), '-nocrop', '-tif', '-r600')