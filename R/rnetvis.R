
#' Visualise route networks
#'
#' @param rnet 
#' @param min_width 
#' @param max_width 
#' @param attrib 
#'
#' @return
#' A tmap or leaflet object
#' @export
#'
#' @examples
#' rnet = rnet_central
#' netvis(rnet)
#' netvis(rnet, min_width = 3)
#' # Small variations in line width
#' netvis(rnet, min_width = 3, max_width = 10)
netvis = function(
    rnet,
    min_width = 1,
    max_width = 10,
    width_regex = "bi|du",
    output = "list",
    width_multiplier = NULL,
    ptile = 0.95
) {
  maps = scale_line_widths(
    rnet,
    min_width = min_width,
    max_width = max_width,
    width_regex = "bi|du",
    width_multiplier = width_multiplier,
    ptile = ptile
  )
  # browser()
  i = 1
  nms = names(maps)
  # Create layer for column 1:
  for(i in seq(length(maps))) {
    if(i == 1) {
      m <<- maps[[1]]
    } else {
      m = m + maps[[i]]
    }
  }
  lm = tmap::tmap_leaflet(m) |>
    leaflet::hideGroup(nms[-1])
  lm
}
scale_line_widths = function(
    x,
    min_width = 1,
    max_width = 10,
    width_regex = "bi|du",
    width_multiplier = NULL,
    ptile = 0.95
    ) {
  names_width = names(x)[grepl(width_regex, names(x))]
  names_width_lwd = paste0(names_width, "_lwd")
  names(names_width_lwd) = names_width
  if(is.null(width_multiplier)) {
    width_multiplier = max_width / min_width
  }
  x_no_outliers = x |>
    sf::st_drop_geometry() |>
    dplyr::select(matches(width_regex)) |>
    dplyr::mutate_all(function(x) {
      x[x > quantile(x, ptile)] = quantile(x, ptile)
      x
    })
  # waldo::compare(x, x_no_outliers) # large values gone
  max_value = max(x_no_outliers)
  x_normalized = x_no_outliers |>
    dplyr::mutate_all(function(x) x / max_value)
  # summary(x_normalized)
  minimum_value_allowed = 1 / width_multiplier
  x_scaled = x_normalized |>
    dplyr::mutate_all(function(x) dplyr::case_when(
      x < minimum_value_allowed ~ minimum_value_allowed,
      TRUE ~ x
    ))
  summary(x_scaled)
  maximums = x_scaled |> sapply(max)
  max_widths = maximums * max_width
  names(x_scaled) = names_width_lwd
  x_to_plot = cbind(x, x_scaled)
  nm = names_width[1]
  map_list = lapply(names_width, function(nm) {
   tmap::tm_shape(x_to_plot) +
     tmap::tm_lines(
        lwd = names_width_lwd[nm],
        scale = max_widths[[nm]],
        group = nm
      )
  })
  names(map_list) = names_width
  # map_list[[1]]
  map_list
}
