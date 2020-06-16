rmd_img_code <- 'function(img_file_name) paste0("\\begin{figure}
\\begin{center}
\\fbox{\\include_graphics[width = 0.75 \\linewidth]{", img_file_name, "}}
\\caption{Caption}
\\end{center}
\\end{figure}")'

nwcd <- data.frame(
  simple = 'function(img_file_name) paste0("![Plot title. ](", img_file_name,")")',
  include_graphics = rmd_img_code,
  stringsAsFactors = FALSE # for R < 4.0.0
)

config <- function() {

  ui <- miniUI::miniPage(
    shinyjs::useShinyjs(),

    miniUI::gadgetTitleBar("Choose code to insert for graphic:"),

    miniUI::miniContentPanel(

      radioButtons("code", "Code choices - customize in text field:",
                   c("simple" = "simple",
                     "include_graphics" = "include_graphics")),

      textInput("file_name", "file name", "clipboardImage_1.png"),
      checkboxInput("show_field", "Code bearbeiten:", FALSE),
      uiOutput("edit_code"),
      verbatimTextOutput("code"),
      h6("Click 'done' to close and then select addin (or corresponding Keyboard shortcut) to insert image from clipboard to .Rmd.")
    )
  )

  server <- function(input, output, session) {

    global <- reactiveValues(rmd_img_code = nwcd)

    observeEvent(input$insert_code, {
      global$rmd_img_code[[input$code]] <- input$insert_code
    })

    observeEvent(input$show_field, {
      if(!input$show_field){
        shinyjs::hide(id = "edit_code")
      }else{
        shinyjs::show(id = "edit_code")
      }
    })

    rmd_img_code <- reactive({
      user_code <- gsub("\\", "\\\\", global$rmd_img_code[[input$code]], fixed = TRUE)
      eval(parse(text = paste0("func = ", user_code)))
    })

    output$code <- renderText({
      user_code <- gsub("\\", "\\\\", global$rmd_img_code[[input$code]], fixed = TRUE)
      eval(parse(text = paste0("func = ", user_code, ";func('", input$file_name,"')")))
    })

    output$edit_code <- renderUI({
      #refactor;3;3;new variable names
      textAreaInput("insert_code", "This code will be inserted:", global$rmd_img_code[[input$code]],
                    width = "500px", rows = 10)
    })

    observeEvent(input$done, {
      imageclipr_env$rmd_img_code <- rmd_img_code()
      stopApp()
    })

  }

  runGadget(ui, server, viewer = paneViewer(300))
}
