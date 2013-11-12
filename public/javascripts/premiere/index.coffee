
contentDiv = $ "#content"

movieStart = Date.now() + 25*1000
countdownStart = movieStart - 10*1000
movieDone = movieStart + 10*1000

userCategory = "General"

switchContent = (contentUrl, done) ->
    contentDiv.html "" # loading or something?

    $.ajax(contentUrl)
        .fail((err) -> console.log err)
        .done (content) -> 
            contentDiv.html content
            done() if done

getCookie = (name) ->
    re = new RegExp "(?:^#{name}|;\s*#{name})=(.*?)(?:;|$)", "g"
    result = re.exec document.cookie
    if result then result[1] else null

setupCategory = () ->
    onClickCategory = (category) ->
        userCategory = category
        switchContent "/premiere/preshow/#{category}"

    category = null #getCookie "userCategory"
    if category isnt null
        onClickCategory category
    else
        switchContent "/premiere/category", () ->
            for category in ["General", "Student", "Parent", "Educator"]
                do (category) ->
                    $("button##{category}").on "click", () ->
                        onClickCategory category

startCountdown = () ->
    switchContent "/premiere/countdown"
    setTimeout startMovie, movieStart - Date.now()

startCountdownCheck = () ->
    console.log countdownStart - Date.now()
    setTimeout startCountdown, countdownStart - Date.now()

startMovie = () ->
    switchContent "/premiere/movie"
    setTimeout startPostshow, movieDone - Date.now()

startPostshow = () ->
    switchContent "/premiere/postshow/#{userCategory}"

if Date.now() > movieDone
    startPostshow()
else if Date.now() > movieStart
    startMovie()
else if Date.now() > countdownStart
    startCountdown()
else
    setupCategory()
    #startCountdownCheck()