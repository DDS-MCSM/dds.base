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

  # Maxmind elegante
  df.maxmind <- cbind(df.maxmind, iptools::range_boundaries(df.maxmind$network))
  df.maxmind$rowname <- as.integer(row.names(df.maxmind))
  df.maxmind$range <- NULL

  saveRDS(object = df.maxmind, file = file.path(dir.data, "maxmind.rds"))

  return(df.maxmind)
}
