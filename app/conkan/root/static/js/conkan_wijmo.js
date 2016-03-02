var wijGridResize = function () {
  var
  h,
  wh = window.innerHeight || $(window).innerHeight(),
  pgldiv = $("#gridlist"),
  wijdiv = $("#gridlist .wijgridouterdiv"),
  scldiv = $("#gridlist .wijmo-wijgrid-scroller"),
  adddiv = $("#pgAddDiv");
  if ( pgldiv.size() !== 0 ) {
    h    = wh - ( pgldiv.offset().top +
                  parseFloat(pgldiv.css('paddingTop')) +
                  parseFloat(pgldiv.css('paddingBottom')) +
                  parseFloat(pgldiv.css('borderTopWidth')) +
                  parseFloat(pgldiv.css('borderBottomWidth')) +
                  parseFloat(pgldiv.css('marginTop')) +
                  parseFloat(pgldiv.css('marginBottom')) +
                  parseFloat(wijdiv.css('borderTopWidth')) +
                  parseFloat(wijdiv.css('borderBottomWidth')) +
                  adddiv.outerHeight() );
    scldiv.css('max-height', h + 'px');
  }
};
