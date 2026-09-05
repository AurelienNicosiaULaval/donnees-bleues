source('R/utils_data_checks.R')
# A midnight end belongs to the preceding civil day. Summer remains UTC-5.
ends <- parse_air_hour_end(c('2025-01-01 00:00:00', '2025-06-01 00:00:00', '2025-06-01 01:00:00'))
stopifnot(identical(as.character(air_calendar_day(ends)), c('2024-12-31', '2025-05-31', '2025-06-01')))
stopifnot(identical(format(ends, '%Y-%m-%d %H:%M', tz = 'UTC'),
  c('2025-01-01 05:00', '2025-06-01 05:00', '2025-06-01 06:00')))
cat('Heures RSQAQ : minuit affecté au jour précédent; HNE conservée en été.\n')
