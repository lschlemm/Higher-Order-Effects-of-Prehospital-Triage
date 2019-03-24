%% Prehospital stroke triage - higher order effects
% Ludwig Schlemm, 2018
% v 3.0.0
clear all

% Definitions
nRuns = 10;         
maxCSC = 4;
maxPSC = 10;
loadCoordinates = 0;
saveCoordinates = 0;

% scenario definition
% geographicArea = 'circle';
% geographicArea = 'square';
geographicArea = 'Berlin';

radius = 10;    % units: min; 30 vs 120
resFactor = 200/radius;  

metric = 'Euclidean';
% metric = 'Manhattan';
% metric = 'google';
% metric = 'haversine';
% end scenario definition

switch geographicArea
    case 'Berlin'
   metric = 'haversine';     
end


%% for real-worl example, define GPS coordinates of centers;
if strcmp(geographicArea, 'Berlin')
    
    resFactor = 300;        % Berlin: 300, Brandenburg: 100
    dat = xlsread('../input/hospital_list.xlsx', 'Berlin', 'C2:N15');
    %     dat = xlsread('../input/hospital_list.xlsx', 'Brandenburg2', 'C2:N21');
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
    
        radius = max(sqrt(SC_coordinates(:,1).^2) + SC_coordinates(:,2).^2)*2.8;
%     radius = max(sqrt(SC_coordinates(:,1).^2) + SC_coordinates(:,2).^2)*1.4;
    
    
    % load Berlin boundary
        datBound = xlsread('../input/hospital_list.xlsx', 'Boundary', 'J1:K111');
%     datBound = xlsread('../input/hospital_list.xlsx', 'BB_Boundary', 'J1:K158');
    BerlinBound = datBound;
    
    BerlinBound = BerlinBound - repmat([xoffset yoffset], size(BerlinBound,1),1);
    
    figure('Color', [1 1 1])
    box off
    patch(BerlinBound(:,2), BerlinBound(:,1), [.5 .5 .5])
    hold on;
    plot(CSC_coordinates(:,2),CSC_coordinates(:,1), 'r+');
    plot(PSC_coordinates(:,2),PSC_coordinates(:,1), 'g+');
end

load('../input/DALYsIS_Fits.mat');
age = 60;
NIHSSperRACE = [1 4 6 7 9 13 15 18 22 24];
pLVOperRACE = [0 .5 1.5 2.5 4 5 6 7 8 9] / 10;

fo_evt_mean = fo_evt_male_mean;         fo_evt_upper = fo_evt_male_upper;         fo_evt_lower = fo_evt_male_lower;
fo_tpa_mean = fo_tpa_male_mean;         fo_tpa_upper = fo_tpa_male_upper;         fo_tpa_lower = fo_tpa_male_lower;

DTN_CSC = 30;
DTN_PSC = 30;
DTR_mother = 90;
DTR_drip = 60;
doorOut = 60;
pReperfMT = .9;
pEarlyReperf = .2;
earlyReperfTimeFrame = 90;

    have2min = @(h) 7*h^0.6;      % Berlin
% have2min = @(h) 4*h^0.71;        % Brandenburg

RACE_min = 0; RACE_max = 0;

pLVO = .15;
benefitRatio = 2;

% benefitCSC > costPSC
% pLVO * benefitsCSC > (1-pLVO) * costPSC
% pLVO*benefitRatio * timebenefitCSC > (1-pLVO) * timecostPSC
% timebenefitCSC / timecostPSC > (1-pLVO)/pLVO/benefitRatio

benefitFactor = (1-pLVO)/pLVO/benefitRatio;
benefitFactor = 2;

% Variables
maxRatio = 50;
maxRatioCumul = 100;
xValStep = 0.01;
xVal = [xValStep:xValStep:maxRatioCumul-xValStep]';

