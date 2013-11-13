
contentDiv = $ "#content"

movieStart = Date.now() + 25*1000
movieDone = movieStart + 10*1000

userCategory = "General"

switchContent = (contentUrl, done=null) ->
    $.ajax(contentUrl)
        .fail((err) -> console.log err)
        .done (content) -> 
            contentDiv.html content
            done() if done


transition = (request, title=null, duration=750) ->
    progressWindow = $ "#progress-window"
    $("body").append """
        <div id="progress-window">
            <div id="progress-bar"></div>
        </div>
    """
    
    progressBar = $ "#progress-bar", progressWindow

    progressWindow.dialog
        dialogClass: "no-close"
        width: 600
        height: 105
        modal: true
        resizable: false
        draggable: false

    if title
        progressWindow.dialog "option", "title", title
    else
        $(".ui-dialog-titlebar", progressWindow.parent()).css "display", "none"

    progressWindow.dialog "open"

    progressBar.progressbar
        value: false

    request.always () ->
        progressBar.progressbar {value: 1}
        $(".ui-progressbar-value", progressBar).animate {width: "100%"},
            duration: duration 
            complete: () -> 
                progressWindow.dialog "close"
                progressWindow.parent().remove()

getCookie = (name) ->
    re = new RegExp "(?:^#{name}|;\s*#{name})=(.*?)(?:;|$)", "g"
    result = re.exec document.cookie
    if result then result[1] else null

setupCategory = () ->
    onClickCategory = (category) ->
        userCategory = category
        transition switchContent "/premiere/preshow/#{category}"

    category = null #getCookie "userCategory"
    if category isnt null
        onClickCategory category
    else
        req = switchContent "/premiere/category", () ->
            for category in ["General", "Student", "Parent", "Educator"]
                do (category) ->
                    $("button##{category}").on "click", () ->
                        onClickCategory category
        transition req

startCountdown = () ->
    transition switchContent "/premiere/countdown"
    setTimeout startMovie, movieStart - Date.now()

startMovieCheck = () ->
    setTimeout startMovie, movieStart - Date.now()

startMovie = () ->
    transition switchContent("/premiere/movie"), "Starting Movie", 3000
    setTimeout startPostshow, movieDone - Date.now()

startPostshow = () ->
    transition switchContent "/premiere/postshow/#{userCategory}"

$ () ->
    if Date.now() > movieDone
        startPostshow()
    else if Date.now() > movieStart
        startMovie()
    else
        setupCategory()
        startMovieCheck()