# CLUSTER MOTIFS BASED ON SANDELIN WASSERMANN 2004
# GET NWK-TREE AND SETS OF HIGH SIMILARITY
#################################################
###################### Setup for "moca_blue" enviroment
NAME0="rdf5_epm"
SPEC ="Arth-Atha"
MODEL="S0" # C0 stand for DeepCistrome version 1 (available at 02-may-2023) Standard conditions
TYPE ="_cwm-motifs.jaspar"
#######################################################
#FILE1 = paste0(NAME0,SPEC,MODEL,TYPE)
FILE1 = "rdf5_epmArth-Atha_S0_cwm-motifs.jaspar"
#######################################################
folder_name <- paste0(SPEC, "_", MODEL)
dir.create(folder_name, showWarnings = FALSE)
#######################################################
dirpath_in = "../mo_nom/out/"
dirpath_out = "./out/"
setwd("/home/ibg-4/Desktop/Rhome/moca_blue/mo_clu") 
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
File1 <- paste0(dirpath_in,FILE1)
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
library(grid)
library(TFBSTools)
library(motifStack)
library(universalmotif)
library(ape)
library(ggtree)
library(ggplot2)
library(ggseqlogo)
library(Cairo)

# ##################################################
 cwm1 <- read_jaspar(File1)
##################################################
# Loop through each motif object in the list
for (i in seq_along(cwm1)) {
  # Extract the motif name and the number after the last "_" underscore
  motif_name <- attr(cwm1[[i]], "name")
  nsites <- as.numeric(sub(".+_(\\d+)$", "\\1", motif_name))
  # Assign the nsites value to the "nsites" field of the motif object
  cwm1[[i]]["nsites"] <- nsites
}
##################################################
# Loop through each motif object in the list
for (i in seq_along(cwm1)) {
  # Extract the Total IC and the Consensus values from the motif object
  total_ic <- attr(cwm1[[i]], "icscore")
  total_ic_rounded <- round(total_ic, 1)
  consensus <- attr(cwm1[[i]], "consensus")
  # Combine the Total IC and the Consensus values separated by "_" to the motif name
  motif_name <- attr(cwm1[[i]], "name")
  new_motif_name <- paste0(motif_name, "_", total_ic_rounded, "_", consensus)
  # Assign the new motif name to the motif object
  attr(cwm1[[i]], "name") <- new_motif_name
}
##################################################
pwm_uni0<-convert_motifs(
  cwm1, class = "TFBSTools-PWMatrix")
pcm<-convert_motifs(
  cwm1, class = "motifStack-pcm")
##################################################
#ggseqlogo(pcm[[1]]@mat)
#pcm[[1]]@name
# Your existing code to generate the sequence logo
#seq_logo <- ggseqlogo(pcm[[1]]@mat)
#seq_logo <- seq_logo + theme_minimal() + theme(
#  plot.background = element_rect(fill = "white"),
#  panel.background = element_rect(fill = "white"),
#  legend.background = element_rect(fill = "white")
# Save the plot with custom width and height
#ggsave("your_plot.png", plot = seq_logo, width = 4831, height = 592, units = "px")
pcm_length <- length(pcm)  # Getting the length of the pcm object
for (i in 1:pcm_length) {
  seq_logo <- ggseqlogo(pcm[[i]]@mat)
  seq_logo <- seq_logo + theme_minimal() + theme(
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    legend.background = element_rect(fill = "white")
  )
  # Save the plot with custom width and height
  file_name <- paste0(pcm[[i]]@name, ".png")
  file_path <- file.path(folder_name, file_name)
  ggsave(file_path, plot = seq_logo, width = 4831, height = 592, units = "px")
}
##################################################
sum<-as.data.frame(summarise_motifs(pcm))
write.csv(sum, file = paste0(dirpath_out,FILE1,"summary.txt"))
##################################################
##########################################################
c<-compare_motifs(cwm1, method = "SW")
c0<-as.data.frame(c)
c1 <- as.matrix(c0)
lower_percentile <- quantile(c1, probs = 0.05)
upper_percentile <- quantile(c1, probs = 0.95)
##############         ####################      ##################
##############         ####################      ##################
c2 <- c0-upper_percentile
c3 <- as.data.frame(ifelse(c2 < 0, 0, 1))
c3$sum <- rowSums(c3)
epms_without_highly_similar_counterparts <- rownames(c3[c3$sum == 2, ])
epms_with_highly_similar_counterparts <- rownames(c3[c3$sum != 2, ])
write.table(epms_without_highly_similar_counterparts, file = paste0(dirpath_out, FILE1, "_epms_without_highly_similar_counterparts-SW.csv"), sep = "\t", col.names = NA, quote = FALSE)
write.table(epms_with_highly_similar_counterparts, file = paste0(dirpath_out, FILE1, "_epms_with_highly_similar_counterparts-SW.csv"), sep = "\t", col.names = NA, quote = FALSE)
write.table(c0, file = paste0(dirpath_out, FILE1, "_matrix-SW.csv"), sep = "\t", col.names = NA, quote = FALSE)
#assign scores from data.frame to branches for selection
comp_1 <- 1-c
comp_1 <- as.dist(comp_1)
#labels <- attr(comp_1, "Labels")
comp_2 <- ape::as.phylo(hclust(comp_1))
comp_2[["edge.length"]] <- comp_2[["edge.length"]]+1
comp_2[["edge.length"]]
# Create a rooted phylo object
phylo_tree <- as.phylo(comp_2)
# Save the tree with positive edge lengths
write.tree(comp_2, file = paste0(dirpath_out, FILE1, "-Sandelin-Wassermann.nwk"))
#################################################
c_pcm<-clusterMotifs(pcm, method = "Smith-Waterman") ### !!! TIME TO GET A COFFEEE !!! ###
hc<- c_pcm
motifs<-pcm[hc$order]
##################################################
write.tree(as.phylo(c_pcm), file = paste0(dirpath_out,FILE1,"-Smith-Waterman.nwk"))

#par(cex = 0.2)
#pdf("output3.pdf", width = 30, height = 40)
#plotMotifLogoStackWithTree(pcm, c_pcm,
#                           treewidth = 1/8,
#                           trueDist = TRUE)
#dev.off()

browseMotifs(pcm,
             layout = c("tree"),
             nodeRadius = 3,
             baseHeight = 30,
             baseWidth = 12,
             width = 100,
             height = 2500)
