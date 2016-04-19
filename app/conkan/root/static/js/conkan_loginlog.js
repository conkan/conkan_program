var storage = sessionStorage;
$(document).ready(function(){
  $(document).scrollTop( storage.getItem( 'sctop' ) );
  storage.clear();
});

// conkanLoginLogモジュールの生成
var ConkanAppModule = angular.module('conkanLoginLog',
        ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

// スタッフリストコントローラ
ConkanAppModule.controller( 'loginLogController',
    [ '$scope', '$http',
        function( $scope, $http ) {
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
            $scope.lloggrid.onRegisterApi = function (gridApi) {
                $scope.gridApi = gridApi;
            }

            $http.get('/config/loginlogget').success(function (data) {
                $scope.lloggrid.data = data.json;
            });
        }
    ]
);

// -- EOF --
