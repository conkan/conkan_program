var storage = sessionStorage;
$(document).ready(function(){
  $(document).scrollTop( storage.getItem( 'sctop' ) );
  storage.clear();
});
// モーダルダイアログ表示
$('#editEquip').on('show.bs.modal', function (event) {
  var equipid = $(event.relatedTarget).data('whatever');
  var content = $('#editEquipContent');
  $(content).load(equipid + '/ FORM');
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
$('#editEquip').on('hide.bs.modal', function (event) {
  storage.setItem( 'sctop', $(document).scrollTop() );
  location.reload(true);
} );
// 更新
$('#dobtn').click(function(event) {
  if (!$('#name').val()) {
      $('#valerr').text('名称は必須です');
      return false;
  }
  if (!$('#equipno').val()) {
      $('#valerr').text('機材番号は必須です');
      return false;
  }
  var content = $('#editEquipContent');
  var data = $('#equipform').serializeArray();
  var equipid = $('#equipid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(equipid + '/edit/ FORM', data );
} );
// 削除
$('#dodel').click(function(event) {
  var content = $('#editEquipContent');
  var data = $('#equipform').serializeArray();
  var equipid = $('#equipid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(equipid + '/del/ FORM', data );
} );

// conkanEquipListモジュールの生成(グローバル変数)
var ConkanAppModule = angular.module('conkanEquipList',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

// 機材リストコントローラ
ConkanAppModule.controller( 'equipListController',
    [ '$scope', '$sce', '$http', '$uibModal',
        function( $scope, $sce, $http, $uibModal ) {
            $scope.__getEditbtn = function( rmdate, equipid ) {
                var cont = uiGetEditbtn( rmdate, '#editEquip',
                        [ { 'key' : 'whatever', 'val' : equipid },
                          { 'key' : 'rmcol', 'val' : rmdate } ] );
                var wkstr = $sce.trustAsHtml( cont );
                return wkstr;
            };
            $scope.equipgrid = {
                enableFiltering: false,
                enableSorting: true,
                treeRowHeaderAlwaysVisible: false,
                enableColumnResizing: true,
                enableGridMenu: false,
            };

            $scope.equipgrid.columnDefs = [
                { name : '名称', field: 'name',
                    headerCellClass: 'gridheader',
                    width: "32%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '機材番号', field: 'equipno',
                    headerCellClass: 'gridheader',
                    width: "24%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '仕様', field: 'spec',
                    headerCellClass: 'gridheader',
                    width: "32%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '', field: 'equipid',
                    headerCellClass: 'gridheader nogridmenu',
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableSorting: false,
                    enableHiding: false,
                    cellTemplate: '<div class="gridcelbtn"><span ng-bind-html="grid.appScope.__getEditbtn(row.entity.rmdate, row.entity.equipid)"></span></div>'
                },
            ];
            $http.get('/config/equip/listget')
            .success(function(data, status, headers, config) {
                $scope.equipgrid.data = data.json;
            })
            .error(function(data, status, headers, config) {
                var modalinstance = $uibModal.open(
                    { templateUrl : 'T_httpget_fail' }
                );
                modalinstance.result.then( function() {} );
            });
        }
    ]
);

// -- EOF --
