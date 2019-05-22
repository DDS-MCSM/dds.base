#' Download GeoLite2 data set that include geolocation information for network ranges (CIDRs)
#'
#' @param dirdata
#'
#' @return data.frame
#' @export
#'
#' @examples
#' \dontrun{
#' maxmind <- download.maxmind()
#' }
download.maxmind <- function(dirdata = "data") {
  # Maxmind - Obtener datos en crudo (city)
  maxmind.url <- "https://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip"

  dir.data <- file.path(getwd(), dirdata)
  if (!dir.exists(dir.data)) {
    dir.create(dir.data)
  }

  maxmind.file <- file.path(dir.data, "maxmind.zip")
  download.file(url = maxmind.url, destfile = maxmind.file)
  zipfiles <- unzip(zipfile = maxmind.file, list = T)
  maxmind.source <- zipfiles$Name[grep(pattern = ".*GeoLite2-City-Blocks-IPv4.csv", x = zipfiles$Name)]
  unzip(zipfile = maxmind.file, exdir = dir.data, files = maxmind.source)
  maxmind.source <- file.path(dir.data, maxmind.source)
  df.maxmind <- read.csv(maxmind.source, stringsAsFactors = FALSE)
  file.remove(maxmind.source, maxmind.file)
  unlink(file.path(dir.data, "GeoLite2-City-CSV_*"), recursive = T)

  # Maxmind elegante
  df.maxmind <- cbind(df.maxmind, iptools::range_boundaries(df.maxmind$network))
  df.maxmind$rowname <- as.integer(row.names(df.maxmind))
  df.maxmind$range <- NULL

  saveRDS(object = df.maxmind, file = file.path(dir.data, "maxmind.rds"))

  return(df.maxmind)
}

#' Given a vector of IP addresses it returns a data frame with
#' the IP addresses and its geolocation data (lat, long, accuracy and more).
#'
#' @param ips array of characters of IPv4 addresses
#' @param df.maxmind data frame from download.maxmind function
#' @param boost logical default set as FALSE, if TRUE it will use parallel computing using multiple cores
#'
#' @return data.frame
#' @export
#'
#' @examples
#' \dontrun{
#' geoips <- addIPgeolocation(ips = c("8.8.8.8", "147.81.23.1"),
#'                            df.maxmind = download.maxmind())
#' }
addIPgeolocation <- function(ips = "", df.maxmind = data.frame(), boost = FALSE) {
  # Para geolocalizar una IP en un rango comprobaremos si está entre la primera
  # y la ultima ip de cada rango en MaxMind.

  if (all(iptools::is_ipv4(ips))) {
    ips <- iptools::ip_to_numeric(ips)
  }
  df <- data.frame(ip = as.numeric(ips))

  if (boost) {
    # Usamos multiples cpu's para geolocalizar IPs en rangos
    no_cores <- parallel::detectCores() - 1
    cl <- parallel::makeCluster(no_cores)
    parallel::clusterExport(cl, "df.maxmind", envir = environment())
    df$maxmind.rowname <- sapply(ips,
                                 function(ip)
                                   which((ip >= df.maxmind$min_numeric) &
                                           (ip <= df.maxmind$max_numeric)))
    parallel::stopCluster(cl)
    rm(cl, no_cores)
  } else {
    df$maxmind.rowname <- sapply(ips,
                                 function(ip)
                                   which((ip >= df.maxmind$min_numeric) &
                                           (ip <= df.maxmind$max_numeric)))
  }

  df <- dplyr::left_join(df, df.maxmind, by = c("maxmind.rowname" = "rowname"))

  df <- dplyr::select(df, ip, network, latitude, longitude, accuracy_radius,
                      is_anonymous_proxy, is_satellite_provider)

  return(df)
}
