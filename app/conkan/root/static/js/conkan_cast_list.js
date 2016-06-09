// conkan_cast_list.js --- 出演者一覧用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  // conkanCastListモジュールの生成
  var ConkanAppModule = angular.module('conkanCastList',
      ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

  // 出演者リストコントローラ
  ConkanAppModule.controller( 'castListController',
    [ '$scope', '$sce', '$http', '$uibModal',
      function( $scope, $sce, $http, $uibModal ) {
        $scope.getCastList = function() {
          $http.get('/config/cast/listget')
          .success(function(data) {
            if ( data.status === 'ok' ) {
              $scope.castgrid.data = data.json;
            }
            else {
              openDialog( data.status );
            }
          })
          .error( function() { httpfailDlg( $uibModal ); } );
        }

        $scope.getCastList();

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
                width: "12%",
                cellClass: function(grid, row)
                    { return uiGetCellCls(row.entity.rmdate); },
                enableHiding: false,
            },
            { name : '出演企画数', field: 'pgcnt',
                headerCellClass: 'gridheader',
                width: "8%",
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
                cellTemplate: '<div class="gridcelbtn">'
                          + '<button ng-if="row.entity.rmdate"'
                          +   'type="button" class="btn btn-xs">無効</button>'
                          + '<button ng-if="!row.entity.rmdate"'
                          +   'type="button" class="btn btn-xs btn-primary" '
                          +   'ng-click="grid.appScope.openAllCastForm'
                          +   '(row.entity.castid)">編集</button>'
            },
        ];

        // 出演者更新追加ダイアログ
        $scope.openAllCastForm = function( castid ) {
          $scope.castid = castid;
          $scope.applyBtnLbl = ( castid === 0 ) ? '追加' : '更新';
          $uibModal.open({
            templateUrl : 'T_cast_detail',
            controller  : 'allcastFormController',
            backdrop    : 'static',
            scope       : $scope,
            size        : 'lg',
            resolve     :
              { params: function() {
                return {
                  editCastId : castid,
                  editCastBtnLbl : ( castid === 0 ) ? '追加' : '更新',
                };
              }},
          });
        };
      }
    ]
  );
  
  // 出演者更新追加ダイアログコントローラ
  ConkanAppModule.controller( 'allcastFormController',
    [ '$scope', '$http', '$uibModal', '$uibModalInstance', 'params',
      function( $scope, $http, $uibModal, $uibModalInstance, params ) {
        // 初期値設定
        angular.element('#valerr').text('');
        $http({
          method  : 'GET',
          url     : '/config/cast/' + params.editCastId
        })
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.cast = {
              applyBtnLbl : params.editCastBtnLbl,
              castid    : data.json.castid,
              regno     : data.json.regno,
              name      : data.json.name,
              namef     : data.json.namef,
              status    : data.json.status,
              memo      : data.json.memo,
              restdate  : data.json.restdate,
              rmdate    : data.json.rmdate,
            };
            $scope.statlist = data.statlist;
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } )
        .finally( dialogResizeDrag);

        // 更新実施
        $scope.castDoApply = function() {
          // 二重クリック回避
          angular.element('#castapplybtn').attr('disabled', 'disabled');
          angular.element('#castdelbtn').attr('disabled', 'disabled');
          // バリデーション
          //    現在なし
          // 実行
          doJsonPost( $http, '/config/cast/' + $scope.cast.castid + '/edit',
                      $.param($scope.cast), $uibModalInstance, $uibModal,
                      function() { $scope.getCastList(); } );
        };
        // 削除実施
        $scope.castDoDel = function() {
          // 二重クリック回避
          angular.element('#castapplybtn').attr('disabled', 'disabled');
          angular.element('#castdelbtn').attr('disabled', 'disabled');
          doJsonPost( $http, '/config/cast/' + $scope.cast.castid + '/del',
                      undefined, $uibModalInstance, $uibModal,
                      function() { $scope.getCastList(); } );
        };
      }
    ]
  );
})();
// -- EOF --
