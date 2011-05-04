$(function() {
  $('.entry').live('click', function() {
      entry($(this).attr('id'));
  });
});

function entry(asin) {
  var request = new Object();
  request.asin = asin;

  $.post(
    "bookentry",
    request,
    function(json) {
      var items = eval("(" + json + ")");
      var html = items.title + ' を登録しました！';
      var cls = 'success';

      if(items.status_id == '1') {
        html = '既に登録されています。';
        cls = 'error';
      } else if(items.status_id == '2') {
        html = 'エラーが発生しました。';
        cls = 'error';
      }

      $.notifyBar({
        html: html, 
        delay: 50000,
        animationSpeed: 'normal',
        close: true,
        cls: cls
      }); 
    },
    'JSON'
  );
}

