# imageclipr
RStudio Addin: Copy images from clipboard into RMarkdown .Rmd files.

# Dependencies
Python (incl. PIL library)

R Pakete `library(rstudioapi)`, `library(reticulate)` (`library(rmarkdown)` for markdown files)

# Installation
`devtools::install_github('Timag/imageclipr')`

# Open issues
- remove python dependency
- can not: 
-- copy and paste image and text together
-- copy and paste an image by copying the file in the explorer

# Adding a keyboard shortcut
In RStudio go to Tools - Modify Keyboard Shortcuts...

![Plot title. ](clipboardImage_1.png)

![Plot title. ](clipboardImage_2.png)
