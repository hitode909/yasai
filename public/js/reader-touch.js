$(function() {
  var caches, create_cache_image, next_page, prepare_first_cache, prepare_next_cache, size_params, _i;
  caches = [];
  size_params = function() {
    return "?width=" + window.innerWidth + "&height=" + window.innerHeight;
  };
  create_cache_image = function(path) {
    var img;
    img = $('<img>').attr({
      src: path,
      'data-path': path
    });
    img.appendTo($('#caches'));
    return caches.push(img);
  };
  prepare_first_cache = function() {
    var book_id;
    book_id = $('body').attr('data-book-id');
    return create_cache_image(("/read/" + book_id + "/image/r/1.jpg") + size_params());
  };
  prepare_next_cache = function() {
    var book_id, last_cache, match, next_page_num, next_path, next_rl, page_num, path, rl, _;
    last_cache = caches[caches.length - 1];
    path = last_cache.attr('data-path');
    match = path.match(/^\/read\/(\d+)\/image\/(\w)\/(\d+)\.jpg$/);
    _ = match[0], book_id = match[1], rl = match[2], page_num = match[3];
    if (rl === "r") {
      next_rl = "l";
      next_page_num = page_num;
    } else {
      next_rl = "r";
      next_page_num = +page_num + 1;
    }
    next_path = ("/read/" + book_id + "/image/" + next_rl + "/" + next_page_num + ".jpg") + size_params();
    return create_cache_image(next_path);
  };
  next_page = function() {
    var image;
    $('#stage img').remove();
    image = caches.shift();
    image.appendTo('#stage');
    image.click(function() {
      return next_page();
    });
    if (caches.length < 3) {
      return prepare_next_cache();
    }
  };
  prepare_first_cache();
  for (_i = 1; _i <= 3; _i++) {
    prepare_next_cache();
  }
  return next_page();
});