library(shiny)
library(miniUI)
library(shinyjs)

newCode <- 'function(ImgfileName) paste0("\\begin{figure}
\\begin{center}
\\fbox{\\includegraphics[width = 0.75 \\linewidth]{", ImgfileName, "}}
\\caption{Caption}
\\end{center}
\\end{figure}")'

nwcd <- data.frame(
  simple = 'function(ImgfileName) paste0("![Plot title. ](", ImgfileName,")")',
  includegraphics = newCode,
  stringsAsFactors = FALSE
)

config <- function() {

  ui <- miniPage(
    useShinyjs(),

    gadgetTitleBar("Choose code to insert for graphic:"),

    miniContentPanel(

      radioButtons("code", "Code choices - customize in text field:",
                   c("simple" = "simple",
                     "includegraphics" = "includegraphics")),

      textInput("fileName", "file name", "clipboardImage_1.png"),
      checkboxInput("showField", "Code bearbeiten:", FALSE),
      uiOutput("editCode"),
      verbatimTextOutput("code"),
      h6("Click 'done' to close and then select Addin (or corresponding Keyboard shortcut) to insert image from clipboard to .Rmd.")
    )
  )

  server <- function(input, output, session) {

    global <- reactiveValues(newCode = nwcd)

    observeEvent(input$insertCode, {
      global$newCode[[input$code]] <- input$insertCode
    })

    observeEvent(input$showField, {
      if(!input$showField){
        shinyjs::hide(id = "editCode")
      }else{
        shinyjs::show(id = "editCode")
      }
    })

    finalCode <- reactive({
      userCode <- gsub("\\", "\\\\", global$newCode[[input$code]], fixed = TRUE)
      eval(parse(text = paste0("func = ", userCode)))
    })

    output$code <- renderText({
      userCode <- gsub("\\", "\\\\", global$newCode[[input$code]], fixed = TRUE)
      eval(parse(text = paste0("func = ", userCode, ";func('", input$fileName,"')")))
    })

    output$editCode <- renderUI({
      #refactor;3;3;new variable names
      textAreaInput("insertCode", "This Code will be inserted:", global$newCode[[input$code]],
                    width = "500px", rows = 10)
    })

    observeEvent(input$done, {
      imagecliprEnv$newCode <- finalCode()
      stopApp()
    })

  }

  viewer <- paneViewer(300)

  runGadget(ui, server, viewer = viewer)
}
