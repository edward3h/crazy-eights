$ ->
  messages = []
  window.socket = socket = io.connect("#{window.location.protocol}//#{window.location.host}")

  room = 0

  appendData = (data) ->
    { user, message } = data
    if message
      messages.push { user, message }
      $('.stuff').html ''
      $('.stuff').append "#{i.user}: #{i.message}<br />" for i in messages
      console.log 'MESSAGEEEEEEEEEEEE'
    else
      console.log 'problem lol'

  socket.on 'room-0', (data) ->
    if data instanceof Array
      appendData(i) for i in data
    else if data instanceof Object
      appendData(data)
    else
      throw "Invalid return value"


  socket.emit 'initial', { room }

  $('.chat').submit (e) ->
    e.preventDefault()

    user = $('.user input').val()
    message = $('.message input').val()
    room = 0

    socket.emit 'send', { user, message, room }
