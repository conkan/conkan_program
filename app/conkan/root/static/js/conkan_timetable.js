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

// 現在操作中企画サービス
ConkanAppModule.service( 'currentprgService', function() {
    this.current = {
      regpgid : '', subno : '', pgid :   '', id :      '', target : '',
      sname :   '', name :  '', stat :   '',
      date1 :   '', shour1 :  '', smin1 : '', ehour1 : '', emin1 :  '',
      date2 :   '', shour2 :  '', smin2 : '', ehour2 : '', emin2 :  '',
      roomid :  ''
    };
    this.get = function() { return this.current; };
});
