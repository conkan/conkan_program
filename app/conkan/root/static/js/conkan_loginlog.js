// conkan_loginlog.js --- ログイン履歴用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  // conkanLoginLogモジュールの生成
  var ConkanAppModule = angular.module('conkanLoginLog',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

  // ログイン履歴コントローラ
  ConkanAppModule.controller( 'loginLogController',
    [ '$scope', '$http', '$uibModal',
      function( $scope, $http, $uibModal ) {
        $scope.lloggrid = {
          enableFiltering: false,
          enableSorting: true,
          treeRowHeaderAlwaysVisible: false,
          enableColumnResizing: true,
          enableGridMenu: false,
          paginationPageSize: 25,
        };
        $scope.lloggrid.columnDefs = [
          { name : 'スタッフ名', field: 'staffname',
            headerCellClass: 'gridheader',
            width: '40%',
          },
          { name : 'login日時', field: 'login_date',
            headerCellClass: 'gridheader',
            width: '60%',
          },
        ];

        $http.get(uriprefix + '/config/loginlogget')
        .success(function (data) {
          if ( data.status === 'ok' ) {
            $scope.lloggrid.data = data.json;
          }
          else {
            openDialog( data.status, data.json, $uibModal );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } );
      }
    ]
  );
})();
// -- EOF --
