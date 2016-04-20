// 追加実施時、ボタンを無効にする
$('#doadd').click(function(event) {
  $('#doadd').addClass('disabled');
  $('#cancel').addClass('disabled');
  return true;
} );
// モーダルダイアログ addProgram 表示
$('#addProgram').on('show.bs.modal', function (event) {
  $('#jsoninputfile').val('');
} );
// モーダルダイアログ addProgram非表示
$('#addProgram').on('hide.bs.modal', function (event) {
  location.reload(true);
} );

// conkanProgListモジュールの生成(グローバル変数)
var ConkanAppModule = angular.module('conkanProgList',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

// スタッフリストコントローラ
ConkanAppModule.controller( 'progListController',
    [ '$scope', '$sce', '$http', '$uibModal',
        function( $scope, $sce, $http, $uibModal ) {
            $scope.__getPgid = function( regpgid, subno ) {
                var cont = regpgid + '(' + subno + ')';
                var wkstr = $sce.trustAsHtml( cont );
                return wkstr;
            };

            $scope.__getPgname = function( pgid, name ) {
                var cont = '<a href="' + pgid + '">' + name + '</a>';
                var wkstr = $sce.trustAsHtml( cont );
                return wkstr;
            };

            $scope.proggrid = {
                enableFiltering: false,
                enableSorting: true,
                treeRowHeaderAlwaysVisible: false,
                enableColumnResizing: true,
                enableGridMenu: false,
            };

            $scope.proggrid.columnDefs = [
                { name : '企画ID', field: 'regpgid',
                    headerCellClass: 'gridheader',
                    width: "10%",
                    cellClass: 'ui-grid-vcenter',
                    enableHiding: false,
                    cellTemplate: '<div ng-bind-html="grid.appScope.__getPgid(row.entity.regpgid, row.entity.subno)"></div>'
                },
                { name : '企画名称', field: 'pgid',
                    headerCellClass: 'gridheader',
                    cellClass: 'ui-grid-vcenter',
                    enableHiding: false,
                    cellTemplate: '<div ng-bind-html="grid.appScope.__getPgname(row.entity.pgid, row.entity.name)"></div>'
                },
                { name : '短縮名', field: 'sname',
                    headerCellClass: 'gridheader',
                    width: "15%",
                    cellClass: 'ui-grid-vcenter',
                    enableHiding: false,
                },
                { name : '担当スタッフ', field: 'staff',
                    headerCellClass: 'gridheader',
                    cellClass: 'ui-grid-vcenter',
                    width: "10%",
                    enableHiding: false,
                    visible: allprg,
                },
                { name : '実行ステータス', field: 'status',
                    headerCellClass: 'gridheader',
                    cellClass: 'ui-grid-vcenter',
                    width: "15%",
                    enableHiding: false,
                },
                { name : '最終更新日時', field: 'repdatetime',
                    headerCellClass: 'gridheader',
                    cellClass: 'ui-grid-vcenter',
                    width: "15%",
                    enableHiding: false,
                },
            ];
            $http.get('/program/listget')
            .success(function(data, status, headers, config) {
                $scope.proggrid.data = data.json;
            })
            .error(function(data, status, headers, config) {
                var modalinstance = $uibModal.open(
                    { templateUrl : 'T_httpget_fail' }
                );
                modalinstance.result.then( function() {} );
            });
        }
    ]
);

// -- EOF --
