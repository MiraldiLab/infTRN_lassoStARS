# infTRN_lassoStARS

This repository contains a workflow for inference of transcriptional regulatory networks (TRNs) from gene expression data and prior information, as described in:

[Miraldi et al., Leveraging chromatin accessibility for transcriptional regulatory network inference in T Helper 17 Cells](https://genome.cshlp.org/content/early/2019/02/19/gr.238253.118).

From gene expression data and tables of prior information, the [example Th17 workflow](Th17_example/example_workflow_Th17.m) can be used to infer a TRN using modified LASSO-StARS, and relies upon [GlmNet in MATLAB](https://web.stanford.edu/~hastie/glmnet_matlab/index.html) to solve the LASSO. Workflow also includes TRN model evaluation based on precision-recall and ROC.

The resulting network can be visualized with TRN visualization software: [jp_gene_viz](https://github.com/simonsfoundation/jp_gene_viz).

Additional workflows are provided for:
* [Construct a prior transcriptional regulatory network from ATAC-seq data](priorConstruction/readme.md)
* [TF-TF module analysis: Discovery of TFs that co-regulate gene pathways](Th17_example/example_Th17_tfTfModules.m)
* [Identify "core" TF regulators for a subset of conditions or celltypes in the gene expression dataset](scTRN)
* [Gene-set enrichment analysis (GSEA) of a TF's positive and repressed target genes](scTRN)
* [Visualize TF degree, positive and negative edges, and overlap with TF-gene interactions in the prior](scTRN/viz_TF_degree.m)
* [Out-of-sample gene expression prediction](Th17_example/example_workflow_Th17_r2Pred.m), including calculation of R<sup>2</sup><sub>pred
* [Modeling of time-series gene expression with linear differential equations](Th17_example/example_workflow_Th17_timeLag.m), as in [Bonneau et al. (2006) Genome Biology](https://genomebiology.biomedcentral.com/articles/10.1186/gb-2006-7-5-r36)

NOTE: For Mac users of MATLAB 2016b or later versions, you might need to install gfortran. We recommend the following: Install [Homebrew](https://brew.sh/), and then install gfortran with the Terminal command: ```"brew cask install gfortran"```.