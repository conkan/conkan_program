// conkan_common.js --- conkan 共通関数群 ---
/*esLint-env jquery, prototypejs */
// 単一オブジェクトの中にカプセル化すること手もあるが、
// ここは敢えてグローバルに定義 (ユーティリティ関数のみ)
//
// 非グリッドのリサイズ
var uiPlainResize = function ( target ) {
  var h,gh,
    wh = angular.element(window).innerHeight(),
    welldiv = angular.element(target),
    adddiv = angular.element("#pgAddDiv"),
    footer = angular.element("#main-footer");
  if ( welldiv.size() !== 0 ) {
    h    = wh - ( welldiv.offset().top +
                  parseFloat(welldiv.css('marginBottom')) +
                  adddiv.outerHeight() +
                  footer.outerHeight()
                );
    welldiv.css('height', h + 'px');
    welldiv.css('min-height', h + 'px');
    welldiv.css('max-height', h + 'px');
  }
};

// グリッドのリサイズ
var uiGridResize = function () {
  var h,gh,
    wh = angular.element(window).innerHeight(),
    pgldiv = angular.element("#gridlist"),
    grddiv = angular.element("#gridlist .grid"),
    adddiv = angular.element("#pgAddDiv"),
    footer = angular.element("#main-footer"),
    viewport = angular.element('#gridlist .ui-grid-viewport');
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
                  adddiv.outerHeight() +
                  footer.outerHeight()
                );
    grddiv.css('height', h + 'px');
    grddiv.css('max-height', h + 'px');
    grddiv.css('min-height', h + 'px');
    gh = h - ( angular.element('#gridlist .ui-grid-header').height() +
               angular.element('#gridlist .ui-grid-scrollbar-placeholder').height() +
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
  wkcnf.scale_hash  = angular.fromJson(data.json.gantt_scale_str);
  wkcnf.time_origin = data.json.time_origin;
  wkcnf.dates       = angular.fromJson(data.json.dates);
  wkcnf.hours1      = GetHours(undefined, wkcnf);
  wkcnf.hours2      = GetHours(undefined, wkcnf);
  wkcnf.mins        = ['00','05','10','15','20','25',
                       '30','35','40','45','50','55' ];
  wkcnf.roomlist    = angular.fromJson(data.json.roomlist);
  wkcnf.stafflist   = angular.fromJson(data.json.stafflist);
  wkcnf.nos         = [ '0', '1', '2', '3', '4' ];
  wkcnf.status      = angular.fromJson(data.json.pg_status_vals);
  wkcnf.cast_status = angular.fromJson(data.json.cast_status_vals);
  wkcnf.def_regEquip = angular.fromJson(data.json.def_regEquip);
  wkcnf.yesno       = [ 'する', 'しない' ];
  wkcnf.dates.unshift(''); // 日付初期化用
  wkcnf.roomlist.unshift({id:'',val:''}); // 部屋初期化用

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
  prog.csid    = data.csid;
  prog.crole   = data.crole;
  prog.roomid  = data.roomid;
  prog.memo    = data.memo;
  prog.progressprp = data.progressprp;
  prog.noteditable = 
      (   ( data.crole == 'ROOT' )
         || ( data.crole == 'PG' ) ) ? false : true;
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
        angular.element('*[name=' + cur.dh + ']').each(function() {
          elmSetValid( this, false );
        });
      }
      else {
        angular.element('*[name=' + cur.dh + ']').each(function() {
          elmSetValid( this, true );
        });
      }
    }
  }
  return retval;
};

// UI部品有効化/無効化
var elmSetValid = function( obj, valid ) {
  if ( valid ) {
    angular.element(obj).removeClass('ng-invalid');
    angular.element(obj).addClass('ng-valid');
    angular.element(obj).$invalid = false;
  }
  else {
    angular.element(obj).removeClass('ng-valid');
    angular.element(obj).addClass('ng-invalid');
    angular.element(obj).$invalid = true;
  }
};

