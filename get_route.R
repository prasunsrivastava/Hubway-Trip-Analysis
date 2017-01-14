# script to pull route information from google maps for all unique trips
unique_trips <- trips %>% 
                  select(strt_lat, strt_lon, end_lat, end_lon) %>%
                  unique

# remove all trips with same source and destination
unique_trips <- unique_trips[!(unique_trips$strt_lon == unique_trips$end_lon 
                               &
                             unique_trips$strt_lat == unique_trips$end_lat), ]

from <- unname(apply(unique_trips[,c('strt_lon', 'strt_lat')], 1,
                     function(x) paste(x['strt_lat'], x['strt_lon'], sep = ' ')))
to <- unname(apply(unique_trips[,c('end_lon', 'end_lat')], 1,
                   function(x) paste(x['end_lat'], x['end_lon'], sep = ' ')))
origin_destination <- data.frame(cbind(from, to), stringsAsFactors = FALSE)
origin_destination <- origin_destination[!((origin_destination$from == 'NA NA') |
                                        (origin_destination$to == 'NA NA')),]

route_df <- route(origin_destination[1, 'from'], 
                  origin_destination[1, 'to'], 
                  mode = 'bicycling', structure = 'leg')
route_df <- cbind(origin_destination[1,], route_df)
route_df$pathID <- 1
count <- 0
for (i in 2:length(origin_destination$from)){
        origin <- origin_destination[i, 'from']
        destination <- origin_destination[i, 'to']
        df <- route(origin, destination, mode = 'bicycling', structure = 'leg', override_limit = TRUE)
        df_temp <- cbind(origin_destination[i, ], df)
        df_temp$pathID <- i
        route_df <- rbind(route_df, df_temp)
        Sys.sleep(runif(1, 1.0, 2.5))
}

# break route_df from & to fields into source and destination 
src <- unname(sapply(route_df$from, strsplit, ' '))
dest <- unname(sapply(route_df$to, strsplit, ' '))
route_df$strt_lat <- as.numeric(sapply(src, function(x) x[1]))
route_df$strt_lon <- as.numeric(sapply(src, function(x) x[2]))
route_df$end_lat <- as.numeric(sapply(dest, function(x) x[1]))
route_df$end_lon <- as.numeric(sapply(dest, function(x) x[2]))

# calculate the last leg to the final destination
last_endlat <- route_df %>% 
        group_by(pathID, strt_lat, strt_lon, end_lat, end_lon) %>% 
        summarise(endLat = last(endLat))
last_endlon <- route_df %>% 
        group_by(pathID, strt_lat, strt_lon, end_lat, end_lon) %>% 
        summarise(endLon = last(endLon))
last_leg <- route_df %>% 
        group_by(pathID, strt_lat, strt_lon, end_lat, end_lon) %>% 
        summarise(leg = last(leg))
last_endlat$m <- 0
last_endlat$seconds <- 0
last_endlat$startLon <- last_endlon$endLon
last_endlat$startLat <- last_endlat$endLat
last_endlat$endLon <- last_endlon$endLon
last_endlat$endLat <- last_endlat$endLat
last_endlat$leg <- last_leg$leg + 1
last_endlat <- last_endlat %>% 
        select(pathID, strt_lat, strt_lon, end_lat, end_lon, m, seconds,
               startLon, startLat, endLon, endLat, leg)
route_df <- rbind(route_df, last_endlat) %>% arrange(pathID, leg)

# write the output to csv file
write.csv(route_df, 'data/routes_info.csv', row.names = FALSE)

# below writes and reads were used as helper to cache data multiple times during
# the fetching of route from google maps API.

# save unique_trips rds
saveRDS(unique_trips, 'unique_trips_route.rds')

# save origin_destination rds
saveRDS(origin_destination, 'origin_destination_route.rds')

# save a csv file for od
write.csv(origin_destination, 'data/origin_destination_route.csv')

# save a csv for the routes till 1911 path
write.csv(route_df, 'data/route_df.csv', row.names = FALSE)

# save a rds for routes till 1911 path
saveRDS(route_df, 'route_df.rds')

# load origin_destination
origin_destination <- readRDS('origin_destination_route.rds')

# load unique_trips 
unique_trips <- readRDS('unique_trips_route.rds')

# load route_df 
route_df <- readRDS('route_df.rds')