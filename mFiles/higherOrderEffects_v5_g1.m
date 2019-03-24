%% Prehospital stroke triage - higher order effects
% Ludwig Schlemm, 2018, 2019
% v 5.0.0
% main

clear all

% Definitions for abstract scenarios  
nRuns = 50;       
maxCSC = 4;
maxPSC = 10;
radius = 30;    % units: min; 30 vs 120
resFactor = 200/radius;  % resolution
loadCoordinates = 0;  
saveCoordinates = 0;

% scenario definition
% geographicArea = 'circle';
% geographicArea = 'square';
geographicArea = 'Berlin'; % real-world geographic scenarios

metric = 'Euclidean';
% metric = 'Manhattan';
% metric = 'google';
% metric = 'haversine';
% end scenario definition

switch geographicArea  % force metric to haversine in real-world geographic scenarios
    case 'Berlin'
        metric = 'haversine';
end


%% for real-worl example, define GPS coordinates of centers;
if strcmp(geographicArea, 'Berlin')
    
    resFactor = 300;        % Berlin: 300, Brandenburg: 100
    dat = xlsread('../input/hospital_list.xlsx', 'Berlin', 'C2:N15');
    %     dat = xlsread('../input/hospital_list.xlsx', 'Brandenburg', 'C2:N32');
    CSC_coordinates = dat(dat(:,9) == 1,1:2);
    PSC_coordinates = dat(dat(:,9) == 0,1:2);
    SC_coordinates = [CSC_coordinates; PSC_coordinates];
    
    % shift coordinates to origo = (0, 0);
    xoffset = (max(SC_coordinates(:,1)) + min(SC_coordinates(:,1))) / 2;
    yoffset = (max(SC_coordinates(:,2)) + min(SC_coordinates(:,2))) / 2;
    
    maxPSC = size(PSC_coordinates,1); maxCSC = size(CSC_coordinates,1); nRuns = 1;
    CSC_coordinates = CSC_coordinates - repmat([xoffset yoffset], maxCSC,1);
    PSC_coordinates = PSC_coordinates - repmat([xoffset yoffset], maxPSC,1);
    SC_coordinates = [CSC_coordinates; PSC_coordinates];
    
    radius = max(sqrt(SC_coordinates(:,1).^2) + SC_coordinates(:,2).^2)*2.8;  % Berlin
    %     radius = max(sqrt(SC_coordinates(:,1).^2) + SC_coordinates(:,2).^2)*1.4;  % Brandenburg
    
    
    % load real-word sceanrio boundary
    datBound = xlsread('../input/hospital_list.xlsx', 'Boundary', 'J1:K111'); % Berlin
    %     datBound = xlsread('../input/hospital_list.xlsx', 'BB_Boundary', 'J1:K158'); % Brandenburg
    BerlinBound = datBound;
    
    BerlinBound = BerlinBound - repmat([xoffset yoffset], size(BerlinBound,1),1);
    
    figure('Color', [1 1 1])
    box off
    patch(BerlinBound(:,2), BerlinBound(:,1), [.5 .5 .5])
    hold on;
    plot(CSC_coordinates(:,2),CSC_coordinates(:,1), 'r+');
    plot(PSC_coordinates(:,2),PSC_coordinates(:,1), 'g+');
end


have2min = @(h) 7*h^0.6;      % Berlin
% have2min = @(h) 4*h^0.71;        % Brandenburg

benefitFactor = 2;

% Variables for visualizations
maxRatio = 50;
maxRatioCumul = 100;
xValStep = 0.01;
xVal = [xValStep:xValStep:maxRatioCumul-xValStep]';

