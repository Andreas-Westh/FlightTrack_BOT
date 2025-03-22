library(RMariaDB)
library(httr)
library(jsonlite)

# User credentials
user <- 
password <- 

# Connect to the database
db <- dbConnect(
  MariaDB(),
  user = "",         # Your database username
  password = "",     # Your database password
  dbname = "",       # The name of your database
  host = ""        # Database host 
)
cat("Connected to the database successfully.\n")

# Fetch flight data
url <- "https://opensky-network.org/api/states/all"
north_korea_bbox <- list(
  lamin = 37.9,  # Tighter southern latitude
  lamax = 42.6,  # Tighter northern latitude
  lomin = 125.0, # Tighter western longitude
  lomax = 130.5  # Tighter eastern longitude
)

# Fetch the data
response <- GET(url, query = north_korea_bbox, authenticate(user = user, password = password))
data <- fromJSON(content(response, as = "text"), flatten = TRUE)

if (is.null(data$states)) {
  stop("No flight data found in the response. Check the API query or authentication credentials.")
}

df <- as.data.frame(data$states)
colnames(df) <- c(
  "icao24", "callsign", "origin_country", "time_position", "last_contact", 
  "longitude", "latitude", "baro_altitude", "on_ground", "velocity", 
  "true_track", "vertical_rate", "sensors", "geo_altitude", 
  "squawk", "spi", "position_source"
)

# Convert `on_ground` from TRUE/FALSE to 1/0
df$on_ground <- as.integer(df$on_ground)
df$spi <- as.integer(df$spi)  # Also convert `spi` if it is a boolean

# Function to log data into the database
log_plane_traffic <- function(db, flight_data) {
  query <- "INSERT INTO dprk_Flights (
              icao24, callsign, origin_country, time_position, last_contact, 
              longitude, latitude, baro_altitude, on_ground, velocity, 
              true_track, vertical_rate, sensors, geo_altitude, 
              squawk, spi, position_source
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
  
  tryCatch({
    dbExecute(db, query, params = list(
      flight_data$icao24, flight_data$callsign, flight_data$origin_country,
      flight_data$time_position, flight_data$last_contact, flight_data$longitude,
      flight_data$latitude, flight_data$baro_altitude, flight_data$on_ground,
      flight_data$velocity, flight_data$true_track, flight_data$vertical_rate,
      flight_data$sensors, flight_data$geo_altitude, flight_data$squawk,
      flight_data$spi, flight_data$position_source
    ))
    cat("Flight data logged successfully: ", flight_data$icao24, "\n")
  }, error = function(e) {
    cat("Error logging flight data:", e$message, "\n")
  })
}

# Log each row in the dataframe
for (i in seq_len(nrow(df))) {
  flight_data <- df[i, ]
  
  # Convert the row to a named list
  flight_data <- as.list(flight_data)
  
  # Log the data
  log_plane_traffic(db, flight_data)
}

# Disconnect from the database
dbDisconnect(db)
cat("Database connection closed.\n")

