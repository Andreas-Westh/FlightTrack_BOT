library(httr)
library(jsonlite)

url <- "https://opensky-network.org/api/states/all"

gaza_bbox <- list(
  minLatitude = 31.2201289,
  maxLatitude = 32.5521479,
  minLongitude = 34.0689732,
  maxLongitude = 35.5739235
)



readRenviron(".Renviron")
username <- Sys.getenv("username") 
password <- Sys.getenv("password")

response <- GET(url, query = gaza_bbox, authenticate(username, password))

data <- fromJSON(content(response, as = "text"), flatten = T)

df <- as.data.frame(data$states)
# https://openskynetwork.github.io/opensky-api/rest.html
new_colnames <- c(
  "icao24", "callsign", "origin_country", "time_position", "last_contact", 
  "longitude", "latitude", "baro_altitude", "on_ground", "velocity", 
  "true_track", "vertical_rate", "sensors", "geo_altitude", 
  "squawk", "spi", "position_source")
colnames(df) <- new_colnames
df$time_position <- as.numeric(df$time_position)
df$last_contact <- as.numeric(df$last_contact)

# Opret nye kolonner med konverterede datoer
df$time_position_date <- as.POSIXct(df$time_position, origin = "1970-01-01", tz = "UTC")
df$last_contact_date <- as.POSIXct(df$last_contact, origin = "1970-01-01", tz = "UTC")

# Tjek resultaterne
head(df)