for nCSC = maxCSC: maxCSC
    for nPSC = maxPSC: maxPSC
        perc_STArray = zeros(nRuns,1);
        perc_HOTArray = zeros(nRuns,1);
        perc_pgmArray = zeros(nRuns,1);
        pgm_medianArray = zeros(nRuns,1, 2);
        
        wb_1 = waitbar(0, ['Please wait ... (nCSC: ' num2str(nCSC) ', nPSC: ' num2str(nPSC) ')']);
        for u = 1: nRuns
            if ~strcmp(geographicArea, 'Berlin') && loadCoordinates == 0
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
                
                if saveCoordinates
                    CSC_coordinatesToSave = CSC_coordinates / radius;
                    PSC_coordinatesToSave = PSC_coordinates / radius;
                   save('coordinates.mat', 'CSC_coordinatesToSave', 'PSC_coordinatesToSave', 'nPSC', 'nCSC') 
                end
                clear CSC_coordinatesToSave PSC_coordinatesToSave
            elseif ~strcmp(geographicArea, 'Berlin') && loadCoordinates == 1
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
                BerlinBound2plot = (BerlinBound + radius)*resFactor + 1;
            end
            
            PSCtoCSC = zeros(nPSC, 1);
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
            for yIndex = 1:nSteps
                waitbar(((u-1)*nSteps + yIndex)/(nRuns*nSteps), wb_1)
                y = -radius + (yIndex-1) / resFactor;
                for xIndex = 1: nSteps
                    x = -radius +  (xIndex-1) / resFactor;
                    
                    dOrigo = sqrt(x^2 + y^2);
                    if (dOrigo > radius && strcmp(geographicArea, 'circle')) || strcmp(geographicArea, 'Berlin') && (~inpolygon(x,y,BerlinBound(:,2),BerlinBound(:,1)) && strcmp(geographicArea, 'Berlin'))
                        classifier = 64;
                        gridArray(yIndex, xIndex,1) = classifier;
                        gridArrayBerlin(yIndex, xIndex,:, 1) = classifier;
                        continue;
                    end
                    clear dOrigo
                    
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
                    
                    [dPSC_sorted, dPSC_sorted_index] = sort(dPSC);
                    [dCSCviaPSC_sorted, dCSCviaPSC_sorted_index] = sort(dCSCviaPSC);
                    
                    dPSC_base = dPSC_sorted(1);
                    dCSCviaPSC_base = dCSCviaPSC(dPSC_sorted_index(1));
                    
                    pEarlyReperf_rand = 0.5;    %rand()/pEarlyReperf;
                    classifier = 0;
                    gainMetricPSC = 0;
                    gainMetricCSC = 0;
                    
                    if strcmp(geographicArea, 'Berlin')  || 0
                        gainMetricDALY_CSC = zeros(10,1);
                        gainMetricDALY_PSC_base = zeros(10,1);
                        gainMetricDALY_PSC = zeros(10,1);
                        newGainMetricDALY_PSC = zeros(10,1);
                        
                        for indivRACE = RACE_min : RACE_max
                            NIHSS = NIHSSperRACE(indivRACE+1);
                            gainMetricDALY_CSC(indivRACE+1) =   (1-pLVOperRACE(indivRACE+1))                                * max(270 - dCSC_min - DTN_CSC, 0) *     fo_tpa_mean(NIHSS, age) + ...
                                pLVOperRACE(indivRACE+1) * ( ...
                                pEarlyReperf * pReperfMT        *  max(390 - dCSC_min - DTN_CSC - min(pEarlyReperf_rand * earlyReperfTimeFrame, DTR_mother - DTN_CSC), 0)    + ...
                                pEarlyReperf * (1 - pReperfMT)  *  max(390 - dCSC_min - DTN_CSC - pEarlyReperf_rand * earlyReperfTimeFrame, 0)                               + ...
                                (1-pEarlyReperf)*  pReperfMT   *  max(390 - dCSC_min - DTR_mother, 0)                                                                        ...
                                ) * fo_evt_mean(NIHSS, age);
                            
                            
                            gainMetricDALY_PSC_base(indivRACE+1) =      (1-pLVOperRACE(indivRACE+1))                                *  max(270 - dPSC_base - DTN_PSC, 0) *    fo_tpa_mean(NIHSS, age) + ...
                                pLVOperRACE(indivRACE+1) * ( ...
                                pEarlyReperf * pReperfMT        *  max(390 - dPSC_base - DTN_PSC - min(pEarlyReperf_rand * earlyReperfTimeFrame, doorOut + dCSCviaPSC_base - dPSC_base + DTR_drip), 0)   + ...
                                pEarlyReperf * (1 - pReperfMT)  *  max(390 - dPSC_base - DTN_PSC - pEarlyReperf_rand * earlyReperfTimeFrame, 0)                                                          + ...
                                (1-pEarlyReperf) *  pReperfMT   *  max(390 - DTN_PSC - doorOut - dCSCviaPSC_base - DTR_drip, 0)                                                                          ...
                                ) * fo_evt_mean(NIHSS, age);
                            
                            gainMetricDALY_PSC(indivRACE+1) = 0;
                        end
                    end
                    
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
                                
                                if strcmp(geographicArea, 'Berlin')  || 0
                                    for indivRACE = RACE_min : RACE_max
                                        NIHSS = NIHSSperRACE(indivRACE+1);
                                        newGainMetricDALY_PSC(indivRACE+1) =    (1-pLVOperRACE(indivRACE+1))                *  max(270 - dPSC_curr - DTN_PSC, 0) *    fo_tpa_mean(NIHSS, age) + ...
                                            pLVOperRACE(indivRACE+1) .* ( ...
                                            pEarlyReperf * pReperfMT                    *  max(390 - dPSC_curr - DTN_PSC - min(pEarlyReperf_rand * earlyReperfTimeFrame, doorOut + dCSCviaPSC_curr - dPSC_curr + DTR_drip), 0)   + ...
                                            pEarlyReperf * (1 - pReperfMT)              *  max(390 - dPSC_curr - DTN_PSC - pEarlyReperf_rand * earlyReperfTimeFrame, 0)                                                          + ...
                                            (1-pEarlyReperf) *  pReperfMT               *  max(390 - DTN_PSC - doorOut - dCSCviaPSC_curr - DTR_drip, 0)                                                                           ...
                                            ) * fo_evt_mean(NIHSS, age);
                                        
                                        if newGainMetricDALY_PSC(indivRACE+1) > gainMetricDALY_PSC(indivRACE+1)  && dPSC_curr ~= dPSC_base && dPSC_curr < dCSC_min
                                            gainMetricDALY_PSC(indivRACE+1) = newGainMetricDALY_PSC(indivRACE+1);
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if strcmp(geographicArea, 'Berlin') || 0
                        for indivRACE = RACE_min : RACE_max
                            if gainMetricDALY_CSC(indivRACE+1) >= gainMetricDALY_PSC_base(indivRACE+1)
                                od = 1; % old destination, 1 = CSC
                                DALD_od = gainMetricDALY_CSC(indivRACE+1);
                            else
                                od = 2; % 2 = PSC
                                DALD_od = gainMetricDALY_PSC_base(indivRACE+1);
                            end
                            
                            if gainMetricDALY_PSC(indivRACE+1) > max(gainMetricDALY_CSC(indivRACE+1), gainMetricDALY_PSC_base(indivRACE+1))
                                nd = 3; % HOT PSC
                                DALD_nd = gainMetricDALY_PSC(indivRACE+1);
                            else
                                nd = od; % new destination
                                DALD_nd = DALD_od;
                            end
                            
                            
                            gridArrayBerlin(yIndex, xIndex, indivRACE+1, 1) = classifier;
                            gridArrayBerlin(yIndex, xIndex, indivRACE+1, 2) = od;                              % original destination
                            gridArrayBerlin(yIndex, xIndex, indivRACE+1, 3) = nd;                              % new destination
                            gridArrayBerlin(yIndex, xIndex, indivRACE+1, 4) = DALD_od;                          % DALD with original destination
                            gridArrayBerlin(yIndex, xIndex, indivRACE+1, 5) = DALD_nd;                       % DALD with new destination
                            gridArrayBerlin(yIndex, xIndex, indivRACE+1, 6) = DALD_nd - DALD_od;             % DALD improvement
                            gridArrayBerlin(yIndex, xIndex, indivRACE+1, 7) = gainMetricDALY_CSC(indivRACE+1);      % DALD CSC
                            gridArrayBerlin(yIndex, xIndex, indivRACE+1, 8) = gainMetricDALY_PSC_base(indivRACE+1);                % DALD PSC_base
                            gridArrayBerlin(yIndex, xIndex, indivRACE+1, 9) = gainMetricDALY_PSC(indivRACE+1);      % DALD PSC_HOT
                            
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
            gm = gridArray(:,:,2);
            % secondary transfer among whole geographic area
            perc_ST = sum(classif < 64 & classif >= 1) / sum(classif < 64);
            
            % higher orders transfer among  whole geographic area
            perc_HOT = sum(classif < 64 & classif >= 2) / sum(classif < 64);
            
            % positive gainMetric among  higher order transfer area
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
%         clear wb_1 perc_ST perc_HOT perc_pgm pgm_condMean pgm_condMean_weighted
        
        
        % Saves
        fileName = ['../output/' geographicArea '/' metric '/' num2str(nRuns) '/' geographicArea '_' metric '_' num2str(nCSC) '_' num2str(nPSC) '_' num2str(nRuns)];
        save(fileName, 'perc_STArray', 'perc_HOTArray', 'perc_pgmArray', 'pgm_medianArray')
        %         clear fileName perc_STArray perc_HOTArray perc_pgmArray pgm_condMeanArray pgm_condMean_weightedArray
        
