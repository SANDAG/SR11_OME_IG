#' Choose a Folder Interactively 
#'
#' @param default which folder to show initially
#' @param caption the caption on the selection dialog
#'
#' @details
#' display a folder selection dialog.
#'
#' @return
#' A length one character vector, character NA if 'Cancel' was selected.
#'

#' Directory Selection Control
#'
#' Create a directory selection control to select a directory on the server
#'
#' @param inputId The \code{input} slot that will be used to access the value
#' @param label Display label for the control, or NULL for no label
#' @param value Initial value.  Paths are exapnded via \code{\link{path.expand}}.
#'
#' @details
#' This widget relies on \link{\code{choose.dir}} to present an interactive
#' dialog to users for selecting a directory on the local filesystem.  Therefore,
#' this widget is intended for shiny apps that are run locally - i.e. on the
#' same system that files/directories are to be accessed - and not from hosted
#' applications (e.g. from shinyapps.io).
#'
#' @return
#' A directory input control that can be added to a UI definition.
#'
#' @seealso
#' \link{updateDirectoryInput}, \link{readDirectoryInput}, \link[utils]{choose.dir}

directoryInput = function(inputId, label, value = NULL) {
  if (!is.null(value) && !is.na(value)) {
    value = path.expand(value)
  }
  
  tagList(
    singleton(
      tags$head(
        tags$script(src = 'js/directory_input_binding.js')
      )
    ),
  
    div(
      class = 'form-group directory-input-container',
      style = 'padding-left: 12px; margin-bottom: 0',
      tags$label(label)
    ),
      
    div(
      span(
        class = 'col-xs-9 col-md-11',
        style = 'padding-left: 0; padding-right: 0;',
        div(
          class = 'input-group shiny-input-container',
          style = 'width:100%; padding-top: 0;',
          div(class = 'input-group-addon', icon('folder-o')),
          tags$input(
            id = sprintf('%s__chosen_dir', inputId),
            value = value,
            type = 'text',
            class = 'form-control directory-input-chosen-dir',
            readonly = 'readonly'
          )
        )
      ),
      
      span(
        class = 'shiny-input-container',
        tags$button(
          id = inputId,
          class = 'btn btn-default directory-input',
          'browse'
        )
      )
    )
  )

}

#' Change the value of a directoryInput on the client
#'
#' @param session The \code{session} object passed to function given to \code{shinyServer}.
#' @param inputId The id of the input object.
#' @param value A directory path to set
#' @param ... Additional arguments passed to \link{\code{choose.dir}}.  Only used
#'    if \code{value} is \code{NULL}.
#'
#' @details
#' Sends a message to the client, telling it to change the value of the input
#' object.  For \code{directoryInput} objects, this changes the value displayed
#' in the text-field and triggers a client-side change event.  A directory
#' selection dialog is not displayed.
#'
updateDirectoryInput = function(session, inputId, value = NULL, ...) {
  if (is.null(value)) {
    value = choose.dir(...)
  }
  session$sendInputMessage(inputId, list(chosen_dir = value))
}

#' Read the value of a directoryInput
#'
#' @param session The \code{session} object passed to function given to \code{shinyServer}.
#' @param inputId The id of the input object
#'
#' @details
#' Reads the value of the text field associated with a \code{directoryInput}
#' object that stores the user selected directory path.
#'
readDirectoryInput = function(session, inputId) {
  session$input[[sprintf('%s__chosen_dir', inputId)]]
}

resetDirectoryInput = function(session, inputId, value) {
  session$sendInputMessage(inputId, list(chosen_dir = value))
}