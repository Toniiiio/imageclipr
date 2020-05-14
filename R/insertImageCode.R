imagecliprEnv <- new.env(parent = emptyenv())
imagecliprEnv$newCode <- function(ImgfileName) paste0("![Plot title. ](", ImgfileName, ")")

grabclipboard <- function(filepath){
  platform <- Sys.info()[1]
  if (platform == "Darwin") {
    script <- paste0(
      "osascript -e \'
      set theFile to (open for access POSIX file \"", filepath, "\" with write permission)
      try
      write (the clipboard as «class PNGf») to theFile
      end try
      close access theFile'"
      )
    system(script)

  } else if (platform == 'Windows') {
    script <- paste0(
      "powershell -sta \"\n",
      "  Add-Type -AssemblyName System.Windows.Forms;\n",
      "  if ($([System.Windows.Forms.Clipboard]::ContainsImage())) {\n",
      "    [System.Drawing.Bitmap][System.Windows.Forms.Clipboard]::GetDataObject().getimage().Save('",
      paste0(filepath, "', [System.Drawing.Imaging.ImageFormat]::Png) \n"),
      "  }\""
    )
    system(script)
  }else if (platform == 'Linux') {
    tryCatch(targets <- tolower(system("xclip -selection clipboard -t TARGETS -o",intern=T)), error = function(e){
      stop("Please install the required system dependency xclip")
    }) # Validate xclip is installed and get targets from clipboard
    if (any(grepl(".*png$",targets))){
      system(paste0("xclip -selection clipboard -t image/png -o > ", filepath))
    }
  }

  # writeLines(script)

  # in mac os, if no image in clipboard, exec script will create a empty image
  # in window, no image be create
  if(file.exists(filepath) &&  file.size(filepath) > 0) {
    return(filepath)
  }
  NULL
}

saveClipboardImage <- function(fileName, dir = getwd()){
  filePath <- file.path(dir, fileName)
  # Refactoring;2;2;Check how other functions deal with the file saving
  if(file.exists(filePath)) stop(paste0("File already exists at: ", filePath, ". Did not save the file."))

  filePath <- grabclipboard(filePath)
  if (is.null(filePath)) {
    stop("Clipboard data is not an image.")
  }
}


findImgFileName <- function(filePath, fileType = ".png"){
  # this is to check whether there are identical names

  dirPath <- dirname(filePath)
  identifierName <- paste0( gsub(paste0("\\.", tools::file_ext(filePath)), "", basename(filePath)), "_insertimage_" )

  fileNames <- list.files(dirPath)

  idx <- grep(identifierName, fileNames)
  candidates <- strsplit(fileNames[idx], identifierName)
  if(!length(candidates)){
    imgNr <- 1
  }else{
    nrs <- sapply(candidates, function(cand){
      # refactor;2;4;what if other types of names -kopie...
      as.numeric(strsplit(cand[2], "[.]")[[1]][1])
    })
    imgNr <- max(nrs) + 1
  }
  return(paste0(identifierName, imgNr, fileType))
}



#assumption;2;4; if multiple images are selected and copied they will be added to one
#open issue;2;3;configure parameter for addins
#todo;2;3;create an image folder and edit the path accordingly
insertImageCode <- function(){
  func = imagecliprEnv$newCode
  #print(func)
  library(reticulate)
  library(rstudioapi)

  # if(Sys.info()['sysname'] == "Linux") stop("The addin only supports MacOS and Windows.")

  # oldFileContent <- getActiveDocumentContext()$contents
  docId <- getActiveDocumentContext()$id
  if(docId %in% c("#console", "#terminal")) stop("You can`t insert an image in the console nor in the terminal.
                                                 Please select a line in the source editor.")
  filePath <- getActiveDocumentContext()$path
  if(!nchar(filePath)) stop("Please save the file before pasting an image.")

  # if the first is tilde, then the python code breaks. Let's replace this using Sys.getenv
  filePath <- gsub( "^~", Sys.getenv("HOME"), filePath)

  ImgfileName = findImgFileName(filePath, fileType = ".png")

  # refactor;3;3;get file ending
  saveClipboardImage(ImgfileName, dir = dirname(filePath))
  position <- getActiveDocumentContext()$selection[[1]]$range$start
  insertText(position, func(ImgfileName), id = docId)
}
