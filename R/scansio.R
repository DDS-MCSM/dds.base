#' Download and parse FTP connections from Rapid7 Open Data sonar project
#'
#' @param dirdata
#'
#' @return data.frame
#' @export
#'
#' @examples
#' \dontrun{
#' raw.ftps <- download.ftp.scans.io()
#' }
download.ftp.scans.io <- function(dirdata = "data") {
  scansio.url <- "https://opendata.rapid7.com/sonar.tcp/2019-04-04-1554350684-ftp_21.csv.gz"

  dir.data <- file.path(getwd(), dirdata)
  if (!dir.exists(dir.data)) {
    dir.create(dir.data)
  }

  scansio.source <- file.path(dir.data, "scans.io.tcp21.csv")
  scansio.file.gz <- paste(scansio.source, ".gz", sep = "")
  download.file(url = scansio.url, destfile = scansio.file.gz)
  R.utils::gunzip(scansio.file.gz)
  df.tcp21 <- read.csv(scansio.source, stringsAsFactors = FALSE)
  file.remove(scansio.file.gz, scansio.source)

  saveRDS(object = df.tcp21, file = file.path(dir.data, "scansio.tcp21.rds"))

  return(df.tcp21)
}

#' Load FTP data set from Rapid7 and add IP geolocation data, providing a tidy data set.
#'
#' @param scope number of observations. Warning: if scope > 1000 it will use multiple cores.
#' @param dirdata path where raw data and tidy data frames will be stored
#' @param seed used to select the scope observations
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{
#' ftps <- getScansioFTPs()
#' }
getScansioFTPs <- function(scope = 500, dirdata = "data", seed = 666) {
  set.seed(seed)
  dir.data <- file.path(getwd(), dirdata)
  if (!dir.exists(dir.data)) {
    dir.create(dir.data)
  }

  print("[*] Load source data sets")
  if (file.exists(file.path(dirdata, "scansio.tcp21.rds"))) {
    df <- readRDS(file.path(dirdata, "scansio.tcp21.rds"))
  } else {
    df <- download.ftp.scans.io(dirdata)
  }
  if (file.exists(file.path(dirdata, "maxmind.rds"))) {
    df.maxmind <- readRDS(file.path(dirdata, "maxmind.rds"))
  } else {
    df.maxmind <- download.maxmind(dirdata)
  }

  print("[*] Prepare scans.io data.frame")
  # Seleccionamos una muestra de scans
  df <- df[sample(1:nrow(df), scope),]

  # Transformamos las IPs a formato decimal
  df$saddr.num <- iptools::ip_to_numeric(df$saddr)
  df$daddr.num <- iptools::ip_to_numeric(df$daddr)

  print("[*] Find IP geolocation data")
  # Geolocalizamos las IPs origen y destino
  geo.src <- addIPgeolocation(ips = df$saddr,
                              df.maxmind = df.maxmind,
                              boost = scope > 1000)
  geo.dst <- addIPgeolocation(ips = df$daddr,
                              df.maxmind = df.maxmind,
                              boost = scope > 1000)

  print("[*] Tidy data frame")
  names(geo.src) <- paste("src_", names(geo.src), sep = "")
  names(geo.dst) <- paste("dst_", names(geo.dst), sep = "")
  # Preparamos el data frame
  df <- dplyr::bind_cols(df, geo.src, geo.dst)
  df$dst_is_anonymous_proxy <- as.factor(df$dst_is_anonymous_proxy)
  df$src_is_anonymous_proxy <- as.factor(df$src_is_anonymous_proxy)
  df$dst_is_satellite_provider <- as.factor(df$dst_is_satellite_provider)
  df$src_is_satellite_provider <- as.factor(df$src_is_satellite_provider)

  df <- dplyr::select(df, timestamp_ts, ttl,
                      saddr, sport, src_network, src_latitude, src_longitude,
                      src_accuracy_radius, src_is_anonymous_proxy, src_is_satellite_provider,
                      daddr, dport, dst_network, dst_latitude, dst_longitude,
                      dst_accuracy_radius, dst_is_anonymous_proxy, dst_is_satellite_provider)

  saveRDS(object = df, file = file.path(dir.data, "df_ftps.rds"))

  return(df)
}
