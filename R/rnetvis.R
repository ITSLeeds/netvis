
#' Visualise route networks
#'
#' @param x 
#' @param min_width Minimum width of lines
#' @param max_width Maximum width of lines
#' @param names_width Names of columns to use for line widths
#' @param popup_vars Variables to appear in popups
#'
#' @return
#' A tmap or leaflet object
#' @export
#'
#' @examples
#' rnet = rnet_minimal
#' netvis(rnet, basemaps = leaflet::providers$OpenStreetMap)
#' # Variations in width only in bottom 30% of widest lines set to max width:
#' netvis(rnet, ptile = 0.3, basemaps = leaflet::providers$OpenStreetMap)
#' 
#' # Small variations in line width:
#' netvis(rnet, min_width = 3, max_width = 5)
#' # Max width reached early:
#' netvis(rnet, min_width = 3, max_width = 10, ptile = 0.1)
#' rnet = rnet_limerick
#' netvis(rnet, width_regex = "Bicycle")
#' m = netvis(rnet, width_regex = "Bicycle", output = "tmap")
#' class(m)
#' tmap::tmap_mode("view")
#' m
#' popup_vars = c(
#'   "Cycle friendliness" = "Quietness",
#'   "Gradient" = "Gradient"
#' )
#' netvis(rnet, width_regex = "Bicycle", popup_vars = popup_vars)
#' netvis(rnet, width_regex = "Bicycle", popup_vars = popup_vars,
#'    width_var_name = "Bicycle trips")
#' pal = c('#882255','#CC6677', '#44AA99', '#117733')
#' quietness_breaks = c(0, 35, 70, 85, 100)
#' basemaps = c(
#'   `Grey basemap` = "CartoDB.Positron",
#'   `Coloured basemap` = "Esri.WorldTopoMap",
#'   `Cycleways (OSM)` = "https://b.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png",
#'   `Satellite image` = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'"
#' )
#' netvis(rnet, width_regex = "Bicycle", popup_vars = popup_vars,
#'    width_var_name = "Bicycle trips", col = "Quietness", pal = pal,
#'    breaks = quietness_breaks, basemaps = basemaps)
netvis = function(
    x,
    min_width = 1.8,
    max_width = 8,
    names_width = NULL,
    width_regex = "bi|du",
    width_var_name = NULL,
    output = "leaflet",
    width_multiplier = NULL,
    ptile = 0.95,
    popup_vars = NULL,
    basemaps = NULL,
    ...
) {
  if(is.null(names_width)) {
    names_width = names(x)[grepl(width_regex, names(x))]
  }
  names_width_lwd = paste0(names_width, "_lwd")
  names(names_width_lwd) = names_width
  if(is.null(width_multiplier)) {
    width_multiplier = max_width / min_width
  }
  x_no_outliers = sf::st_drop_geometry(x)[names_width]
  x_no_outliers = as.matrix(x_no_outliers)
  max_value = quantile(x = x_no_outliers, probs = ptile)
  x_no_outliers[x_no_outliers > max_value] = max_value
  x_no_outliers = tibble::as_tibble(x_no_outliers)
  # waldo::compare(x, x_no_outliers) # large values gone
  x_normalized = x_no_outliers |>
    dplyr::mutate_all(function(x) x / max_value)
  # summary(x_normalized)
  minimum_value_allowed = 1 / width_multiplier
  x_scaled = x_normalized |>
    dplyr::mutate_all(function(x) dplyr::case_when(
      x < minimum_value_allowed ~ minimum_value_allowed,
      TRUE ~ x
    ))
  # summary(x_scaled)
  maximums = x_scaled |> sapply(max)
  max_widths = maximums * max_width
  message("Max widths: ", paste(round(max_widths, 2), collapse = ", "))
  names(max_widths) = names_width
  names(x_scaled) = names_width_lwd
  x_to_plot = dplyr::bind_cols(x, x_scaled)
  nm = names_width[1]
  # browser()
  # nm = names_width[1] # for debugging
  map_list = lapply(names_width, function(nm) {
    pvs = c(nm, popup_vars)
    if(!is.null(width_var_name)) {
      names(pvs)[1] = width_var_name
    }
    tmap::tm_shape(x_to_plot) +
      tmap::tm_lines(
        popup.vars = pvs,
        lwd = names_width_lwd[nm],
        scale = max_widths[[nm]],
        group = nm,
        id = "",
        ...
      )
  })
  names(map_list) = names_width
  # map_list[[1]]
  i = 1
  nms = names(map_list)
  # Create layer for column 1:
  for(i in seq(length(map_list))) {
    if(i == 1) {
      m <<- map_list[[1]]
    } else {
      m = m + map_list[[i]]
    }
  }
  if(!is.null(basemaps)) {
    m = m + tmap::tm_basemap(server = basemaps)
  }
  if(output == "tmap") {
    return(m)
  }
  lm = tmap::tmap_leaflet(m) |>
    leaflet::hideGroup(nms[-1])
  lm
}
