// conkan_room_list.js --- 部屋一覧用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  // conkanRoomListモジュールの生成
  var ConkanAppModule = angular.module('conkanRoomList',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

  // 部屋リストコントローラ
  ConkanAppModule.controller( 'roomListController',
    [ '$scope', '$sce', '$http', '$uibModal',
      function( $scope, $sce, $http, $uibModal ) {

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
                          + '<button ng-if="row.entity.rmdate"'
                          +   'type="button" class="btn btn-xs">無効</button>'
                          + '<button ng-if="!row.entity.rmdate"'
                          +   'type="button" class="btn btn-xs btn-primary" '
                          +   'ng-click="grid.appScope.openAllRoomForm'
                          +   '(row.entity.roomid)">編集</button>'
                          + '</div>'
          },
        ];
        
        // 部屋一覧取得
        $scope.getRoomList = function() {
          $http.get('/config/room/listget')
          .success(function(data) {
            if ( data.status === 'ok' ) {
              $scope.roomgrid.data = data.json;
            }
            else {
              openDialog( data.status );
            }
          })
          .error( function() { httpfailDlg( $uibModal ); } );
        };

        $scope.getRoomList();

        // 部屋更新追加ダイアログ
        $scope.openAllRoomForm = function( roomid ) {
          $uibModal.open({
            templateUrl : 'T_room_detail',
            controller  : 'allroomFormController',
            backdrop    : 'static',
            scope       : $scope,
            size        : 'lg',
            resolve     :
              { params: function() {
                return {
                  editRoomId : roomid,
                  editRoomBtnLbl : ( roomid === 0 ) ? '追加' : '更新',
                };
              }},
          });
        };
      }
    ]
  );

  // 部屋更新追加ダイアログコントローラ
  ConkanAppModule.controller( 'allroomFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance', 'params',
      function( $scope, $http, $uibModal, $uibModalInstance, params ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $http({
          method  : 'GET',
          url     : '/config/room/' + params.editRoomId
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.room = {
              applyBtnLbl : params.editRoomBtnLbl,
              roomid    : data.json.roomid,
              name      : data.json.name,
              roomno    : data.json.roomno,
              max       : data.json.max,
              type      : data.json.type,
              size      : data.json.size,
              useabletime : data.json.useabletime,
              tablecnt  : data.json.tablecnt,
              chaircnt  : data.json.chaircnt,
              equips    : data.json.equips,
              net       : data.json.net,
              comment   : data.json.comment,
            };
            $scope.netlist = [
                { id : 'NONE', val : '無' },
                { id : 'W',    val : '無線' },
                { id : 'E',    val : '有線' },
            ];
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } )
        .finally( dialogResizeDrag );

        // 更新実施
        $scope.roomDoApply = function() {
          // 二重クリック回避
          angular.element('#roomapplybtn').attr('disabled', 'disabled');
          angular.element('#roomdelbtn').attr('disabled', 'disabled');
          // バリデーション
          //    現在なし
          // 実行
          doJsonPost( $http, '/config/room/' + $scope.room.roomid + '/edit',
                      $.param($scope.room), $uibModalInstance, $uibModal,
                      function() { $scope.getRoomList(); } );
        };
        // 削除実施
        $scope.roomDoDel = function() {
          // 二重クリック回避
          angular.element('#roomapplybtn').attr('disabled', 'disabled');
          angular.element('#roomdelbtn').attr('disabled', 'disabled');
          doJsonPost( $http, '/config/room/' + $scope.room.roomid + '/del',
                      undefined, $uibModalInstance, $uibModal,
                      function() { $scope.getRoomList(); } );
        };
      }
    ]
  );
})();  
// -- EOF --
