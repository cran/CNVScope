% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/averageMatrixEdges.R
\name{averageMatrixEdges}
\alias{averageMatrixEdges}
\title{Average edges of a matrix to facilitate downsampling.}
\usage{
averageMatrixEdges(unchangedmatrix, nedges = 1, dimension = c("row", "column"))
}
\arguments{
\item{unchangedmatrix}{A matrix to have edges averaged with genomic coordinates in the form chr1_50_100 set as the column and row names.}

\item{nedges}{The number of edges to be averaged}

\item{dimension}{Selectively averages edges in one dimension. Performs symmetric edge averaging by default.}
}
\value{
averaged_matrix A matrix with edges averaged, which may be more amenable to downsampling
}
\description{
Averages the columns and rows of a matrix by a certain amount.
}
\examples{
load(system.file("extdata","nbl_result_matrix_sign_small.rda",package = "CNVScope"))
dim(nbl_result_matrix_sign_small)
nbl_result_matrix_sign_small_avg<-averageMatrixEdges(nbl_result_matrix_sign_small,
nedges=1,dimension="row")
dim(nbl_result_matrix_sign_small_avg)
nbl_result_matrix_sign_small_avg<-averageMatrixEdges(nbl_result_matrix_sign_small,
nedges=1,dimension="column")
dim(nbl_result_matrix_sign_small_avg)
}
\keyword{average}
\keyword{downsample}
\keyword{edges}
\keyword{matrix}
\keyword{rescale}
