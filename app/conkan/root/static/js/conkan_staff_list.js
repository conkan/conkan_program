// conkan_staff_list.js --- スタッフ一覧用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  // conkanProfileモジュールの取得(conkan_profile.jsで生成)
  var ConkanAppModule = angular.module('conkanProfile');

  // スタッフリストコントローラ
  ConkanAppModule.controller( 'staffListController',
    [ '$scope', '$sce', '$http', '$uibModal',
      function( $scope, $sce, $http, $uibModal ) {
        $scope.getStaffList = function() {
          $http( {
            method  : 'GET',
            headers : { 'If-Modifired-Since' : (new Date(0)).toUTCString() },
            url     : uriprefix + '/config/staff/listget'
          } )
          .success(function(data) {
            if ( data.status === 'ok' ) {
              $scope.staffgrid.data = data.json;
            }
            else {
              openDialog( data.status );
            }
          })
          .error( function() { httpfailDlg( $uibModal ); } );
        };
        $scope.$on('PrfRelEvent', function( ev, dt ) {
          $scope.getStaffList();
        });

        $scope.staffgrid = {
          enableFiltering: false,
          enableSorting: true,
          treeRowHeaderAlwaysVisible: false,
          enableColumnResizing: true,
          enableGridMenu: false,
        };

        $scope.staffgrid.columnDefs = [
          { name : '名前', field: 'name',
            headerCellClass: 'gridheader',
            width: "23%",
            cellClass: function(grid, row) {
              return uiGetCellCls(row.entity.rmdate);
            },
            enableHiding: false,
          },
          { name : '役割', field: 'role',
            headerCellClass: 'gridheader',
            width: "23%",
            cellClass: function(grid, row) {
              return uiGetCellCls(row.entity.rmdate);
            },
            enableHiding: false,
            cellTemplate: '<div ng-bind-html="'
                        + 'grid.appScope.__getRole(row.entity.role)"></div>'
          },
          { name : '担当名', field: 'tname',
            headerCellClass: 'gridheader',
            width: "23%",
            cellClass: function(grid, row) {
              return uiGetCellCls(row.entity.rmdate);
            },
            enableHiding: false,
          },
          { name : '担当企画数', field: 'pgcnt',
            headerCellClass: 'gridheader',
            width: "8%",
            cellClass: function(grid, row) {
              return uiGetCellCls(row.entity.rmdate);
            },
            enableHiding: false,
          },
          { name : '最終ログイン日時', field: 'llogin',
            headerCellClass: 'gridheader',
            width: "15%",
            cellClass: function(grid, row) {
              return uiGetCellCls(row.entity.rmdate);
            },
            enableHiding: false,
          },
          { name : '', field: 'staffid',
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
                          +   'ng-click="grid.appScope.openProfForm'
                          +   '(row.entity.staffid)">編集</button>'
                          + '</div>'
          },
        ];
        $scope.getStaffList();
      }
    ]
  );
})();  
// -- EOF --
