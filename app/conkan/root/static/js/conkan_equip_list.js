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

        $scope.__getEquipname = function( equipid, name ) {
          var cont = '<a href="' + equipid + '">' + name + '</a>';
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
          { name : '名称', field: 'equipid',
                headerCellClass: 'gridheader',
                cellClass: 'ui-grid-vcenter',
                width: "30%",
                enableHiding: false,
                cellTemplate: '<div ng-bind-html="grid.appScope.__getEquipname'
                        + '(row.entity.equipid, row.entity.name)"></div>',
          },
          { name : '機材番号', field: 'equipno',
              headerCellClass: 'gridheader',
              cellClass: function(grid, row)
                  { return uiGetCellCls(row.entity.rmdate); },
              enableHiding: false,
          },
          { name : '配置場所', field: 'room',
              headerCellClass: 'gridheader',
              width: "24%",
              cellClass: function(grid, row)
                  { return uiGetCellCls(row.entity.rmdate); },
              enableHiding: false,
          },
              // 配置場所未指定の場合、決定機材にしている企画の数
              // 配置場所指定の場合、その場所を実施場所にしている企画数
          { name : '使用企画数', field: 'progcnt',
              headerCellClass: 'gridheader',
              cellClass: function(grid, row)
                  { return uiGetCellCls(row.entity.rmdate); },
              enableHiding: false,
          },
          { name : '仕様', field: 'spec',
              headerCellClass: 'gridheader',
              width: "24%",
              cellClass: function(grid, row)
                  { return uiGetCellCls(row.entity.rmdate); },
              enableHiding: false,
          },
        ];
        // 機材一覧取得
        $scope.getEquipList = function() {
          $http( {
            method  : 'GET',
            headers : { 'If-Modifired-Since' : (new Date(0)).toUTCString() },
            url     : uriprefix + '/config/equip/listget'
          } )
          .success(function(data) {
            if ( data.status === 'ok' ) {
              $scope.equipgrid.data = data.json;
            }
            else {
              openDialog( data.status, data.json, $uibModal );
            }
          })
          .error( function() { httpfailDlg( $uibModal ); } );
        };

        if ( location.toString().split('/').pop() == 'list' ) {
            $scope.getEquipList();
        }

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
        // 選択肢取得
        $http.get(uriprefix + '/config/confget')
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.conf = ConfDataCnv( data, $scope.conf );
            // 指定なしの選択肢を追加
            $scope.conf.roomlist.unshift({'id': '', 'val': ''});
          }
          else {
            openDialog( data.status, data.json, $uibModal,
                        $uibModalInstance );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } );

        // 初期値設定
        angular.element('#valerr').text('');
        $http({
          method  : 'GET',
          url     : uriprefix + '/config/equip/' + params.editEquipId + '/edit'
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.equip = {
              applyBtnLbl : params.editEquipBtnLbl,
              equipid : data.json.equipid,
              name    : data.json.name,
              equipno : data.json.equipno,
              roomid  : data.json.roomid,
              spec    : data.json.spec,
              comment : data.json.comment,
              suppliers : data.json.suppliers,
              rmdate  : data.json.rmdate,
              usecnt  : data.json.usecnt,
            };
          }
          else {
            var finalcb;
            if ( location.toString().split('/').pop() == 'list' ) {
              finalcb = function() { $scope.getEquipList(); };
            }
            openDialog( data.status, data.json, $uibModal,
                        $uibModalInstance, finalcb );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } )
        .finally( dialogResizeDrag );

        // 更新実施
        $scope.equipDoApply = function() {
          // 二重クリック回避
          angular.element('#equipapplybtn').attr('disabled', 'disabled');
          angular.element('#equipdelbtn').attr('disabled', 'disabled');
          // バリデーション
          //    現在なし
          // 実行
          var finalcb;
          if ( location.toString().split('/').pop() == 'list' ) {
            finalcb = function() { $scope.getEquipList(); };
          }
          doJsonPost( $http, uriprefix + '/config/equip/' + $scope.equip.equipid + '/edit',
                      $.param($scope.equip), $uibModalInstance, $uibModal,
                      finalcb );
        };
        // 削除実施
        $scope.equipDoDel = function() {
          // 二重クリック回避
          angular.element('#equipapplybtn').attr('disabled', 'disabled');
          angular.element('#equipdelbtn').attr('disabled', 'disabled');
          var finalcb;
          if ( location.toString().split('/').pop() == 'list' ) {
            finalcb = function() { $scope.getEquipList(); };
          }
          else {
            finalcb = function(stat) {
                if ( stat === 'del' ) {
                    location = uriprefix + '/config/equip/list';
                }
            };
          }
          doJsonPost( $http, uriprefix + '/config/equip/' + $scope.equip.equipid + '/del',
                      undefined, $uibModalInstance, $uibModal, finalcb );
        };
      }
    ]
  );
})();
// -- EOF --
