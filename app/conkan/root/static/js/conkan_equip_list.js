// conkan_equip_list.js --- 機材一覧用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  // conkanEquipListモジュールの生成
  var conkanAppModule = angular.module('conkanEquipList',
      ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

  // 機材リストコントローラ
  conkanAppModule.controller( 'equipListController',
    [ '$scope', '$sce', '$http', '$uibModal',
      function( $scope, $sce, $http, $uibModal ) {
        // 初期値設定
        $scope.getEquipList = function() {
          $http.get('/config/equip/listget')
          .success(function(data) {
            if ( data.status === 'ok' ) {
              $scope.equipgrid.data = data.json;
            }
            else {
              openDialog( data.status );
            }
          })
          .error( function() { httpfailDlg( $uibModal ); } );
        };
        $scope.getEquipList();

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
              cellTemplate: '<div class="gridcelbtn">'
                          + '<button ng-if="row.entity.rmdate"'
                          +   'type="button" class="btn btn-xs">無効</button>'
                          + '<button ng-if="!row.entity.rmdate"'
                          +   'type="button" class="btn btn-xs btn-primary" '
                          +   'ng-click="grid.appScope.openAllEquipForm'
                          +   '(row.entity.equipid)">編集</button>'
          },
        ];

        // 機材詳細更新追加ダイアログ
        $scope.openAllEquipForm = function( equipid ) {
          $scope.equipid = equipid;
          $scope.applyBtnLbl = ( equipid === 0 ) ? '追加' : '更新';
          $uibModal.open({
            templateUrl : 'T_equip_detail',
            controller  : 'allequipFormController',
            backdrop    : 'static',
            scope       : $scope,
            size        : 'lg',
            resolve     :
              { params: function() {
                return {
                  editEquipId : equipid,
                  editEquipBtnLbl : ( equipid === 0 ) ? '追加' : '更新',
                };
              }},
          });
        };
      }
    ]
  );
  
  // 機材詳細更新追加ダイアログコントローラ
  conkanAppModule.controller( 'allequipFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance', 'params',
      function( $scope, $http, $uibModal, $uibModalInstance, params ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $http({
          method  : 'GET',
          url     : '/config/equip/' + params.editEquipId
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.equip = {
              applyBtnLbl : params.editEquipBtnLbl,
              equipid : data.json.equipid,
              name    : data.json.name,
              equipno : data.json.equipno,
              spec    : data.json.spec,
              comment : data.json.comment,
              rmdate  : data.json.rmdate,
            };
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } )
        .finally( dialogResizeDrag);

        // 更新実施
        $scope.equipDoApply = function() {
          // 二重クリック回避
          angular.element('#equipapplybtn').attr('disabled', 'disabled');
          angular.element('#equipdelbtn').attr('disabled', 'disabled');
          // バリデーション
          //    現在なし
          // 実行
          doJsonPost( $http, '/config/equip/' + $scope.equip.equipid + '/edit',
                      $.param($scope.equip), $uibModalInstance, $uibModal,
                      function() { $scope.getEquipList(); } );
        };
        // 削除実施
        $scope.equipDoDel = function() {
          // 二重クリック回避
          angular.element('#equipapplybtn').attr('disabled', 'disabled');
          angular.element('#equipdelbtn').attr('disabled', 'disabled');
          doJsonPost( $http, '/config/equip/' + $scope.equip.equipid + '/del',
                      undefined, $uibModalInstance, $uibModal,
                      function() { $scope.getEquipList(); } );
        };
      }
    ]
  );
})();
// -- EOF --
