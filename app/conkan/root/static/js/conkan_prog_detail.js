var storage = sessionStorage;
$(document).ready(function(){
  $(document).scrollTop( storage.getItem( 'sctop' ) );
  storage.removeItem( 'sctop' );
});
// スクロール制御
$('.subtag a').click(function(){
  var pd, tp;
  pd = parseInt($(document.body).css('padding-top'));
  tp = $(this.hash).position().top;
  $(document).scrollTop(tp-pd);
  return false;
});
// モーダルダイアログ表示
$('#PgEdit').on('show.bs.modal', function (event) {
  var pgid   = $(event.relatedTarget).data('whatpgid');
  var id     = $(event.relatedTarget).data('whatitem');
  var target = $(event.relatedTarget).data('whattarget');
  var content = $('#PgEditContent');
  var arg = '/program/' + pgid + '/' + target;
  if ( id != "-" ) {
      arg += '/' + id;
  }
  arg += '/ FORM';
  $(content).load(arg);
  if ( !id ) {
      $('#dobtn').text('追加');
  }
  $('#dobtn').show();
  if ( target == "equip" && id ) {
      $('#dodel').show();
  } else {
      $('#dodel').hide();
  }
} );
// モーダルダイアログ表示後サイズ調整
$('#PgEdit').on('shown.bs.modal', function (event) {
  if ( $('#PgEditDialog').outerHeight() < $(window).height() ) return;
  var content = $('#PgEditContent');
  var vh = content.offset().top + 1 +
           $('#PgEditFooter').outerHeight() + 
           parseInt( $('#PgEditDialog').css('marginTop'))
           parseInt( $('#PgEditDialog').css('marginBottom'));
  content.css( 'height', $(window).height() - vh );
} );
// モーダルダイアログ非表示
$('#PgEdit').on('hide.bs.modal', function (event) {
  storage.setItem( 'sctop', $(document).scrollTop() );
  location.reload(true);
} );
// 更新/追加
$('#dobtn').click(function(event) {
  // バリデーション
  var vha = $('#progform #vha').data('vha');
  for ( var i in vha ) {
    if (!$('#'+ vha[i].id).val()) {
      $('#valerr').text(vha[i].name + 'は必須です');
      $('#' + vha[i].id).css('background-color', '#ff8e8e');
      return false;
    }
    else {
      $('#' + vha[i].id).css('background-color', '');
    }
  }
  var content = $('#PgEditContent');
  var data = $('#progform').serializeArray();
  var pgid   = $('#progform #pgid').val();
  var id     = $('#progform #id').val() || 0;
  var target = $('#progform #target').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  var arg = '/program/' + pgid + '/' + target;
  if ( id != "-" ) {
      arg += '/' + id;
  }
  arg += '/ FORM';
  $(content).load(arg, data );
} );
// 削除
$('#dodel').click(function(event) {
  var content = $('#PgEditContent');
  var pgid    = $('#progform #pgid').val();
  var id      = $('#progform #id').val() || 0;
  var target  = $('#progform #target').val();
  var data = $('#progform').serializeArray();
  $('#dobtn').hide();
  $('#dodel').hide();
  var arg = '/program/' + pgid + '/' + target + '/' + id + '/del/ FORM';
  $(content).load(arg, data );
} );
// 進捗登録
$('#addProgress button').click(function(event) {
  storage.setItem( 'sctop', $(document).scrollTop() );
} );
// 企画複製分割
$('#pgcpysepform button').click(function(event) {
  var act  = $(event.target).data('cpysep');
  $('#pgcpysepform #cpysep_act').val(act);
} );