%         if nRuns > 0
%             continue;
%         end
        % Figure 1
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
                        ll = [0.1 round(benefitFactor*100)/100, 10, maxRatio];
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
%         switch i
%             case 2
%                 xlabel('Benefit/harm ratio - PSC')
%             case 3
%                 xlabel('Benefit/harm ratio - CSC')
%         end
%         ylabel('%')
        yt = [.05 .1 .15 .2];
        set(gca, 'Ytick', length(g)*yt)
        set(gca, 'YtickLabel', sprintf('%.0f %%|', yt*100))
        set(gca, 'YtickLabel', '')
        ylim([0 1500])
        export_fig(sprintf('..\\Figures\\benefitHarmBerlinBB_%d', i), '-nocrop', '-tif', '-r300')
    end
end


break;

%% Addition Berlin results and figures
% figure('Color', [1 1 1])
% g = gridArray(:,:,2); g = reshape(g, [],1); g = g(g>0);
% h = histfit(log(g),25);
% set(h(1), 'FaceColor', [0.6784    0.9216    1.0000]);
% set(h(2), 'Color', [0 0 0]);
% set(h(2), 'LineWidth', 4);
%
% xtn = [0.01 0.1 1 10 100];
% set(gca, 'XTick', log(xtn))
% set(gca, 'XTickLabel', sprintf('%.2f | ', xtn))
%
% lg = length(g);
% yt = [.1 .2 .3] * lg;
% set(gca, 'YTick', yt)
% set(gca, 'YTickLabel',  sprintf('%.0f%% | ', yt/lg*100))
%
% xlim(log([min(xtn) max(xtn)]))
% xlabel('benefit/harm ratio')
% ylabel('%')
% box off

