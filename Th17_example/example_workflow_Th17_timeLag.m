%% example_workflow_Th17_timeLag
%% _timeLag = classic Inferelator implementation with time-lag for linear 
% differential equations-based modeling of time series gene expression as
% in Bonneau et al. (2006) Genome Biology.
%% Use mLASSO-StARS to build a TRN from gene expression and prior
% information in four steps. Please refer to each function's help
% annotations for descriptions of inputs, outputs and other information.
%% References: 
% (1) Miraldi et al. (2018) "Leveraging chromatin accessibility for 
% transcriptional regulatory network inference in T Helper 17 Cells"
% (2) Qian et al. (2013) "Glmnet for Matlab."
% http://www.stanford.edu/~hastie/glmnet_matlab/
% (3) Liu, Roeder, Wasserman (2010) "Stability Approach to Regularization 
%   Selection (StARS) for High Dimensional Graphical Models". Adv. Neural.
%   Inf. Proc.
% (4) Muller, Kurtz, Bonneau. "Generalized Stability Approach for Regularized
%   Graphical Models". 23 May 2016. arXiv.
% (5) Bonneau et al. "The Inferelator: an algorithm for learning
%   parsimonious regulatory networks from systems biology data sets de
%   novo." (2006) Genome Biology.
%% Author: Emily R. Miraldi, Ph.D., Divisions of Immunobiology and Biomedical
%   Informatics, Cincinnati Children's Hospital
%% Date: July 22, 2018

clear all
close all
restoredefaultpath

matlabDir = '..';

addpath(fullfile(matlabDir,'infLassoStARS'))
addpath(fullfile(matlabDir,'glmnet'))
addpath(fullfile(matlabDir,'customMatlabFxns'))

%% 1. Import gene expression data, list of regulators, list of target genes
% into a Matlab .mat object
geneExprTFAdir = './outputs/processedGeneExpTFA';
mkdir(geneExprTFAdir)
normGeneExprFile = './inputs/geneExpression/th17_RNAseq254_DESeq2_VSDcounts.txt';
targGeneFile = './inputs/targRegLists/targetGenes_names.txt';
potRegFile = './inputs/targRegLists/potRegs_names.txt';
tfaGeneFile = './inputs/targRegLists/genesForTFA.txt';
geneExprMat = fullfile(geneExprTFAdir,'geneExprGeneLists.mat');

disp('1. importGeneExpGeneLists.m')
importGeneExpGeneLists(normGeneExprFile,targGeneFile,potRegFile,...
    tfaGeneFile,geneExprMat)

%% 2. Given a prior of TF-gene interactions, estimate transcription factor 
% activities (TFAs) using prior-based TFA and TF mRNA levels
priorName = 'ATAC_Th17';
priorFile = ['./inputs/priors/' priorName '.tsv']; % Th17 ATAC-seq prior
timeLagFile = './inputs/targRegLists/timeSeriesInfo.txt'; % see integratePrior_estTFA_timeLag.m for format
timeLag = .5; % time lag for Inferelator, should be in same units as timeLagFile (e.g., hr / min...), here units are hours
edgeSS = 50;
minTargets = 3;
[xx, priorName, ext] = fileparts(priorFile);
tfaMat = fullfile(geneExprTFAdir,[priorName '_tLag_ss' num2str(edgeSS) '.mat']);

disp('2. integratePrior_estTFA_timeLag.m')
integratePrior_estTFA_timeLag(geneExprMat,priorFile,edgeSS,...
     minTargets, tfaMat, timeLagFile, timeLag)
 
%% 3. Calculate network instabilities using bStARS
lambdaBias = .5;
tfaOpt = ''; % options are '_TFmRNA' or ''
totSS = 50;
targetInstability = .05;
lambdaMin = .01;
lambdaMax = 1;
extensionLimit = 1;
totLogLambdaSteps = 25; % will have this many steps per log10 within bStARS lambda range
bStarsTotSS = 5;
subsampleFrac = .63;
leaveOutSampleList = '';
leaveOutInf = '';
instabilitiesDir = fullfile('./outputs',strrep(['instabilities_targ' ...
    num2str(targetInstability) '_SS' num2str(totSS) leaveOutInf '_bS' num2str(bStarsTotSS) '_tLag'],'.','p'));
mkdir(instabilitiesDir)
netSummary = [priorName '_bias' strrep(num2str(100*lambdaBias),'.','p') tfaOpt];
instabOutMat = fullfile(instabilitiesDir,netSummary);

disp('3. estimateInstabilitiesTRNbStARS.m')
estimateInstabilitiesTRNbStARS(geneExprMat,tfaMat,lambdaBias,tfaOpt,...
    totSS,targetInstability,lambdaMin,lambdaMax,totLogLambdaSteps,...
    subsampleFrac,instabOutMat,leaveOutSampleList,bStarsTotSS,extensionLimit)

%% 4. For a given instability cutoff and model size, rank TF-gene
% interactions, calculate stabilities and network file for jp_gene_viz
% visualizations
priorMergedTfsFile = ['./inputs/priors/' priorName '_mergedTfs.txt'];
try % not all priors have merged TFs and merged TF files
    ls(priorMergedTfsFile) 
catch
    priorMergedTfsFile = '';
end
meanEdgesPerGene = 15;
targetInstability = .05;
networkDir = strrep(instabilitiesDir,'instabilities','networks');
instabSource = 'Network';
mkdir(networkDir);
networkSubDir = fullfile(networkDir,[instabSource ...
    strrep(num2str(targetInstability),'.','p') '_' ...
    num2str(meanEdgesPerGene) 'tfsPerGene']);
mkdir(networkSubDir)
trnOutMat = fullfile(networkSubDir,netSummary);
outNetFileSparse = fullfile(networkSubDir,[netSummary '_sp.tsv']);
networkHistDir = fullfile(networkSubDir,'Histograms');
mkdir(networkHistDir)
subsampHistPdf = fullfile(networkHistDir,[netSummary '_ssHist']);

disp('4. buildTRNs_mLassoStARS.m')
buildTRNs_mLassoStARS(instabOutMat,tfaMat,priorMergedTfsFile,...
    meanEdgesPerGene,targetInstability,instabSource,subsampHistPdf,trnOutMat,...
    outNetFileSparse)

%% 5. Calculate precision-recall 
gsFile = './inputs/priors/KC1p5_sp.tsv';
prNickName = 'KC1p5';
rankColTrn = 3;
prTargGeneFile = './inputs/priors/goldStandardGeneLists/targGenesPR_mm9mm10.txt';
gsRegsFile = '';
prDir = fullfile(networkSubDir,['PR_' prNickName]);
mkdir(prDir)
prMatBase = fullfile(prDir,netSummary);
prFigBase = fullfile(prDir,netSummary);

display('5. calcPRinfTRNs')
calcPRinfTRNs(outNetFileSparse,gsFile,rankColTrn,...
    prTargGeneFile,gsRegsFile,prMatBase,prFigBase)


