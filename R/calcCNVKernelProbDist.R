#' Calculate the probability distribution of CNV concordance events with a fast kernel
#'
#' This function produces several matrices, including a Z-score matrix
#' from a matrix of the same size
#' and a percentile matrix of these Z-scores
#' @name calcCNVKernelProbDist
#' @param submatrix A matrix of CNV data in an intrachromosomal region (e.g. chr1 vs chr1 or chr5 vs chr5)
#' @param win a window size for the matrix that calculates the windowed average using the kernel function
#' @param debug extra output for debugging.
#' @param parallel use parallelization using mcmapply and doParallel?
#' @param mcmcores The number of cores used for parallelization.
#' @keywords CNV kernel probability distribution concordance fast
#' @import doParallel
#' @importFrom foreach foreach
#' @importFrom Matrix bandSparse sparseMatrix
#' @examples
#' load(system.file("extdata","nbl_result_matrix_sign_small.rda",package = "CNVScope"))
#' mat_prob_dist<-calcCNVKernelProbDist(nbl_result_matrix_sign_small,parallel=FALSE)
#' mat_prob_dist
#' @export
globalVariables(c("x","y"))
calcCNVKernelProbDist<-function(submatrix=NULL,win=5,debug=F,parallel=T,mcmcores=1)
{
  x <- if(exists("x")){get("x")} else {NULL}
  y <- if(exists("y")){get("y")} else {NULL}
  submatrix<-as.matrix(submatrix)
  #win<-5
  #library(spatialfil)
  
  if(debug) {win_start <- proc.time()}
  if(requireNamespace("smoothie",quietly = T)){
  # k = list(matrix=matrix(1/(win^2),nrow=win,ncol=win),kernel='custom')
  # class(k)='convKern'
  # submatrix_win_avg = spatialfil::applyFilter(submatrix,k)
  submatrix_win_avg=smoothie::kernel2dsmooth( submatrix, kernel.type="boxcar", n=win)
  } else{
    return("Please Install package smoothie to use this optional function./n
           This can be done by installing CNVScope using the dependencies=T flag")
    }
  if(debug){
    print("win avg complete")
    print(proc.time() - win_start)
  }
  if(debug){diag_avg_start<-proc.time()}
  diag_avg_matrix<-matrix(0,ncol=ncol(submatrix),nrow=nrow(submatrix))
  if(debug){
    print("diag avg complete")
    print(proc.time() - diag_avg_start)
  }
  if(debug){diag_sd_start<-proc.time()}
  diag_sd_matrix<-matrix(0,ncol=ncol(submatrix),nrow=nrow(submatrix))
  if(debug){
    print("diag sd complete")
    print(proc.time() - diag_sd_start)
  }
  if(!parallel){foreach::registerDoSEQ()}
  if(parallel){doParallel::registerDoParallel()}
  #if(parallel){registerdoParallel()}
  coladjustments2<-foreach(y=c(nrow(submatrix),1),.combine="rbind") %dopar%
  {
    coladjustments<-foreach::foreach(x=1:ncol(submatrix),
    .export=ls(),.combine="rbind" ,.inorder=T) %dopar% 
    {
      if(debug){loop_start<-proc.time()}
      off_diag_for_point<-submatrix[row(submatrix)==col(submatrix)-(y-x)]
      diag_avg<-mean(off_diag_for_point)
      diag_sd<-sd(off_diag_for_point)
      #diag_avg_matrix[row(diag_avg_matrix)==col(diag_avg_matrix)-(y-x)]<-diag_avg
      #diag_sd_matrix[row(diag_sd_matrix)==col(diag_sd_matrix)-(y-x)]<-diag_sd
      #if(x==319){Heatmap(diag_sd_matrix,cluster_columns = F,cluster_rows=F,
      #show_row_names = F,show_column_names = F)}
      diff<-(y-x)
      output<-c(diff,y,x,diag_avg,diag_sd)
      #names(output)<-c("diff","y","x")
      
      if(debug){
        print(paste0(x/ncol(submatrix)*100,"% complete"))
        print(proc.time()-loop_start)
      }
      #print((unlist(ls())))
      #sapply(ls(),function (x) x==Inf)
      output
    }
    colnames(coladjustments)<-c("diff","x","y","diag_avg","diag_sd")
    coladjustments
  }
  diag_sd_vec<-coladjustments2[,"diag_sd"]
  diag_sd_vec[is.na(diag_sd_vec)]<-0
  coladjustments2[,"diag_sd"]<-diag_sd_vec
  if(parallel==T)
  {
    bands_mcmapply<-mcmapply(FUN=function(x,y,diag_avg)
    {
      rep(diag_avg,length(diag_avg_matrix[row(diag_avg_matrix)==col(diag_avg_matrix)-(y-x)]))
    },x=coladjustments2[,"x"],y=coladjustments2[,"y"],diag_avg=coladjustments2[,"diag_avg"],
    mc.cores=mcmcores
    )
    bands<-bands_mcmapply[c(1:(length(bands_mcmapply)/2),
                            (length(bands_mcmapply)/2+2):length(bands_mcmapply))]
    #bands_unique<-unique(bands)
  } else {
    bands_mapply<-mapply(FUN=function(x,y,diag_avg)
    {
      rep(diag_avg,length(diag_avg_matrix[row(diag_avg_matrix)==col(diag_avg_matrix)-(y-x)]))
    },x=coladjustments2[,"x"],y=coladjustments2[,"y"],diag_avg=coladjustments2[,"diag_avg"]
    )
    bands<-bands_mapply[c(1:(length(bands_mapply)/2),
                            (length(bands_mapply)/2+2):length(bands_mapply))]
    
    #bands_unique<-unique(bands)
  }
  diag_avg_matrix<-as.matrix(Matrix::bandSparse(n=nrow(submatrix),m=ncol(submatrix),bands,
                                            k=c(-(nrow(submatrix)-1):(ncol(submatrix)-1)),
                                                symmetric = F,giveCsparse = T))
  #this case will work for symmetric matrices, untested on asymmetric.
  if(parallel==T)
  {
    bands_mcmapply<-mcmapply(FUN=function(x,y,diag_sd)
    {
      rep(diag_sd,length(diag_sd_matrix[row(diag_sd_matrix)==col(diag_sd_matrix)-(y-x)]))
    },x=coladjustments2[,"x"],y=coladjustments2[,"y"],diag_sd=coladjustments2[,"diag_sd"],
    mc.cores=mcmcores
    )
    bands<-bands_mcmapply[c(1:(length(bands_mcmapply)/2),
                            (length(bands_mcmapply)/2+2):length(bands_mcmapply))]
    #bands_unique<-unique(bands)
  } else {
    bands_mapply<-mapply(FUN=function(x,y,diag_sd)
    {
      rep(diag_sd,length(diag_sd_matrix[row(diag_sd_matrix)==col(diag_sd_matrix)-(y-x)]))
    },x=coladjustments2[,"x"],y=coladjustments2[,"y"],diag_sd=coladjustments2[,"diag_sd"]
    )
    bands<-bands_mapply[c(1:(length(bands_mapply)/2),
                            (length(bands_mapply)/2+2):length(bands_mapply))]
    #bands_unique<-unique(bands)
  }
  #browser()
  diag_sd_matrix<-as.matrix(Matrix::bandSparse(n=nrow(submatrix),
    m=ncol(submatrix),bands,k=c(-(nrow(submatrix)-1):(ncol(submatrix)-1)),
    symmetric = F,giveCsparse = T)) #this case will work for symmetric matrices, untested on asymmetric.
  diag_avg_matrix<-t(diag_avg_matrix)
  diag_sd_matrix<-t(diag_sd_matrix)
  zscore_matrix<-(submatrix_win_avg-diag_avg_matrix)/(diag_sd_matrix)
  zscore_matrix[1,ncol(zscore_matrix)]<-0
  zscore_matrix[ncol(zscore_matrix),1]<-0
  percentile_matrix<-pnorm((submatrix_win_avg-diag_avg_matrix)/diag_sd_matrix)
  output_list<-list(zscore_matrix,percentile_matrix,submatrix,
                    coladjustments2,diag_avg_matrix,diag_sd_matrix)
  names(output_list)<-c("zscore_matrix","percentile_matrix","original_matrix",
                        "coladjustments2","diag_avg_matrix","diag_sd_matrix")
  return(output_list)
}

