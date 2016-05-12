// conkan_room_list.js --- 部屋一覧用 JS ---
var storage = sessionStorage;
var needreload = false;
$(document).ready(function(){
  $(document).scrollTop( storage.getItem( 'sctop' ) );
  storage.clear();
});
// モーダルダイアログ表示
$('#editRoom').on('show.bs.modal', function (event) {
  var roomid = $(event.relatedTarget).data('whatever');
  var content = $('#editRoomContent');
  needreload = false;
  $(content).load(roomid + '/ FORM');
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
$('#editRoom').on('hide.bs.modal', function (event) {
  storage.setItem( 'sctop', $(document).scrollTop() );
  if ( needreload ) {
    location.reload(true);
  }
} );
// 更新
$('#dobtn').click(function(event) {
  if (!$('#name').val()) {
      $('#valerr').text('部屋名は必須です');
      return false;
  }
  if (!$('#roomno').val()) {
      $('#valerr').text('部屋番号は必須です');
      return false;
  }
  if (!$('#type').val()) {
      $('#valerr').text('形式は必須です');
      return false;
  }
  var content = $('#editRoomContent');
  var data = $('#roomform').serializeArray();
  var roomid = $('#roomid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(roomid + '/edit/ FORM', data );
  needreload = true;
} );
// 削除
$('#dodel').click(function(event) {
  var content = $('#editRoomContent');
  var data = $('#roomform').serializeArray();
  var roomid = $('#roomid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(roomid + '/del/ FORM', data );
  needreload = true;
} );

// conkanRoomListモジュールの生成(グローバル変数)
var ConkanAppModule = angular.module('conkanRoomList',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

// 部屋リストコントローラ
ConkanAppModule.controller( 'roomListController',
    [ '$scope', '$sce', '$http', '$uibModal',
        function( $scope, $sce, $http, $uibModal ) {
            $scope.__getEditbtn = function( rmdate, roomid ) {
                var cont = uiGetEditbtn( rmdate, '#editRoom',
                        [ { 'key' : 'whatever', 'val' : roomid },
                          { 'key' : 'rmcol', 'val' : rmdate } ] );
                var wkstr = $sce.trustAsHtml( cont );
                return wkstr;
            };
            $scope.roomgrid = {
                enableFiltering: false,
                enableSorting: true,
                treeRowHeaderAlwaysVisible: false,
                enableColumnResizing: true,
                enableGridMenu: false,
            };

            $scope.roomgrid.columnDefs = [
                { name : '部屋名', field: 'name',
                    headerCellClass: 'gridheader',
                    width: "24%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '部屋番号', field: 'roomno',
                    headerCellClass: 'gridheader',
                    width: "16%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '形式', field: 'type',
                    headerCellClass: 'gridheader',
                    width: "24%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '面積', field: 'size',
                    headerCellClass: 'gridheader',
                    width: "16%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '', field: 'roomid',
                    headerCellClass: 'gridheader nogridmenu',
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableSorting: false,
                    enableHiding: false,
                    cellTemplate: '<div class="gridcelbtn"><span ng-bind-html="grid.appScope.__getEditbtn(row.entity.rmdate, row.entity.roomid)"></span></div>'
                },
            ];
            $http.get('/config/room/listget')
            .success(function(data) {
                $scope.roomgrid.data = data.json;
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
