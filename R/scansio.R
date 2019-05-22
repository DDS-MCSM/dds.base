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
