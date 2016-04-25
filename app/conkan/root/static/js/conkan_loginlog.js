// conkanLoginLogモジュールの生成
var ConkanAppModule = angular.module('conkanLoginLog',
        ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

// スタッフリストコントローラ
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

            $http.get('/config/loginlogget')
            .success(function (data) {
                $scope.lloggrid.data = data.json;
            })
            .error(function(data) {
                var modalinstance = $uibModal.open(
                    { templateUrl : 'T_httpget_fail' }
                );
            });
        }
    ]
);

// -- EOF --