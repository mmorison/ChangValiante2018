function [events, thresholdFrequency, thresholdIntensity, thresholdDuration, indexArtifact, thresholdAmplitudeOutlier] = classifier_dynamic (events, plotFigures)
%classifier_dynamic will classify a population (>6) of epilpeptiform events
%into two different populations (IIEs and SLEs)
%   The threshold to classify populations of epileptiform events are based
%   are drawn from three different methods of calculation, hard-codes based
%   on the in vitro ictal event population, Michael's calculation based on
%   emperical data, and k-means clustering (in combinations with the widest
%   gap).

%% Set Variables according to Michael's terms
userInput(3) = plotFigures;  %1 = yes; 0 = no
indexEventsToAnalyze = events(:,7)<4;

if nargin < 2
    userInput(3) = 0    %by default don't plot any figures
end

%% Stage 1: Artifact (Outlier) removal 
%Remove outliers based on peak-to-peak amplitude
featureSet = events(:,6);   %peak-to-peak amplitude values
thresholdAmplitudeOutlier = mean(featureSet)+(3.1*std(featureSet));  %Michael's custom threshold
indexArtifact = events(:,6) > thresholdAmplitudeOutlier;  %implement a while-loop, so it repeats until all outliers are gone
index = indexArtifact; %Generic Terms

if sum(indexArtifact)>0   %I wonder if this if statement will speed up the code by allowing it to skip a few lines       
    %Plot figure if artifacts detected within events
    if userInput(3) == 1      
        figArtifact = figure;
        gscatter(events(:,6) , events(:,6), index);    %plot index determined by Michael's Threshold
        hold on
        %plot Michael Chang's threshold values 
        plot ([thresholdAmplitudeOutlier thresholdAmplitudeOutlier], ylim);
        %Label
        set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
        set(gcf,'Name', 'Remove events containing artifact, using Peak-to-Peak Amplitude (mV)'); %select the name you want
        title ('Unsupervised classication, using k-means clustering');
        ylabel ('Peak-to-Peak Amplitude (mV)');
        xlabel ('Peak-to-Peak Amplitude (mV)');   
        legend('Epileptiform Events', 'Artifact', 'Michaels Artifact Threshold')
        legend ('Location', 'southeast')
        set(gca,'fontsize',12)
    end

    %Remove artifact, based on Michael's threshold 
    events (indexArtifact, 7) = 4;  %%Label the event containing an artifact as '4'
    events (indexArtifact, 12) = 1;
    %Make new index without the artifacts
    indexEventsToAnalyze = events(:,7)<4;
end

%% Stage 2: Unsupervised Classifier 
% classify based on average frequency 
featureSet = events(:,4);   %Average Spike Rate (Hz)
%Michael's threshold
michaelsFrequencyThreshold = 1; %Hz  
%Algo determined threshold
[algoFrequencyIndex, algoFrequencyThreshold] = sleThresholdFinder (events(indexEventsToAnalyze,4));
%Use the lowest threshold, unless it's below 1 Hz
if algoFrequencyThreshold >= 1
    thresholdFrequency = algoFrequencyThreshold;
else
    thresholdFrequency = michaelsFrequencyThreshold;    %michael's threshold frequency is the lowest frequency for SLEs
end
%Event is a SLE if larger than threshold
indexFrequency = featureSet>=thresholdFrequency;  
events (:,9) = indexFrequency;
%Plot figure
    if userInput(3) == 1  
    %plot figure
    index = indexFrequency;   %convert to generic name for plotting
    featureThreshold = thresholdFrequency;  %convert to generic name for plotting
    figFrequency = figure;
    gscatter(featureSet , featureSet, index);      
    hold on
    %plot the algorithm detected threshold
    plot ([algoFrequencyThreshold algoFrequencyThreshold], ylim); 
    %plot Michael Chang's threshold  
    plot ([michaelsFrequencyThreshold michaelsFrequencyThreshold], ylim);
    %plot threshold that was used
    plot ([featureThreshold featureThreshold], ylim);
    
    %Label
    set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
    set(gcf,'Name', 'Feature Set: Spiking Rate (Hz)'); %select the name you want    
    title ('Unsupervised classication, using k-means clustering');
    ylabel ('Spiking Rate (Hz)');
    xlabel ('Spiking Rate (Hz)');   
        if numel(unique(indexFrequency))>1  %legend depends on what's present
            legend('IIE', 'SLE', 'Algo Threshold', 'Michaels Threshold', 'Frequency Threshold')
        else if unique(indexFrequency)==1
                legend('SLE', 'Algo Threshold', 'Michaels Threshold', 'Frequency Threshold')
            else
                legend('IIE', 'Algo Threshold', 'Michaels Threshold', 'Frequency Threshold')
            end
        end                                  
    legend ('Location', 'southeast')
    set(gca,'fontsize',12)
    end


% classify based on average intensity 
featureSet = events(:,5);   %Average intensity (Power/Duration)
%Michael's threshold
if mean(events(indexEventsToAnalyze,5))>std(events(indexEventsToAnalyze,5))
    michaelIntensityThreshold = mean(events(indexEventsToAnalyze,5))-std(events(indexEventsToAnalyze,5));
else 
    michaelIntensityThreshold = mean(events(indexEventsToAnalyze,5));
end
%Algo determined threshold 
[algoIntensityIndex, algoIntensityThreshold] = sleThresholdFinder (events(indexEventsToAnalyze,5));

%use the lower threshold for Intensity, (with a floor at 10 mV^2/s)
if algoIntensityThreshold < 10 && michaelIntensityThreshold < 10
    thresholdIntensity = 10;
