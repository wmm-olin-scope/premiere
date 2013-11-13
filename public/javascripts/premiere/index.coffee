
contentDiv = $ "#content"

movieStart = Date.now() + 2*60*1000
movieDone = movieStart + 30*1000
countdownLength = 2*60*1000

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

startPartnerVideo = (category) ->
    req = switchContent "/premiere/partner", () ->
        new YT.Player 'partner-video-iframe',
            height: '550'
            width: '960'
            videoId: 'kaoGnuhz4Kg'
            allowfullscreen: true
            frameborder: "no"
            autoplay: true
            events:
                onReady: (event) ->
                    event.target.playVideo()
                onStateChange: (event) ->
                    startPreshow category if event.data is YT.PlayerState.ENDED
    transition req, "Loading a message from Randi"
                    
startPreshow = (category="General") ->
    console.log "Preshow starting"
    req = switchContent "/premiere/preshow/#{category}", () ->
        console.log "Preshow loaded"
        startCountdownBar()
        startMovieCheck()
    transition req

setupCategory = () ->
    onClickCategory = (category) ->
        category = "Student" # TODO: Quick fix
        movieStart = Date.now() + 1.5*60*1000
        userCategory = category
        startPartnerVideo category

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
    countdownLength = delta + 1000

    if delta > countdownLength
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

    id = setInterval((() ->
        delta = movieStart - Date.now()
        if delta <= 0
            clearInterval id
        else
            console.log delta
            min = Math.floor delta/(60*1000)
            console.log min
            sec = Math.floor (delta - min*60*1000)/1000
            pad = (x) -> if x >= 10 then "#{x}" else "0#{x}"
            $("#countdown-text").text "#{pad min}:#{pad sec} to Premiere"
    ), 500)

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
        #startMovieCheck()
