$(window).resize(function() {
  // リサイズによるタイムテーブル領域の調整
  var
  h,
  wh = window.innerHeight || $(window).innerHeight(),
  updiv   = $("#timetable_up"),
  downdiv = $("#timetable_down");
  h = wh - ( updiv.offset().top +
             downdiv.outerHeight() +
             parseFloat(downdiv.css('marginTop'))
           );
  updiv.css('height', h + 'px');
  updiv.css('max-height', h + 'px');
  $("#unset_pglist_wrap").css('min-height', h + 'px');
  $("#timetable_wrap").css('min-height', h + 'px');
});
