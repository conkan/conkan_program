var wijGridResize = function () {
  <!-- dataGridのstyle:heightを、計算し設定 -->
  var
  h,
  wh = window.innerHeight || $(window).innerHeight(),
  pgldiv = $("#gridlist"),
  wijdiv = $("#gridlist .wijgridouterdiv"),
  adddiv = $("#pgAddDiv");
  h  = wh - ( pgldiv.offset().top +
              parseFloat(pgldiv.css('paddingTop')) +
              parseFloat(pgldiv.css('paddingBottom')) +
              parseFloat(pgldiv.css('borderTopWidth')) +
              parseFloat(pgldiv.css('borderBottomWidth')) +
              parseFloat(pgldiv.css('marginTop')) +
              parseFloat(pgldiv.css('marginBottom')) +
              parseFloat(wijdiv.css("borderTopWidth")) +
              parseFloat(wijdiv.css("borderBottomWidth")) +
              adddiv.outerHeight() );
  wijdiv.height(h + 'px');
};