%%
for nCSC = maxCSC: maxCSC
    for nPSC = maxPSC: maxPSC
        perc_STArray = zeros(nRuns,1); % relative size of subregion with secondary transfer
        perc_HOTArray = zeros(nRuns,1); % relative size of subregion with higher order triage
        perc_pgmArray = zeros(nRuns,1); % relative size of sub-region with spatial median benefit/harm ratio > benefitFactor
        pgm_medianArray = zeros(nRuns,1, 2); % spatial median benefit/harm ratio
        
        wb_1 = waitbar(0, ['Please wait ... (nCSC: ' num2str(nCSC) ', nPSC: ' num2str(nPSC) ')']);
        for u = 1: nRuns
            if ~strcmp(geographicArea, 'Berlin') && loadCoordinates == 0  % create random stroke center coordinates in abstract environments
                % Init
                CSC_coordinates = zeros(nCSC, 2);
                i = 1;
                while i <= nCSC
                    y = rand()*radius*2 - radius;
                    x = rand()*radius*2 - radius;
                    dOrigo = sqrt(x^2 + y^2);
                    if dOrigo <= radius || strcmp(geographicArea, 'square')
                        CSC_coordinates(i,:) = [y, x];
                        i = i+1;
                    end
                end
                clear i x y dOrigo
                
                PSC_coordinates = zeros(nPSC, 2);
                j = 1;
                while j <= nPSC
                    y = rand()*radius*2 - radius;
                    x = rand()*radius*2 - radius;
                    dOrigo = sqrt(x^2 + y^2);
                    if dOrigo <= radius || strcmp(geographicArea, 'square')
                        PSC_coordinates(j,:) = [y, x];
                        j = j+1;
                    end
                end
                clear j x y dOrigo
                
                if saveCoordinates  % save random stroke center coordinates in abstract environments
                    CSC_coordinatesToSave = CSC_coordinates / radius;
                    PSC_coordinatesToSave = PSC_coordinates / radius;
                    save('coordinates.mat', 'CSC_coordinatesToSave', 'PSC_coordinatesToSave', 'nPSC', 'nCSC')
                end
                clear CSC_coordinatesToSave PSC_coordinatesToSave
            elseif ~strcmp(geographicArea, 'Berlin') && loadCoordinates == 1 % load random stroke center coordinates in abstract environments
                load('coordinates.mat');
                CSC_coordinates = CSC_coordinatesToSave * radius;
                PSC_coordinates = PSC_coordinatesToSave * radius;
                clear CSC_coordinatesToSave PSC_coordinatesToSave
            end
            
            nSteps = ceil(2*radius*resFactor+1);
            gridArray = zeros(nSteps, nSteps, 3);
            gridArrayBerlin = zeros(nSteps, nSteps, 10, 6);
            
            PSC_coordinates2plot = (PSC_coordinates + radius)*resFactor + 1;
            CSC_coordinates2plot = (CSC_coordinates + radius)*resFactor + 1;
            
            if strcmp(geographicArea, 'Berlin')
                BerlinBound2plot = (BerlinBound + radius)*resFactor + 1;  % rescale geographic boundary of real-world scenario for plotting
            end 
            
            PSCtoCSC = zeros(nPSC, 1); % calculate distances from PSCs to nearest CSC
            for p = 1: nPSC
                y = PSC_coordinates(p, 1);
                x = PSC_coordinates(p, 2);
                switch metric
                    case 'Euclidean'
                        PSCtoCSC(p) = min(((y - CSC_coordinates(:,1)).^2 + (x - CSC_coordinates(:,2)).^2).^0.5);
                    case 'Manhattan'
                        PSCtoCSC(p) = min(abs(y - CSC_coordinates(:,1)) + abs(x - CSC_coordinates(:,2)));
                    case 'haversine'
                        haverMin = 1000000;
                        for j = 1: nCSC
                            h = haversine([y+yoffset x+xoffset], [CSC_coordinates(j,1)+yoffset CSC_coordinates(j,2)+xoffset]);
                            if h < haverMin
                                haverMin = h;
                            end
                        end
                        PSCtoCSC(p) = have2min(haverMin);
                        clear haverMin h
                end
            end
            clear p y x
            
            % Main
            for yIndex = 1:nSteps % loop through geographic locations - y
                waitbar(((u-1)*nSteps + yIndex)/(nRuns*nSteps), wb_1)
                y = -radius + (yIndex-1) / resFactor;
                for xIndex = 1: nSteps % loop through geographic locations - x
                    x = -radius +  (xIndex-1) / resFactor;
                    
                    dOrigo = sqrt(x^2 + y^2);
                    % if location outside of reion of interest, continue
                    if (dOrigo > radius && strcmp(geographicArea, 'circle')) || strcmp(geographicArea, 'Berlin') && (~inpolygon(x,y,BerlinBound(:,2),BerlinBound(:,1)) && strcmp(geographicArea, 'Berlin'))
                        classifier = 64;
                        gridArray(yIndex, xIndex,1) = classifier;
                        gridArrayBerlin(yIndex, xIndex,:, 1) = classifier;
                        continue;
                    end
                    clear dOrigo
                    
                    % calculate distances to nearest CSC and all PSCs
                    switch metric
                        case 'Euclidean'
                            dCSC_min = min(((y - CSC_coordinates(:,1)).^2 + (x - CSC_coordinates(:,2)).^2).^0.5);
                            dPSC = ((y - PSC_coordinates(:,1)).^2 + (x - PSC_coordinates(:,2)).^2).^0.5;
                        case 'Manhattan'
                            dCSC_min = min(abs(y - CSC_coordinates(:,1)) + abs(x - CSC_coordinates(:,2)));
                            dPSC = abs(y - PSC_coordinates(:,1)) + abs(x - PSC_coordinates(:,2));
                        case 'haversine'
                            haverMin = 1000000;
                            for j = 1: nCSC
                                h = haversine([y+yoffset x+xoffset], [CSC_coordinates(j,1)+yoffset CSC_coordinates(j,2)+xoffset]);
                                if h < haverMin
                                    haverMin = h;
                                end
                            end
                            dCSC_min = have2min(haverMin);
                            clear haverMin h
                            
                            dPSC = zeros(nPSC, 1);
                            for j = 1: nPSC
                                h = haversine([y+yoffset x+xoffset], [PSC_coordinates(j,1)+yoffset PSC_coordinates(j,2)+xoffset]);
                                dPSC(j) = have2min(h);
                            end
                            clear  h  
                    end
                    dCSCviaPSC = dPSC + PSCtoCSC;
                    
                    % calculate number of transport destination options,
                    % and benefit/harm ratios
                    [dPSC_sorted, dPSC_sorted_index] = sort(dPSC);
                    [dCSCviaPSC_sorted, dCSCviaPSC_sorted_index] = sort(dCSCviaPSC);
                    
                    dPSC_base = dPSC_sorted(1);
                    dCSCviaPSC_base = dCSCviaPSC(dPSC_sorted_index(1));
                    
                    classifier = 0;
                    gainMetricPSC = 0;
                    gainMetricCSC = 0;
                    
                    if dCSC_min > dPSC_base
                        for i = 1: nPSC
                            dPSC_curr = dPSC(i);
                            dCSCviaPSC_curr = dCSCviaPSC(i);
                            if ~any(dPSC < dPSC_curr & dCSCviaPSC < dCSCviaPSC_curr) && dPSC_curr < dCSC_min
                                classifier = classifier + 1;
                                newGainMetricPSC = -(dCSCviaPSC_curr - dCSCviaPSC_base) / (dPSC_curr - dPSC_base);
                                newGainMetricCSC = (dCSC_min - dPSC_curr) / (dCSCviaPSC_curr + doorOut - dCSC_min);
                                
                                if newGainMetricPSC > gainMetricPSC && dPSC_curr ~= dPSC_base && dPSC_curr < dCSC_min
                                    gainMetricPSC = newGainMetricPSC;
                                end
                                if newGainMetricCSC > gainMetricCSC && dPSC_curr ~= dPSC_base
                                    gainMetricCSC = newGainMetricCSC;
                                end
                            end
                        end
                    end
           
                    gridArray(yIndex, xIndex,1) = classifier;
                    gridArray(yIndex, xIndex,2) = gainMetricPSC;
                    gridArray(yIndex, xIndex,3) = gainMetricCSC;
                end
            end
            clear yIndex xIndex x y dCSC dPSC dCSC_min dCSCviaPSC dPSC_sorted dPSC_sorted_index dCSCviaPSC_sorted dCSCviaPSC_sorted_index classifier
            clear dPSC_curr dCSCviaPSC_curr i newGainMetricPSC gainMetricPSC
            
            % Results
            classif = gridArray(:,:,1);
            gm = gridArray(:,:,2); % gainMetricPSC
            % secondary transfer among whole geographic area
            perc_ST = sum(classif < 64 & classif >= 1) / sum(classif < 64);
            
            % higher orders transfer among  whole geographic area
            perc_HOT = sum(classif < 64 & classif >= 2) / sum(classif < 64);
            
            % gainMetric > benefitFactor among  higher order transfer area
            perc_pgm = sum(classif < 64 & classif >= 2 & gm >= benefitFactor) / sum(classif < 64) / perc_HOT;
            
            % median of gainMetric
            pgm_MedianPSC = median(gm(classif < 64 & classif >= 2));
            
            gm = gridArray(:,:,3);
            pgm_MedianCSC = median(gm(classif < 64 & classif >= 2));

           
            perc_STArray(u) = perc_ST;
            perc_HOTArray(u) = perc_HOT;
            perc_pgmArray(u) = perc_pgm;
            pgm_medianArray(u, 1:2) = [pgm_MedianPSC, pgm_MedianCSC];
        end
        close(wb_1)
       
        
        % Save data
        fileName = ['../output/' geographicArea '/' metric '/' num2str(nRuns) '/' geographicArea '_' metric '_' num2str(nCSC) '_' num2str(nPSC) '_' num2str(nRuns)];
        save(fileName, 'perc_STArray', 'perc_HOTArray', 'perc_pgmArray', 'pgm_medianArray')
        
        if nRuns > 0
            continue;
        end
        
        % plot exemplary visualization of triage sub-regions
        figure 
        cmp = colormap('bone');
        %         cmp = colorgrad(64);
        close;
        for f = 1: 5
            c = classif;
            switch f
                case 1
                    c(c>=1 & c<64) = 2;
                    c(c==64) = 3;
                    figure1 = figure('Color',[1 1 1]);
                    axes1 = axes('Parent',figure1,'Layer','top','FontWeight','bold','DataAspectRatio',[1 1 1]);
                    hold(axes1,'all');
                    image(c, 'CDataMapping','direct')
                    colormap(cmp([1, 30, 64],:));
                    if strcmp(metric, 'Manhattan') && strcmp(geographicArea, 'circle') || 1
                        cmb = colorbar;
                        set(cmb, 'YTick', [1:2])
                        set(cmb, 'YTickLabel', {'', ''})
                        set(cmb, 'YLim', [.5, 2.5])
                        set(cmb, 'XTick', [1:2])
                        set(cmb, 'XTickLabel', {'', ''})
                        set(cmb, 'XLim', [.5, 2.5])
                        set(cmb, 'Location', 'NorthOutside')
                    end
                case 2
                    c(c>1 & c<64) = 3;
                    c(c==1) = 2;
                    c(c==64) = 4;
                    figure2 = figure('Color',[1 1 1]);
                    axes2 = axes('Parent',figure2,'Layer','top','FontWeight','bold','DataAspectRatio',[1 1 1]);
                    hold(axes2,'all');
                    image(c, 'CDataMapping','direct')
                    colormap(cmp([1, 30, 40, 64],:));
                    if strcmp(metric, 'Manhattan') && strcmp(geographicArea, 'circle') || 1
                        cmb = colorbar;
                        set(cmb, 'YTick', [1:3])
                        set(cmb, 'YTickLabel', {'', '', ''})
                        set(cmb, 'YLim', [.5, 3.5])
                        set(cmb, 'XTick', [1:3])
                        set(cmb, 'XTickLabel', {'', '', ''})
                        set(cmb, 'XLim', [.5, 3.5])
                        set(cmb, 'Location', 'NorthOutside')
                    end
                case 3
                    c(c>1 & c<64) = c(c>1 & c<64)+1;
                    c(c==1) = 2;
                    c(c==64) = 6;
                    figure3 = figure('Color',[1 1 1]);
                    axes3 = axes('Parent',figure3,'Layer','top','FontWeight','bold','DataAspectRatio',[1 1 1]);
                    hold(axes3,'all');
                    image(c, 'CDataMapping','direct')
                    colormap(cmp([1, 30, 40, 50, 60, 64],:));
                    if strcmp(metric, 'Manhattan') && strcmp(geographicArea, 'circle') || 1
                        cmb = colorbar;
                        set(cmb, 'YTick', [1:5])
                        set(cmb, 'YTickLabel', {'', '', '', '', ''})
                        set(cmb, 'YLim', [.5, 5.5])
                        set(cmb, 'XTick', [1:5])
                        set(cmb, 'XTickLabel', {'', '', '', '', ''})
                        set(cmb, 'XLim', [.5, 5.5])
                        set(cmb, 'Location', 'NorthOutside')
                    end
                case 4
                    g = gridArray(:,:,3);
                    g(g >= maxRatio) = maxRatio;
                    g(g <= 0.001) = 64;
                    g(end, end) = 0.01;
                    g(end, end-1) = 64;
                    figure4 = figure('Color',[1 1 1]);
                    axes4 = axes('Parent',figure4,'Layer','top','FontWeight','bold','DataAspectRatio',[1 1 1]);
                    hold(axes4,'all');
                    image(log(g), 'CDataMapping','scaled');
                    colormap('hot');
                case 5
                    g = gridArray(:,:,2);
                    g(g >= maxRatio) = maxRatio;
                    g(g <= 0.001) = 64;
                    g(end, end) = 0.01;
                    g(end, end-1) = 64;
                    figure5 = figure('Color',[1 1 1]);
                    axes5 = axes('Parent',figure5,'Layer','top','FontWeight','bold','DataAspectRatio',[1 1 1]);
                    hold(axes5,'all');
                    image(log(g), 'CDataMapping','scaled');
                    colormap('hot');
            end
            axis off
            
            switch f
                case {4,5}
                    if strcmp(metric, 'Manhattan') && strcmp(geographicArea, 'circle') || 1
                        
                        cmb = colorbar;
                        ll = [0.1, 1, 10, maxRatio];
                        llab = {'','','',''};
                        yl = get(cmb, 'YLim');
                        
                        set(cmb,'YTick', log(ll))
                        set(cmb,'YTickLabel', ll)
                        set(cmb,'YTickLabel', llab)
                        set(cmb, 'YLim', [log(.01), log(maxRatio)])
                        
                        set(cmb, 'Location', 'NorthOutside')
                        
                        set(cmb,'XTick', log(ll))
                        set(cmb,'XTickLabel', ll)
                        set(cmb,'XTickLabel', llab)
                        set(cmb, 'XLim', [log(.01), log(maxRatio)])
                        clear yl
                    end
            end
            hold on
            if f < 4
                plot(PSC_coordinates2plot(:,2), PSC_coordinates2plot(:,1), ...
                    'MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[0 0 0],...
                    'MarkerSize',5,... % 10
                    'Marker','+',...
                    'LineWidth',5,...  % 3
                    'LineStyle','none',...
                    'Color',[0 0 0]);
                plot(CSC_coordinates2plot(:,2), CSC_coordinates2plot(:,1), ...
                    'MarkerFaceColor',[1 1 1],'MarkerEdgeColor',[1 1 1],...
                    'MarkerSize',6,...
                    'Marker','o',...
                    'LineWidth',1,...
                    'LineStyle','none',...
                    'Color',[1 1 1]);
                
                u = 2*radius/nSteps;
                l = .25;
                plot(nSteps*[1-l 0.99], [1 1]*nSteps/30, 'k-+', 'LineWidth', 2)
                switch geographicArea
                    case 'Berlin'
                        text(nSteps*(1-l)+nSteps*l*.2, nSteps/20+nSteps*.03, sprintf('%.0f km', l*2*radius*65.575))
                        patch(BerlinBound2plot(:,2), BerlinBound2plot(:,1), [0 0 0], 'FaceAlpha', 0)
                        
                    otherwise
                        text(nSteps*(1-l)+nSteps*l*.4, nSteps/20+nSteps*.03, sprintf('%d min', l*2*radius))
                end
            end
            xlim([0, 2*radius*resFactor+1]);
            ylim([0, 2*radius*resFactor+1]);
            
            if strcmp(geographicArea, 'Berlin')
                pbaspect([68677.9, 111267.3, 1])
            end
            export_fig(sprintf('..\\Figures\\Figure_%d\\Figure_%d_%d_%d_%s_%s_exp', [f,f, nCSC, nPSC, geographicArea, metric]), '-nocrop', '-tif', '-r600')
        end
    end
