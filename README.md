# Package dds.base

<!-- badges: start -->
<!-- badges: end -->

The goal of dds.base is to provide tidy data sets for data driven security purposes.

## Installation

You can install the released version of dds.base from [Github](https://github.com/DDS-MCSM/dds.base) with:

``` r
devtools::install_.packages_github("DDS-MCSM/dds.base")
```

## Getting tidy data sets

### FTP connections with geolocation info

```{r}
library(dds.base)
tini <- Sys.time()
ftps10k <- dds.base::getScansioFTPs(scope = 10000, seed = 42)
fini <- Sys.time()
fini - tini
```


## Rapid7 Open data sets

**[TODO]** *Detailed description of project, data sets, motivation, possible correlations, etc...*

### Scans.io  

**[TODO]** *Detailed description of data sets, variables, motivation, possible correlations, etc...*

 - FTP connections [TCP/21](https://opendata.rapid7.com/sonar.tcp/)

``` r
library(dds.base)
ftps <- getScansioFTPs()
```
Or load sample data frame with 500, 1000 or 10.000 random observations

```{r}
ftps <- readRDS("data/df500_ftps.rds")
```

## MaxMind data sets

**[TODO]** *Detailed description of project, data sets, motivation, possible correlations, etc...*
