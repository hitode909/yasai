$ ->
  caches = []

  create_cache_image = (path) ->
    img = $('<img>').attr
      src: path
      'data-path': path
    img.appendTo($('#caches'))
    caches.push(img)

  prepare_first_cache = ->
    book_id = $('body').attr('data-book-id')
    create_cache_image("/read/#{book_id}/image/r/1.jpg")

  prepare_next_cache = ->
    last_cache = caches[caches.length - 1]
    path = last_cache.attr('data-path')
    match = path.match /^\/read\/(\d+)\/image\/(\w)\/(\d+)\.jpg$/
    [_, book_id, rl, page_num] = match
    if rl == "r"
      next_rl = "l"
      next_page_num = page_num
    else
      next_rl = "r"
      next_page_num = +page_num + 1

    next_path = "/read/#{book_id}/image/#{next_rl}/#{next_page_num}.jpg"
    create_cache_image(next_path)

  next_page = ->
    $('#stage img').remove()

    image = caches.shift()
    image.appendTo('#stage')

    image.click ->
      next_page()

    if caches.length < 3
      prepare_next_cache()

  # -----
  prepare_first_cache()

  for [1..3]
    prepare_next_cache()

  next_page()
