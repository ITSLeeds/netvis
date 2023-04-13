
#' Visualise route networks
#'
#' @param rnet 
#' @param lwd_min 
#' @param lwd_max 
#' @param attrib 
#'
#' @return
#' @export
#'
#' @examples
#' rnetvis(rnet_example)
rnetvis = function(rnet, lwd_min = 1, lwd_max = 10, attrib = c("v1", "v2", "v3")) {
  library(tmap)
  # rnet_df = sf::st_drop_geometry(rnet)
  max_values = sapply(attrib, FUN = function(x) max(rnet[[x]]))
  i = 1
  # Create layer for column 1:
  for(i in seq_along(attrib)) {
    if(i == 1) {
      m = tm_shape(rnet) + tm_lines(lwd = attrib[i], title.lwd = attrib[i]) +
    } else {
      m = m + tm_shape(rnet) + tm_lines(lwd = attrib[i]) + tm_layout(title = attrib[i])
    }
  }
  lm = tmap::tmap_leaflet(m)
  lm
}