else if algoIntensityThreshold<=michaelIntensityThreshold
        thresholdIntensity = algoIntensityThreshold;
    else
        thresholdIntensity = michaelIntensityThreshold;
    end
end

%determine the index for SLE and IIE using threshold for Intensity (feature)
indexIntensity = featureSet>=thresholdIntensity;
events (:,10) = indexIntensity; %store in array

    if userInput(3) == 1  
    %plot figure
    index = indexIntensity;
    featureThreshold = thresholdIntensity;
    figIntensity = figure;
    gscatter(featureSet , featureSet, index);    %plot scatter plot
    hold on
    %plot the algorithm detected threshold
    plot ([algoIntensityThreshold algoIntensityThreshold], ylim); 
    %plot Michael Chang's threshold values 
    plot ([michaelIntensityThreshold michaelIntensityThreshold], ylim);
    %plot threshold that was used
    plot ([featureThreshold featureThreshold], ylim);
    
    %Label
    set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
    set(gcf,'Name', 'Feature Set: Intensity (Power/Duration)'); %select the name you want    
    title ('Unsupervised classication, using k-means clustering');
    ylabel ('Average Intensity (Power/Duration)');
    xlabel ('Average Intensity (Power/Duration)');   
        if numel(unique(indexIntensity))>1  %legend depends on what's present
                legend('IIE', 'SLE', 'Algo Threshold', 'Michaels Threshold', 'Intensity Threshold')
            else if unique(indexIntensity)==1
                    legend('SLE', 'Algo Threshold', 'Michaels Threshold', 'Intensity Threshold')
                else
                    legend('IIE', 'Algo Threshold', 'Michaels Threshold', 'Intensity Threshold')
                end
            end    
    legend ('Location', 'southeast')
    set(gca,'fontsize',12)
    end
 
%% Initial Classifier (Filter)
for i = 1: numel(events(:,1))
    if (indexFrequency(i) + indexIntensity(i)) == 2 & events(i,7) <4    %and not an artifact
        events (i,7) = 1;   %1 = SLE; 2 = IIE; 3 = IIS; 0 = unclassified
    else if (indexFrequency(i) + indexIntensity(i)) < 2 & events(i,7) <4
            events (i,7) = 2;   %2 = IIE
        else            
            events (i,7) = 4;   %4 = event contains an artifact
        end
    end    
end

indexPutativeSLE = events (:,7) == 1;  %classify which ones are SLEs
putativeSLE = events(indexPutativeSLE, :);

%Second Filter using duration
averageSLEDuration=mean(putativeSLE(:,3));
sigmaSLEDuration = std(putativeSLE(:,3));

%% Stage 3: Classify based on Class 1 dataset, using duration as a feature
%classify based on duration
featureSet = events(:,3);   %Duration (s)
%Michael's threshold, use the one that is higher, conservative
if averageSLEDuration-(2*sigmaSLEDuration) > sigmaSLEDuration
    michaelsDurationThreshold=averageSLEDuration-(2*sigmaSLEDuration);
else
    michaelsDurationThreshold=sigmaSLEDuration;  
end

%Algo deteremined threshold (tend to be higher value)
[algoDurationIndex, algoDurationThreshold] = sleThresholdFinder (events(indexEventsToAnalyze,3));

%Use the lowest threhsold, unless it's below 3 s (the floor)
if algoDurationThreshold < 3 || michaelsDurationThreshold < 3
    thresholdDuration = 3;
else if michaelsDurationThreshold <= algoDurationThreshold
        thresholdDuration = michaelsDurationThreshold;
    else
        thresholdDuration = algoDurationThreshold;
    end
end

indexDuration = featureSet>thresholdDuration; 
events(:,11) = indexDuration;

    if userInput(3) == 1  
    %plot figure
    index = indexDuration;
    featureThreshold = thresholdDuration;
    figDuration = figure;
    gscatter(featureSet , featureSet, index);    %plot scatter plot
    hold on
    %plot the algorithm detected threshold
    plot ([algoDurationThreshold algoDurationThreshold], ylim); 
    %plot Michael Chang's threshold values 
    plot ([michaelsDurationThreshold michaelsDurationThreshold], ylim);
    %plot threshold that was used
    plot ([featureThreshold featureThreshold], ylim); 
    %Label
    set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
    set(gcf,'Name', 'Feature set: Duration (sec)'); %select the name you want
    title ('Unsupervised classication, using k-means clustering');
    ylabel ('Duration (sec)');
    xlabel ('Duration (sec)');   
        if numel(unique(indexDuration))>1  %legend depends on what's present
                legend('IIE', 'SLE', 'Algo Threshold', 'Michaels Threshold', 'Duration Threshold')
        else if unique(indexDuration)==1
                    legend('SLE', 'Algo Threshold', 'Michaels Threshold', 'Duration Threshold')
            else
                    legend('IIE', 'Algo Threshold', 'Michaels Threshold', 'Duration Threshold')
            end
        end       
    legend ('Location', 'southeast')
    set(gca,'fontsize',12)
    end

%% Final Classifier (assignment)

for i = 1: numel(events(:,1))
    if indexFrequency(i) + indexIntensity(i) + indexDuration(i) == 3 & events (i,7) <4
        events (i,7) = 1;   %1 = SLE; 2 = IIE; 3 = IIS; 0 = unclassified.
        else if indexFrequency(i) + indexIntensity(i) + indexDuration(i) < 3 & events (i,7) < 4
                events (i,7) = 2;
                else
                events (i,7) = 4;
            end
    end
end        

end

