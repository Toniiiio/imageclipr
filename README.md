## imageclipr
RStudio Addin: Copy images from clipboard into RMarkdown .Rmd files.

![Usage of imageclipr](usage.gif)

## Dependencies
Python (incl. PIL library)

R Pakete `library(rstudioapi)`, `library(reticulate)` (`library(rmarkdown)` for markdown files)

## Installation
`devtools::install_github('Timag/imageclipr')`

## Open issues
- remove python dependency
- can not: 

-- copy and paste image and text together

-- copy and paste an image by copying the file in the explorer

## Usage

### Select the addin
![Addin selection](clipboardImage_5.png)

### Adding a keyboard shortcut (Recommended)
In RStudio go to Tools - Modify Keyboard Shortcuts...

![Find Shortcuts](clipboardImage_1.png)

![Modify Shortcuts](clipboardImage_2.png)