// JSON POST汎用実施
var doJsonPost = function( $http, url, data, $uibModalInstance, $uibModal,
                           finalcallback ) {
  $http( {
    method  : 'POST',
    url     : url,
    headers : { 'Content-Type':
                  'application/x-www-form-urlencoded; charset=UTF-8' },
    data: data
  })
  .success(function(data) {
    if ( data.status != 'nodlgok' ) {
      openDialog( data.status, data.json, $uibModal,
                  $uibModalInstance, finalcallback );
    }
  })
  .error(function(data) {
    openDialog( '', data.json, $uibModal,
                $uibModalInstance, finalcallback );
  })
  .finally( function() {
    if ( !$uibModalInstance && finalcallback ) {
      finalcallback();
    }
  });
};

// 共通のHTTPエラー時ダイアログ表示
var httpfailDlg = function( $uibModal ) {
  var modalinstance = $uibModal.open(
      { templateUrl : getTemplate( '' ), }
  );
  modalinstance.rendered.then( function() {
    angular.element('.modal-dialog').draggable({handle: '.modal-header'});
  });
  modalinstance.result.then( function() {} );
};

// 共通のダイアログサイズ調整とドラッガブル化
var dialogResizeDrag = function() {
  var
    dialog = angular.element('.modal-dialog'),
    wh = angular.element(window).innerHeight();

  dialog.draggable({handle: '.modal-header'});
  if ( dialog.outerHeight() < wh ) {
    return;
  }

  var
    content = angular.element('.modal-content'),
    header  = angular.element('.modal-header'),
    body    = angular.element('.modal-body'),
    footer  = angular.element('.modal-footer'); 

  var vh = wh -
            ( parseInt( dialog.css('marginTop')) +
              parseInt( dialog.css('borderTopWidth')) +
              parseInt( dialog.css('paddingTop')) +
              parseInt( content.css('marginTop')) +
              parseInt( content.css('borderTopWidth')) +
              parseInt( content.css('paddingTop')) +
              parseInt( body.css('marginTop')) +
              parseInt( body.css('marginBottom')) +
              parseInt( body.css('borderTopWidth')) +
              parseInt( body.css('borderBottomWidth')) +
              parseInt( body.css('paddingTop')) +
              parseInt( body.css('paddingBottom')) +
              header.outerHeight() +
              footer.outerHeight() + 1 );
  if ( vh < parseInt(content.css('min-height')) ) {
    vh = parseInt(content.css('min-height'));
  }
  body.css( 'height', vh );
};

// HTTP後のエラーダイアログ表示( statがエラーの場合も含む )
var openDialog = function ( stat, json, uibModal, uibInstance, finalcb ) {
  if ( uibInstance ) {
    uibInstance.close('done');
  }
  var resultDlg = uibModal.open(
    {
      templateUrl : getTemplate( stat ),
      backdrop    : 'static',
    }
  );
  resultDlg.rendered.then( function() {
    angular.element('.modal-dialog').draggable({handle: '.modal-header'});
    if ( stat === 'dupl' ) {
      angular.element('#dupkey').text(json.dupkey);
      angular.element('#dupval').text(json.dupval);
    }
  });
  resultDlg.result.then( function() {
    if ( finalcb ) {
      finalcb(stat);
    }
    else {
      location.reload();
    }
  });
};

// JSON POST後のstatusからtemplate名を得る
var getTemplate = function( stat ) {
  var templateTbl = {
    'update'    : 'T_result_update',    // 更新成功
    'fail'      : 'T_result_fail',      // 更新失敗(排他)
    'ipdupfail' : 'T_result_ipdup',     // 更新失敗(企画番号重複)
    'dbfail'    : 'T_result_dberr',     // 更新失敗(DBエラー)
    'dupl'      : 'T_result_dupl',      // 更新失敗(重複)
    'pguse'     : 'T_result_pguse',     // 更新失敗(使用中)
    'add'       : 'T_result_add',       // 追加成功
    'del'       : 'T_result_del',       // 削除成功
    'delfail'   : 'T_result_delfail',   // 削除失敗(排他)
    'inuse'     : 'T_result_inuse',     // 削除失敗(使用中)
    'inroom'    : 'T_result_inroom',    // 削除失敗(部屋設置中)
    'noexist'   : 'T_result_noexist',   // データ取得失敗(対象削除済)
    ''          : 'T_httpget_fail',     // データ取得失敗(詳細不明)
  };
  var retval = templateTbl[stat] || 'T_httpget_fail'; // デフォルト値
  return retval;
};
    
// EOF --
