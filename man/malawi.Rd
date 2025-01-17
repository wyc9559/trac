% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{malawi}
\alias{malawi}
\title{malawi vs venezuela, adults only}
\format{
A phyloseq object:
\describe{
\item{otu_table}{OTU count table with 54 rows corresponding to subjects
and 5008 columns corresponding to OTUs}
\item{tax_table}{Taxonomic table with the taxonomic assignment on different
levels for the OTUs. The names of the OTUs are saved in the rownames.
The 5008 rows correspond to the different OTUS and the 7 columns to
the different levels of the taxonomic tree (Kingdom, Phylum, Class,
Order, Family, Genus, Species)}
\item{sam_data}{Meta data about the different observations. Contains
the labels Vars and additional covariates sex (binary) and age (numeric)}
}
}
\usage{
malawi
}
\description{
This is a subset of the "malawi vs venezuela, adults only" task from the
\href{https://knights-lab.github.io/MLRepo/docs/yatsunenko_malawi_venezuela.html}{Microbiome Learning Repo}.
The task is to predict whether the individuals live in Malawi or Venezuela
based on the OTU count table.
OTUs that occur in less than 10\% of the samples are excluded. Only
Bacteria are included. The
taxonomic table for the OTUs was obtained by the \href{https://www.nature.com/articles/ismej2011139?report=reader}{greengenes reference database}.
The data was originally published in \href{https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3376388/}{Yatsunenko, T., Rey, F. E., Manary, M. J., Trehan, I., Dominguez-Bello, M. G., Contreras, M., ... & Gordon, J. I. (2012). Human gut microbiome viewed across age and geography. nature, 486(7402), 222-227.}.
}
\keyword{datasets}
