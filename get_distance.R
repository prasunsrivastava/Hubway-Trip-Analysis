# script to pull distance from google maps for all unique trips

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

od <- data.frame(cbind(from, to), stringsAsFactors = FALSE)

od <- od[!((od$from == 'NA NA') | (od$to == 'NA NA')),]

od$row_number <- 1:nrow(od)

for (i in 1:length(od$row_number)){
        orig <- od[i,c('from')]
        dest <- od[i,c('to')]
        a <- mapdist(from = orig, 
                     to = dest, 
                     mode = "bicycling",
                     output = "simple",
                     override_limit = TRUE)
        a$row_number <- i
        od$minutes[match(a$row_number, od$row_number)] <- a$minutes
        od$hours[match(a$row_number, od$row_number)] <- a$hours
        od$km[match(a$row_number, od$row_number)] <- a$km
        od$m[match(a$row_number, od$row_number)] <- a$m
}

write.csv(od, 'data\\origin_destination.csv', row.names = FALSE)