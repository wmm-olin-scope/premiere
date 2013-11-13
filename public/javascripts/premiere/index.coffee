
contentDiv = $ "#content"

movieStart = Date.now() + 14*1000
movieDone = movieStart + 10*1000
countdownLength = 15*60*1000

userCategory = "General"

switchContent = (contentUrl, done=null) ->
    $.ajax(contentUrl)
        .fail((err) -> console.log err)
        .done (content) -> 
            contentDiv.html content
            done() if done


transition = (request, title=null, duration=750) ->
    $("body").append """
        <div id="progress-window">
            <div id="progress-bar"></div>
        </div>
    """
    progressWindow = $ "#progress-window"
    progressBar = $ "#progress-bar", progressWindow

    progressWindow.dialog
        dialogClass: "dialog-no-close"
        width: 600
        height: 102
        modal: true
        resizable: false
        draggable: false
        closeOnEscape: false

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

startPreshow = (category="General") ->
    req = switchContent "/premiere/preshow/#{category}", () ->
        startCountdownBar()
    transition req

setupCategory = () ->
    onClickCategory = (category) ->
        userCategory = category
        startPreshow category

    category = null #getCookie "userCategory"
    if category isnt null
        onClickCategory category
    else
        switchContent "/premiere/category", () ->
            for category in ["General", "Student", "Parent", "Educator"]
                do (category) ->
                    $("button##{category}").on "click", () ->
                        onClickCategory category

startCountdownBar = () ->
    bar = $ "#countdown-bar"
    delta = movieStart - Date.now()

    console.log delta, bar

    if delta > countdownLength
        console.log "SHIT!"

        div = $ "countdown"
        div.hide()
        setTimeout((() -> 
            div.show()
            startCountdownBar()
        ), delta - countdownLength)
        return

    width = 100*Math.max(0.01, 1 - delta/countdownLength)
    console.log width
    bar.css {width: "#{width}%"}
    bar.animate {width: "100%"},
        duration: delta
        easing: "linear"

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
