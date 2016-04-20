// リサイズ
var uiGridResize = function () {
  var
  h,gh,
  wh = window.innerHeight || $(window).innerHeight(),
  pgldiv = $("#gridlist"),
  grddiv = $("#gridlist .grid"),
  adddiv = $("#pgAddDiv"),
  viewport = $('#gridlist .ui-grid-viewport');
  if ( pgldiv.size() !== 0 ) {
    h    = wh - ( pgldiv.offset().top +
                  parseFloat(pgldiv.css('paddingTop')) +
                  parseFloat(pgldiv.css('paddingBottom')) +
                  parseFloat(pgldiv.css('borderTopWidth')) +
                  parseFloat(pgldiv.css('borderBottomWidth')) +
                  parseFloat(pgldiv.css('marginTop')) +
                  parseFloat(pgldiv.css('marginBottom')) +
                  parseFloat(grddiv.css('borderTopWidth')) +
                  parseFloat(grddiv.css('borderBottomWidth')) +
                  parseFloat(adddiv.css('marginBottom')) +
                  adddiv.outerHeight() );
    grddiv.css('height', h + 'px');
    grddiv.css('max-height', h + 'px');
    grddiv.css('min-height', h + 'px');
    gh = h - ( $('#gridlist .ui-grid-header').height() +
               $('#gridlist .ui-grid-scrollbar-placeholder').height() +
               1);
    viewport.css('height', gh + 'px');
    viewport.css('min-height', gh + 'px');
    viewport.css('max-height', gh + 'px');
  }
};

// グリッドセルクラス取得
var uiGetCellCls = function( disable ) {
    var cont = 'ui-grid-vcenter';
    if ( disable ) {
        cont += ' disableRow';
    }
    return cont;
};

// 編集ボタン生成
//  $sce    : sceサービス
//  disable : 無効か?
//  target  : data-tagetの値
//  datas   : オブジェクト配列 { key : data-名 val : 値 }
var uiGetEditbtn = function( disable, target, datas ) {
    var cont = '<button type="button" class="btn btn-xs';
    if ( disable ) {
        cont += '">無効</button>';
    }
    else {
        cont += ' btn-primary" data-toggle="modal" data-target="'
                + target + '"';
        for ( var cnt in datas ) {
            cont += ' data-' + datas[cnt].key + '="' + datas[cnt].val + '"';
        }
        cont += '>編集</button>';
    }
    return cont;
};