// conkanProgDetailモジュールの生成
var ConkanAppModule = angular.module('conkanProgDetail',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.grid.pagination', 'ui.bootstrap'] );

// 企画詳細コントローラ
ConkanAppModule.controller( 'progDetailController',
    [ '$scope', '$http', '$uibModal',
        function( $scope, $http, $uibModal ) {
            // 企画概要フォーム
            $scope.openPgEditForm = function( pgid ) {
                $scope.pgid = pgid;
                $uibModal.open({
                    templateUrl : "T_pgup_program",
                    controller  : 'progFormController',
                    backdrop    : "static",
                    scope       : $scope,
                    size        : 'lg',
                });
            };
        }
    ]
);

// 企画更新フォームコントローラ
ConkanAppModule.controller( 'progFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance',
        function( $scope, $http, $uibModal, $uibModalInstance ) {
            $scope.$watch('prog.date1', function( n, o, scope ) {
                if ( n != o ) {
                    scope.conf['hours1'] = GetHours(n, scope.conf);
                    if (!n) {
                        scope.prog.shour1 = undefined;
                        scope.prog.smin1 = undefined;
                        scope.prog.ehour1 = undefined;
                        scope.prog.emin1 = undefined;
                    }
                }
            });
            $scope.$watch('prog.date2', function( n, o, scope ) {
                if ( n != o ) {
                    scope.conf['hours2'] = GetHours(n, scope.conf);
                    if (!n) {
                        scope.prog.shour2 = undefined;
                        scope.prog.smin2 = undefined;
                        scope.prog.ehour2 = undefined;
                        scope.prog.emin2 = undefined;
                    }
                }
            });

            $scope.prgdoApply = function() {
                // 二重クリック回避
                var pgid = $scope.prog.pgid;
                $('#prgapplybtn').attr('disabled', 'disabled');
                // バリデーション ## 共通化対象
                if (!(pgid)) {
                    $('#prgapplybtn').removeAttr('disabled');
                    return;
                }
                ckarray = [
                    {
                        dh    : 'dh1date',
                        date  : $scope.prog.date1,
                        shour : $scope.prog.shour1,
                        smin  : $scope.prog.smin1,
                        ehour : $scope.prog.ehour1,
                        emin  : $scope.prog.emin1
                    },
                    {
                        dh    : 'dh2date',
                        date  : $scope.prog.date2,
                        shour : $scope.prog.shour2,
                        smin  : $scope.prog.smin2,
                        ehour : $scope.prog.ehour2,
                        emin  : $scope.prog.emin2
                    }
                ];
                for ( cnt in ckarray ) {
                    cur = ckarray[cnt];
                    $('*[name=' + cur.dh + ']').each(function() {
                        $(this).removeClass('ng-invalid');
                        $(this).addClass('ng-valid');
                        $(this).$invalid = false;
                    });
                }
                for ( cnt in ckarray ) {
                    if ( ckarray[cnt].date ) {
                        cur = ckarray[cnt];
                        scale = $scope.conf.scale_hash[cur.date];
                        start = ( cur.shour * 60 ) + ( cur.smin * 1 );
                        end   = ( cur.ehour * 60 ) + ( cur.emin * 1 );
                        if (   ( start >= end )
                            || ( start < scale[0] ) || ( scale[1] < end ) ) {
                            $('#valerr').text('時刻設定に矛盾があります');
                            $('*[name=' + cur.dh + ']').each(function() {
                                $(this).addClass('ng-invalid');
                                $(this).removeClass('ng-valid');
                                $(this).$invalid = true;
                            });
                            $('#prgapplybtn').removeAttr('disabled');
                            return;
                        }
                    }
                }
                // バリデーション完了
                $http( {
                    method : 'POST',
                    url : '/timetable/' + pgid,
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
                    data: $.param($scope.prog)
                }).success(function(data) {
                    // templateを一つにまとめたいところ
                    var modalinstance, templateval;
                    $uibModalInstance.close('done');
                    if (data.status == 'update') {
                        templateval = 'T_result_update';
                    }
                    else {
                        templateval = 'T_result_fail';
                    }
                    modalinstance = $uibModal.open(
                        {
                            templateUrl : templateval,
                            backdrop    : 'static'
                        }
                    );
                    modalinstance.result.then( function() {
                        location.reload();
                    });
                }).error(function(data) {
                    $uibModalInstance.close('done');
                    var modalinstance = $uibModal.open(
                        {
                            templateUrl : 'T_result_dberr',
                            backdrop    : 'static'
                        }
                    );
                    modalinstance.result.then( function() {
                        location.reload();
                    });
                });
            };

            // 選択肢取得
            $http.get('/config/confget')
            .success(function(data) {
                $scope.conf = ConfDataCnv( data, $scope.conf );
            })
            .error(function(data) {
                var modalinstance = $uibModal.open(
                    { templateUrl : 'T_httpget_fail' }
                );
                modalinstance.result.then( function() {} );
            });

            $('#valerr').text('');
            $http({
                method  : 'GET',
                url     : '/timetable/' + $scope.pgid
            })
            .success(function(data, status, headers, config) {
               // ここは共通化したい
               $scope.prog = {};
               $scope.prog.regpgid = data.regpgid;
               $scope.prog.subno   = data.subno;
               $scope.prog.pgid    = data.pgid;
               $scope.prog.sname   = data.sname;
               $scope.prog.name    = data.name;
               $scope.prog.date1   = data.date1  ? data.date1  : undefined;
               $scope.prog.shour1  = data.shour1 ? data.shour1 : undefined;
               $scope.prog.smin1   = data.smin1  ? data.smin1  : undefined;
               $scope.prog.ehour1  = data.ehour1 ? data.ehour1 : undefined;
               $scope.prog.emin1   = data.emin1  ? data.emin1  : undefined;
               $scope.prog.date2   = data.date2  ? data.date2  : undefined;
               $scope.prog.shour2  = data.shour2 ? data.shour2 : undefined;
               $scope.prog.smin2   = data.smin2  ? data.smin2  : undefined;
               $scope.prog.ehour2  = data.ehour2 ? data.ehour2 : undefined;
               $scope.prog.emin2   = data.emin2  ? data.emin22 : undefined;
               $scope.prog.status  = data.status;
               $scope.prog.layerno = data.layerno;
               $scope.prog.staffid = data.staffid;
               $scope.prog.roomid  = data.roomid;
               $scope.prog.memo    = data.memo;
               $scope.prog.progressprp = data.progressprp;
            })
            .error(function(data) {
                var modalinstance = $uibModal.open(
                    { templateUrl : 'T_httpget_fail' }
                );
                modalinstance.result.then( function() {} );
            });
        }
    ]
);

