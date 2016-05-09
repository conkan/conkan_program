// conkan_ui_grid.js --- angular 共通関数群 ---
// グリッドのリサイズ
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
//  disable : BOOL 無効行か?
var uiGetCellCls = function( disable ) {
    var cont = 'ui-grid-vcenter';
    if ( disable ) {
        cont += ' disableRow';
    }
    return cont;
};

// 編集ボタン生成
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

// 日付から時刻範囲を得るとともに、日付がクリアされたら時刻を初期化
//  date: 日付
//  conf: 設定オブジェクト
//  prog: 企画情報オブジェクト
//  dnum: 何日目かを示す数字
var GetHours = function( date, conf, prog, dnum ) {
    var hours = [],
    st = date ? conf.scale_hash[date][3] * 1
              : 0 + conf.time_origin * 1,
    et = date ? conf.scale_hash[date][4] * 1
              : 23 + conf.time_origin * 1,
    len = et - st;
    for ( var cnt=0; cnt<=len; cnt++ ) {
        hours[cnt] = ( "00" + ( st + cnt ) ).substr(-2);
    }
    if ( !date && prog ) {
        prog['shour' + dnum] = undefined;
        prog['smin'  + dnum] = undefined;
        prog['ehour' + dnum] = undefined;
        prog['emin'  + dnum] = undefined;
    }
    return hours;
};

// /config/confgetが返す選択肢情報を設定オブジェクトに変換
//  data: 選択肢情報
var ConfDataCnv = function( data ) { 
    var wkcnf = {};
    wkcnf.scale_hash  = JSON.parse(data.json.gantt_scale_str);
    wkcnf.time_origin = data.json.time_origin;
    wkcnf.dates       = JSON.parse(data.json.dates);
    wkcnf.hours1      = GetHours(undefined, wkcnf);
    wkcnf.hours2      = GetHours(undefined, wkcnf);
    wkcnf.mins        = ['00','05','10','15','20','25',
                         '30','35','40','45','50','55' ];
    wkcnf.roomlist    = JSON.parse(data.json.roomlist);
    wkcnf.stafflist   = JSON.parse(data.json.stafflist);
    wkcnf.nos         = [ '0', '1', '2', '3', '4' ];
    wkcnf.status      = JSON.parse(data.json.pg_status_vals);
    wkcnf.dates.unshift(''); // 日付初期化用

    return wkcnf;
};

// /timetable/{{id}} が返す企画情報を変換して企画情報オブジェクトに設定
// data: 企画情報
// prog: 企画情報オブジェクト
var ProgDataCnv = function( data, prog ) {
    prog.regpgid = data.regpgid;
    prog.subno   = data.subno;
    prog.pgid    = data.pgid;
    prog.sname   = data.sname;
    prog.name    = data.name;
    prog.date1   = data.date1  ? data.date1  : undefined;
    prog.shour1  = data.shour1 ? data.shour1 : undefined;
    prog.smin1   = data.smin1  ? data.smin1  : undefined;
    prog.ehour1  = data.ehour1 ? data.ehour1 : undefined;
    prog.emin1   = data.emin1  ? data.emin1  : undefined;
    prog.date2   = data.date2  ? data.date2  : undefined;
    prog.shour2  = data.shour2 ? data.shour2 : undefined;
    prog.smin2   = data.smin2  ? data.smin2  : undefined;
    prog.ehour2  = data.ehour2 ? data.ehour2 : undefined;
    prog.emin2   = data.emin2  ? data.emin2  : undefined;
    prog.status  = data.status;
    prog.layerno = data.layerno;
    prog.staffid = data.staffid;
    prog.roomid  = data.roomid;
    prog.memo    = data.memo;
    prog.progressprp = data.progressprp;
};

// 企画時刻バリデーション
//  prog: 企画情報オブジェクト
//  scale_hash : 日毎開始終了時刻ハッシュ
//
//  戻り値: BOOL true: NG false: OK
//
//  なお、日/時/分 select は、この中でinvalidにするので、nameは固定
//  (1日目: dh1data 2日目: dh2data)
var ProgTimeValid = function( prog, scale_hash ) {
    var cnt, cur, scale, start, end;
    var retval = false;
    var ckarray = [
        {
            dh    : 'dh1date',
            date  : prog.date1,
            shour : prog.shour1,
            smin  : prog.smin1,
            ehour : prog.ehour1,
            emin  : prog.emin1
        },
        {
            dh    : 'dh2date',
            date  : prog.date2,
            shour : prog.shour2,
            smin  : prog.smin2,
            ehour : prog.ehour2,
            emin  : prog.emin2
        }
    ];

    for ( cnt in ckarray ) {
        if ( ckarray[cnt].date ) {
            cur = ckarray[cnt];
            scale = scale_hash[cur.date];
            start = ( cur.shour * 60 ) + ( cur.smin * 1 );
            end   = ( cur.ehour * 60 ) + ( cur.emin * 1 );
            if (   ( start >= end )
                || ( start < scale[0] ) || ( scale[1] < end ) ) {
                retval = true;
                $('*[name=' + cur.dh + ']').each(function() {
                    $(this).addClass('ng-invalid');
                    $(this).removeClass('ng-valid');
                    $(this).$invalid = true;
                });
            }
            else {
                $('*[name=' + cur.dh + ']').each(function() {
                    $(this).removeClass('ng-invalid');
                    $(this).addClass('ng-valid');
                    $(this).$invalid = false;
                });
            }
        }
    }
    return retval;
};

// EOF --