figure('Color', [1 1 1])
h = tight_subplot(RACE_max - RACE_min + 1, 6, 0, 0, 0);
for indivRACE = RACE_min : RACE_max
    for i = 1:3
        switch i
            case 1
                gb = gridArrayBerlin(:,:, indivRACE+1, 2);
                gb(c == 64) = 64;
                gb(c <= 1) = 57;
                gb(gb == 1) = 48;
                gb(gb == 2) = 35;
                gb(gb == 3) = 1;
                gb(end, end) = 0;
            case 2
                gb = gridArrayBerlin(:,:, indivRACE+1, 3);
                gb(c == 64) = 64;
                gb(c <= 1) = 57;
                gb(gb == 1) = 48;
                gb(gb == 2) = 35;
                gb(gb == 3) = 1;
                gb(end, end) = 0;
            case 3
                gb = gridArrayBerlin(:,:, indivRACE+1, 6);
                gb(c == 64) = 64;
                gb(c <= 1) = 57;
                gb(gb == 0) = 48;
                gb(end, end) = 0;
%                 gb(gb == 1) = 48;
%                 gb(gb == 2) = 28;
%                 gb(gb == 3) = 1;
            case 4
                continue;
                gb = gridArrayBerlin(:,:, indivRACE+1, 9) > gridArrayBerlin(:,:, indivRACE+1, 8);
            case 5
                continue;
                gb = gridArrayBerlin(:,:, indivRACE+1, 9) > gridArrayBerlin(:,:, indivRACE+1, 7);
            case 6
                continue;
                gb = gridArrayBerlin(:,:, indivRACE+1, 9) > gridArrayBerlin(:,:, indivRACE+1, 8) & gridArrayBerlin(:,:, indivRACE+1, 9) > gridArrayBerlin(:,:, indivRACE+1, 7);
        end
        axes(h(i + (indivRACE - RACE_min)*6))
        image(flipud(gb), 'CDataMapping', 'scaled')
        axis off
        if strcmp(geographicArea, 'Berlin')
            pbaspect([68677.9, 111267.3, 1])
        else
            pbaspect([1, 1, 1])
        end
    end
    colormap('bone')
end

figure('Color', [1 1 1])
gb = any( gridArrayBerlin(:,:, :, 9) > gridArrayBerlin(:,:, :, 8) & gridArrayBerlin(:,:, :, 9) > gridArrayBerlin(:,:, :, 7), 3);
image(flipud(gb), 'CDataMapping', 'scaled')
axis off
if strcmp(geographicArea, 'Berlin')
    pbaspect([68677.9, 111267.3, 1])
else
    pbaspect([1, 1, 1])
end
colormap('pink')
