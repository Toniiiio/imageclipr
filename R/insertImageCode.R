imageclipr_env <- new.env(parent = emptyenv())
imageclipr_env$newCode <- function(img_file_name) paste0("![Plot title. ](", img_file_name, ")")

#' Saving the clipboard image to disk
#'
#'The image from the clipboard has to be saved to disk. Mac, Linux and Windows are supported. For Windows Powershell is used. For Linux xclip is required.
#'
#' @param file_name The image from the clipboard has to be saved to disk. file_name is the name of the image when saving it to disk.
#' @param dir The image from the clipboard has to be saved to disk. dir is the directory to save the image in. By default it is the current working directory.
#'
save_clipboard_image <- function(file_name, dir = getwd()) {

  file_path <- file.path(dir, file_name)
  if (file.exists(file_path)){
    stop(paste0("File already exists at: ", file_path, ". Did not save the file."))
  }

  platform <- Sys.info()[1]

  if (platform == "Darwin") { # MAC OS

    script <- paste0(
      "osascript -e \'
      set theFile to (open for access POSIX file \"", file_path, "\" with write permission)
      try
      write (the clipboard as «class PNGf») to theFile
      end try
      close access theFile'"
    )
    system(script)

  } else if (platform == "Windows") {

    script <- paste0(
      "powershell -sta \"\n",
      "  Add-Type -AssemblyName System.Windows.Forms;\n",
      "  if ($([System.Windows.Forms.Clipboard]::ContainsImage())) {\n",
      "    [System.Drawing.Bitmap][System.Windows.Forms.Clipboard]::GetDataObject().getimage().Save('",
      paste0(file_path, "', [System.Drawing.Imaging.ImageFormat]::Png) \n"),
      "  }\""
    )
    system(script)

  } else if (platform == "Linux") {

    # Validate xclip is installed and get targets from clipboard
    tryCatch(targets <- tolower(system("xclip -selection clipboard -t TARGETS -o", intern = T)), error = function(e) {
      stop(
        "Getting image from clipboard with xclip failed. The used command is: 'xclip -selection clipboard -t TARGETS -o'.
         Please ensure that the required system dependency xclip is installed and can be used. Otherwise file an issue at Github."
      )
    })

    if (any(grepl(".*png$", targets))) {
      system(paste0("xclip -selection clipboard -t image/png -o > ", file_path))
    }

  }

  # check if a valid picture was saved.
  # In mac os, if no image is in the clipboard, exec script will create a empty image
  # In windows, no image will be created
  if (file.exists(file_path) && file.size(file_path) > 0) {
    stop("Clipboard data is not an image.")
  }


}


#' Create a valid, unique file name.
#'
#' In case the current file name, for the image, is already taken an index will be added to the file name.
#'
#' @param file_path Directory path including name of the file
#' @param file_type Extension of the image, e.g. .png
#'
#' @return An unique name for the image for the given path
create_valid_file_name <- function(file_path, file_type = ".png") {

  dir_path <- dirname(file_path)
  file_name_id <- paste0(gsub(paste0("\\.", tools::file_ext(file_path)), "", basename(file_path)), "_insertimage_")

  file_names <- list.files(dir_path)

  idx <- grep(file_name_id, file_names)
  candidates <- strsplit(file_names[idx], file_name_id)

  if (!length(candidates)) {
    img_nr <- 1
  } else {
    nrs <- sapply(candidates, function(cand) {
      # refactor;2;4;what if other types of names -kopie...
      as.numeric(strsplit(cand[2], "[.]")[[1]][1])
    })
    img_nr <- max(nrs) + 1
  }
  return(paste0(file_name_id, img_nr, file_type))
}


# open issue;2;3;configure parameter for addins
# todo;2;3;create an image folder and edit the path accordingly

#' Insert the markdown code for the image in the .Rmd file.
#'
#' Given the image in the clipboard, the corresponding markdown code will be inserted in the .Rmd file. The code
#' will be generated given the code template from the configuration and the generated file path. It will be inserted with
#' the rstudioapi package.
#' Unsaved documents as Untitled1.Rmd can not properly be accessed by rstudioapi. The document has to be saved to disk.
#' If multiple images are copied only one will be copied.
#' The image can only be inserted in the source editor not in the console nor the terminal.
#'
insert_image_code <- function() {

  doc_id <- rstudioapi::getActiveDocumentContext()$id
  if (doc_id %in% c("#console", "#terminal")){
    stop("You can`t insert an image in the console nor in the terminal. Please select a line in the source editor.")
  }

  file_path <- rstudioapi::getActiveDocumentContext()$path
  if (!nchar(file_path)){
    stop("Please save the file before pasting an image.")
  }

  # if the first is tilde, then the python code breaks. Let's replace this using Sys.getenv
  file_path <- gsub("^~", Sys.getenv("HOME"), file_path)
  img_file_name <- create_valid_file_name(file_path, file_type = ".png")

  # refactor;3;3;get file ending
  save_clipboard_image(img_file_name, dir = dirname(file_path))
  position <- rstudioapi::getActiveDocumentContext()$selection[[1]]$range$start
  code_to_insert <- imageclipr_env$newCode
  rstudioapi::insertText(position, code_to_insert(img_file_name), id = doc_id)
}
