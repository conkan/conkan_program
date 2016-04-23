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

// conkanProgressListモジュールの生成
var ConkanAppModule = angular.module('conkanProgressList',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.grid.pagination', 'ui.bootstrap'] );

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