// 進捗リストコントローラ
ConkanAppModule.controller( 'progressListController',
    [ '$scope', '$sce', '$http', '$uibModal', 'uiGridConstants',
        function( $scope, $sce, $http, $uibModal, uiGridConstants ) {
            var pageSize = 5;
            $scope.progressgrid = {
                enableFiltering: false,
                enableSorting: false,
                treeRowHeaderAlwaysVisible: false,
                enableColumnResizing: true,
                enableGridMenu: false,
                paginationPageSize: pageSize,
                paginationPageSizes: [ pageSize ],
                useExternalPagination: true,
                enableHorizontalScrollbar: uiGridConstants.scrollbars.NEVER,
                enableVerticalScrollbar: uiGridConstants.scrollbars.NEVER,
                onRegisterApi: function(gridApi) {
                    $scope.gridApi = gridApi;
                    gridApi.pagination.on.paginationChanged($scope,
                        function(nPage) {
                            getPage(nPage);
                        });
                }
            };

            $scope.progressgrid.columnDefs = [
                { name : '報告日時', field : 'repdatetime',
                    headerCellClass: 'gridheader',
                    width: "17%",
                    cellClass: 'ui-grid-vcenter',
                    enableHiding: false,
                },
                { name : '報告者', field : 'tname',
                    headerCellClass: 'gridheader',
                    width: "17%",
                    cellClass: 'ui-grid-vcenter',
                    enableHiding: false,
                },
                { name : '内容', field : 'report',
                    headerCellClass: 'gridheader',
                    cellClass: 'ui-grid-vcenter',
                    enableHiding: false,
                },
            ];
            var getPage = function( newPage ) {
                var pgid = $('#progress_pgid').val();
                var url = '/program/' + pgid + '/progress/'
                            + newPage + '/' + pageSize + '/';
                $http.get(url)
                .success(function(data) {
                    $scope.progressgrid.totalItems = data.totalItems;
                    $scope.progressgrid.data = data.json;
                })
                .error(function(data) {
                    var modalinstance = $uibModal.open(
                        { templateUrl : 'T_httpget_fail' }
                    );
                    modalinstance.result.then( function() {} );
                });
            };

            getPage(1);
        }
    ]
);

// -- EOF --