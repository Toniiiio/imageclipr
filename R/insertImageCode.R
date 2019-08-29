imagecliprEnv <- new.env(parent = emptyenv())
imagecliprEnv$newCode <- function(ImgfileName) paste0("![Plot title. ](", ImgfileName, ")")

saveClipboardImage <- function(fileName, dir = getwd()){
  library(reticulate)
  library(rstudioapi)

  filePath <- paste0(dir, "/" , fileName)
  # Refactoring;2;2;Check how other functions deal with the file saving
  if(file.exists(filePath)) stop(paste0("File already exists at: ", filePath, ". Did not save the file."))

  tryCatch(import("os"), error = function(e){
    stop("Can not use python, please configure the reticulate/python setup.")
  })
  tryCatch(import("PIL"), error = function(e){
    stop("Required python package PIL is not installed on the python linked at reticulate. Check py_config() for linked python version. Restart R after installing PIL.")
  })

  pyCode <- paste0("from PIL import ImageGrab; im = ImageGrab.grabclipboard(); im.save('", filePath, "','PNG')")
  tryCatch(py_run_string(pyCode), error = function(e){
    
    if("AttributeError: 'NoneType' object has no attribute 'save'" == e){
      stop("Clipboard data is not an image.")
     }else{
      stop(
        paste0("Error copying the file with python. Error message reads: ", e)
      )
     }
  })
}


findImgFileName <- function(dirPath, fileType = ".png"){
  fileNames <- list.files(dirPath)
  identifierName <- "clipboardImage_"

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
  print(func)
  library(reticulate)
  library(rstudioapi)

  # if(Sys.info()['sysname'] == "Linux") stop("The addin only supports MacOS and Windows.")

  # oldFileContent <- getActiveDocumentContext()$contents
  docId <- getActiveDocumentContext()$id
  if(docId %in% c("#console", "#terminal")) stop("You can`t insert an image in the console nor in the terminal.
                                                 Please select a line in the source editor.")
  filePath <- getActiveDocumentContext()$path
  if(!nchar(filePath)) stop("Please save the file before pasting an image.")
  splitted <- strsplit(filePath, "[/]")[[1]]
  dirPath <- paste(splitted[1:(length(splitted) - 1)], collapse = "/")
  ImgfileName = findImgFileName(dirPath, fileType = ".png")

  # refactor;3;3;get file ending
  saveClipboardImage(ImgfileName, dir = dirPath)
  position <- getActiveDocumentContext()$selection[[1]]$range$start
  insertText(position, func(ImgfileName), id = docId)
}
