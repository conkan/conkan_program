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

// 日付から時刻範囲を得る
//  date: 日付
//  conf: 設定オブジェクト
var GetHours = function( date, conf ) {
    var hours = [],
    st = date ? conf.scale_hash[date][3] * 1
              : 0 + conf.time_origin * 1,
    et = date ? conf.scale_hash[date][4] * 1
              : 23 + conf.time_origin * 1,
    len = et - st;
    for ( var cnt=0; cnt<=len; cnt++ ) {
        hours[cnt] = ( "00" + ( st + cnt ) ).substr(-2);
    }
    return hours;
};
//
// 取得したJSON情報を設定オブジェクトに変換
//  data: JSON情報
var ConfDataCnv = function( data ) { 
    var wkcnf = {};
    wkcnf.scale_hash  = JSON.parse(data.json.gantt_scale_str);
    wkcnf.time_origin = data.json.time_origin;
    wkcnf.dates       = JSON.parse(data.json.dates);
    wkcnf.hours1      = GetHours(undefined,wkcnf);
    wkcnf.hours2      = GetHours(undefined,wkcnf);
    wkcnf.mins        = ['00','05','10','15','20','25',
                         '30','35','40','45','50','55' ];
    wkcnf.roomlist    = JSON.parse(data.json.roomlist);
    wkcnf.stafflist   = JSON.parse(data.json.stafflist);
    wkcnf.nos         = [ '0', '1', '2', '3', '4' ];
    wkcnf.status      = JSON.parse(data.json.pg_status_vals);
    wkcnf.dates.unshift(''); // 日付初期化用

    return wkcnf;
};

// EOF --
