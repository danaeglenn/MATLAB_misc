
cd '/Volumes/DANA_HD/EmotionID/Analysis'
anxScores=importdata('VEPAscores.xlsx');
%%
accuracyCutoff=.6;
nsubjects = size(anxScores.data,1);
for sub=1:nsubjects
%Load data
    VEPAdata{sub,1}=importdata(sprintf('%d_EmoID.mat',sub));
    Output{sub,1}=[VEPAdata{sub,1}.matrand(:,2:3) VEPAdata{sub,1}.responses];
    Output_text={'Emotion','Intensity','Response','Responsetime'};
    
for emotion=1:2
%Sort responses by trial type
    indexTrials{emotion,sub}=Output{sub,1}(:,1)==emotion; %indexes whether face was a fear or anger morph
    Responses{sub,emotion}=Output{sub,1}(indexTrials{emotion,sub},:); %sorts accordingly (output_text for col headers)
    Responses_text={'Emotion','Morph','Response','Time'};
for morph=1:15
    indexMorphs{emotion,sub,morph}=Responses{sub,emotion}(:,2)==morph;
    respByMorph{emotion,sub,morph}=Responses{sub,emotion}(indexMorphs{emotion,sub,morph},:);
end

  for emoChoice=1:4
%Index responses by subject response
    indexResp{emoChoice,sub, emotion}=Responses{sub,emotion}(:,3)==emoChoice; %whether subject chose each emotion for each trial
 end;end;end 
 
%  Calculate proportion of emotion choices for each morph / trial type

%corresponding numbers to each emotion: 1=anger, 2=fear, 3=happy, 4=sad
emotion_text={'Anger','Fear','Happy','Sad'};
  %%
%Structure of sumResp table
sumResp_text={'Subject','TrialType','SubjectChoice','MorphIntensity'};
    
  for sub=1:nsubjects
     for emotion=1:2
       for emoChoice=1:4
        for morph = 1:15
            
sumResp(sub,emotion,emoChoice,morph)=sum(Responses{sub,emotion}(indexResp{emoChoice,sub,emotion},2)==morph); 
        end
       end
                if sumResp(sub,emotion,3,1)/sum(respByMorph{emotion,sub,1}(:,3)~=-1) >= accuracyCutoff
                    %will need to change this for full exp analysis because
                    %only one emotion has happy trials
                    keepSub(sub,emotion)=1;
                else 
                     keepSub(sub,emotion)=0;
                end  
       end
  end

  %%
  for emoTrial=1:2
figure('name',sprintf('Weibull - %s',emotion_text{emoTrial}));
axes
hold on
for sub=1:nsubjects
 colors={'r','c','g','b'};
 subplot(3,6,sub)
for emoResp=1:4
 StimLevels=1:15; 
 PercentMorph=0:7.14:100;
 OutOfNum=12*ones(size(StimLevels));
 if emoResp==3
    NumPos=flip(reshape(sumResp(sub,emoTrial,emoResp,:),size(StimLevels)));
 else 
     NumPos=reshape(sumResp(sub,emoTrial,emoResp,:),size(StimLevels));
 end 
 paramsFree = [1 1 0 0]; %estimate threshold and slope, fix guess and lapse rate

%search through this grid of parameter values for seed to be used in iterative parameter search
searchGrid.alpha = 0:.1:15;
searchGrid.beta = -1:.01:1;
searchGrid.gamma = .05;
searchGrid.lambda = .05;
%guess and lapse rate should be symmetric

%fit Weibull
PF=@PAL_Weibull;

[paramsValues] = PAL_PFML_Fit(StimLevels,NumPos,OutOfNum,searchGrid,paramsFree, PF);
paramsVals{sub,emoTrial,emoResp}=paramsValues;

%Create plot
ProportionCorrectObserved=NumPos./OutOfNum; 
StimLevelsFineGrain=[min(StimLevels):max(StimLevels)./1000:max(StimLevels)];
ProportionCorrectModel = PF(paramsValues,StimLevelsFineGrain);
hold on
if emoResp==3
    lineplot(emoResp)=plot(flip(StimLevelsFineGrain),(ProportionCorrectModel),colors{emoResp},'linewidth',2);
    plot(flip(StimLevels),ProportionCorrectObserved,[colors{emoResp},'.'],'markersize',15);

else
    lineplot(emoResp)=plot(StimLevelsFineGrain,ProportionCorrectModel,colors{emoResp},'linewidth',2);
    plot(StimLevels,ProportionCorrectObserved,[colors{emoResp},'.'],'markersize',15);

end 
set(gca, 'fontsize',16);
axis([min(StimLevels) max(StimLevels) 0 1]);

end
end 
subplot(3,6,1)
xlabel(sprintf('Percent %s',emotion_text{emoTrial}));
ylabel('Proportion correct');
set(gca,'Xtick',1:15, 'Xticklabels',round(PercentMorph));
legend(lineplot(1:4),'Anger','Fear','Happiness','Sadness');
 
  end 
 %%
 allSubs=1:nsubjects;
  for emoTrial=1:2
      goodSubs{emoTrial}=allSubs(keepSub(:,emoTrial)==1);
 Params{emoTrial}=cell2mat(paramsVals(goodSubs{emoTrial},emoTrial,emoTrial));
 for measure=4:length(anxScores.data)
 [Rhos(measure,emoTrial), pvals(measure, emoTrial)]=corr(anxScores.data(goodSubs{emoTrial},measure),Params{emoTrial}(:,1),'rows','complete');
fprintf('%s | %s | R=%f, p=%f\n',emotion_text{emoTrial},anxScores.textdata{measure},Rhos(measure,emoTrial),pvals(measure,emoTrial))   
 end
  end 
  