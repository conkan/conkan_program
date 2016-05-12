// conkan_cast_list.js --- 出演者一覧用 JS ---
var storage = sessionStorage;
var needreload = false;
$(document).ready(function(){
  $(document).scrollTop( storage.getItem( 'sctop' ) );
  storage.clear();
});
// モーダルダイアログ表示
$('#editCast').on('show.bs.modal', function (event) {
  var castid = $(event.relatedTarget).data('whatever');
  var content = $('#editCastContent');
  needreload = false;
  $(content).load(castid + '/ FORM');
  if ( $(event.relatedTarget).data('rmcol') ) {
    $('#dobtn').hide();
    $('#dodel').hide();
  }
  else {
    $('#dobtn').show();
    $('#dodel').show();
  }
} );
// モーダルダイアログ非表示
$('#editCast').on('hide.bs.modal', function (event) {
  storage.setItem( 'sctop', $(document).scrollTop() );
  if ( needreload ) {
    location.reload(true);
  }
} );
// 更新
$('#dobtn').click(function(event) {
  if (!$('#name').val()) {
      $('#valerr').text('氏名は必須です');
      return false;
  }
  var content = $('#editCastContent');
  var data = $('#castform').serializeArray();
  var castid = $('#castid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(castid + '/edit/ FORM', data );
  needreload = true;
} );
// 削除
$('#dodel').click(function(event) {
  var content = $('#editCastContent');
  var data = $('#castform').serializeArray();
  var castid = $('#castid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(castid + '/del/ FORM', data );
  needreload = true;
} );

// conkanCastListモジュールの生成(グローバル変数)
var ConkanAppModule = angular.module('conkanCastList',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

// 出演者リストコントローラ
ConkanAppModule.controller( 'castListController',
    [ '$scope', '$sce', '$http', '$uibModal',
        function( $scope, $sce, $http, $uibModal ) {
            $scope.__getEditbtn = function( rmdate, castid ) {
                var cont = uiGetEditbtn( rmdate, '#editCast',
                        [ { 'key' : 'whatever', 'val' : castid },
                          { 'key' : 'rmcol', 'val' : rmdate } ] );
                var wkstr = $sce.trustAsHtml( cont );
                return wkstr;
            };

            $scope.castgrid = {
                enableFiltering: false,
                enableSorting: true,
                treeRowHeaderAlwaysVisible: false,
                enableColumnResizing: true,
                enableGridMenu: false,
            };

            $scope.castgrid.columnDefs = [
                { name : '氏名', field: 'name',
                    headerCellClass: 'gridheader',
                    width: "16%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : 'フリガナ', field: 'namef',
                    headerCellClass: 'gridheader',
                    width: "16%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '登録番号', field: 'regno',
                    headerCellClass: 'gridheader',
                    width: "8%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : 'コンタクトステータス', field: 'status',
                    headerCellClass: 'gridheader',
                    width: "20%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '補足(連絡先)', field: 'memo',
                    headerCellClass: 'gridheader',
                    width: "16%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '補足(制限事項)', field: 'restdate',
                    headerCellClass: 'gridheader',
                    width: "16%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '', field: 'castid',
                    headerCellClass: 'gridheader nogridmenu',
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableSorting: false,
                    enableHiding: false,
                    cellTemplate: '<div class="gridcelbtn"><span ng-bind-html="grid.appScope.__getEditbtn(row.entity.rmdate, row.entity.castid)"></span></div>'
                },
            ];
            $http.get('/config/cast/listget')
            .success(function(data) {
                $scope.castgrid.data = data.json;
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

// -- EOF --
