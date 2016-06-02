// conkan_room_list.js --- 部屋一覧用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  var storage = sessionStorage;
  var needreload = false;
  angular.element(document).ready(function(){
    angular.element(document).scrollTop( storage.getItem( 'sctop' ) );
    storage.clear();
  });
  // モーダルダイアログ表示
  angular.element('#editRoom').on('show.bs.modal', function (event) {
    var roomid = angular.element(event.relatedTarget).data('whatever');
    var content = angular.element('#editRoomContent');
    needreload = false;
    angular.element(content).load(roomid + '/ FORM');
    if ( angular.element(event.relatedTarget).data('rmcol') ) {
      angular.element('#dobtn').hide();
      angular.element('#dodel').hide();
    }
    else {
      angular.element('#dobtn').show();
      angular.element('#dodel').show();
    }
  } );
  // モーダルダイアログ非表示
  angular.element('#editRoom').on('hide.bs.modal', function (event) {
    storage.setItem( 'sctop', angular.element(document).scrollTop() );
    if ( needreload ) {
      location.reload(true);
    }
  } );
  // 更新
  angular.element('#dobtn').click(function(event) {
    if (!angular.element('#name').val()) {
      angular.element('#valerr').text('部屋名は必須です');
      return false;
    }
    if (!angular.element('#roomno').val()) {
      angular.element('#valerr').text('部屋番号は必須です');
      return false;
    }
    if (!angular.element('#type').val()) {
      angular.element('#valerr').text('形式は必須です');
      return false;
    }
    var content = angular.element('#editRoomContent');
    var data = angular.element('#roomform').serializeArray();
    var roomid = angular.element('#roomid').val();
    angular.element('#dobtn').hide();
    angular.element('#dodel').hide();
    angular.element(content).load(roomid + '/edit/ FORM', data );
    needreload = true;
  } );
  // 削除
  angular.element('#dodel').click(function(event) {
    var content = angular.element('#editRoomContent');
    var data = angular.element('#roomform').serializeArray();
    var roomid = angular.element('#roomid').val();
    angular.element('#dobtn').hide();
    angular.element('#dodel').hide();
    angular.element(content).load(roomid + '/del/ FORM', data );
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
            cellClass: function(grid, row) {
              return uiGetCellCls(row.entity.rmdate);
            },
            enableHiding: false,
          },
          { name : '部屋番号', field: 'roomno',
            headerCellClass: 'gridheader',
            width: "16%",
            cellClass: function(grid, row) {
              return uiGetCellCls(row.entity.rmdate);
            },
            enableHiding: false,
          },
          { name : '形式', field: 'type',
            headerCellClass: 'gridheader',
            width: "24%",
            cellClass: function(grid, row) {
              return uiGetCellCls(row.entity.rmdate);
            },
            enableHiding: false,
          },
          { name : '面積', field: 'size',
            headerCellClass: 'gridheader',
            width: "16%",
            cellClass: function(grid, row) {
              return uiGetCellCls(row.entity.rmdate);
            },
            enableHiding: false,
          },
          { name : '', field: 'roomid',
            headerCellClass: 'gridheader nogridmenu',
            cellClass: function(grid, row) {
              return uiGetCellCls(row.entity.rmdate);
            },
            enableSorting: false,
            enableHiding: false,
            cellTemplate: '<div class="gridcelbtn">'
                        +   '<span ng-bind-html="grid.appScope.__getEditbtn'
                        +     '(row.entity.rmdate, row.entity.roomid)"></span>'
                        + '</div>'
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
})();  
// -- EOF --