end

%% plot distribution of benefit/harm ratios in real-world scenarios
if strcmp(geographicArea, 'Berlin') 
    for i =2:3
        figure1 = figure('Color',[1 1 1], 'Units','Centimeter', 'Position', [7 5 3.9 3]);
        ha = tight_subplot(1,1,0,[0.2 0],[0 0.1]);
        axes(ha(1))
        g = gridArray(:, :,i);
        g = g(c>1 & c < 64);
        hist(log(g), sqrt(length(g)))
        h = findobj(gca,'Type','patch');
        set(h, 'FaceColor',[0.8471    0.1608         0])
        set(h, 'LineStyle','none')
        box off
%         axis off
        xt = [0.01 1 100];
        set(gca, 'XTick', log(xt))
        set(gca, 'XTickLabel', xt)
        xlim([min(log(xt/10)) max(log(xt))])
        switch i
            case 2
                xlabel('Benefit/harm ratio - PSC')
            case 3
                xlabel('Benefit/harm ratio - CSC')
        end
        ylabel('%')
        yt = [.05 .1 .15 .2];
        set(gca, 'Ytick', length(g)*yt)
        set(gca, 'YtickLabel', sprintf('%.0f %%|', yt*100))
        set(gca, 'YtickLabel', '')
        ylim([0 1500])
        export_fig(sprintf('..\\Figures\\benefitHarmBerlinBB_%d', i), '-nocrop', '-tif', '-r300')
    end
end