
saveClipboardImage <- function(fileName, dir = getwd()){
  library(reticulate)
  library(rstudioapi)

  filePath <- paste0(dir, "/" , fileName)
  # Refactoring;2;2;Check how other functions deal with the file saving
  if(file.exists(filePath)) stop(paste0("File already exists at: ", filePath, ". Did not save the file."))
  pyCode <- paste0("from PIL import ImageGrab; im = ImageGrab.grabclipboard(); im.save('", filePath, "','PNG')")
  tryCatch(py_run_string(pyCode), error = function(e){
    if("AttributeError: 'NoneType' object has no attribute 'save'" == e) stop("Clipboard data is not an image.")
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


#todo;2;3;create an image folder and edit the path accordingly
insertImageCode <- function(){
  library(reticulate)
  library(rstudioapi)

  # oldFileContent <- getActiveDocumentContext()$contents
  filePath <- getActiveDocumentContext()$path
  docId <- getActiveDocumentContext()$id
  splitted <- strsplit(filePath, "[/]")[[1]]
  dirPath <- paste(splitted[1:(length(splitted) - 1)], collapse = "/")
  ImgfileName = findImgFileName(dirPath, fileType = ".png")

  # refactor;3;3;get file ending
  # newFileName <- gsub("[.]Rmd", "2.Rmd", filePath)
  # activeLine <- getActiveDocumentContext()$selection[[1]]$range$start[[1]]
  saveClipboardImage(ImgfileName, dir = dirPath)
  position <- getActiveDocumentContext()$selection[[1]]$range$start
  newCode <- paste0("![Plot title. ](", ImgfileName, ")")
  insertText(position, newCode, id = docId)
  # newFileContent <- paste(c(oldFileContent[1:(activeLine - 1)], newCode, oldFileContent[activeLine:length(oldFileContent)]), collapse = "\n")
  # write.table(file = newFileName, newFileContent, row.names = FALSE, col.names = FALSE, quote = FALSE)
  # file.edit(newFileName)
}

