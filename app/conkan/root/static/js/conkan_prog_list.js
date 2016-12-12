// conkan_prog_list.js --- 企画一覧用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  // conkanProgListモジュールの生成
  var ConkanAppModule = angular.module('conkanProgList',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

  // ファイル選択ディレクティブ
  ConkanAppModule.directive("fileModel",
    ["$parse",
      function ($parse) {
        return {
          restrict: "A",
          link: function (scope, element, attrs) {
            var model = $parse(attrs.fileModel);
            element.bind("change", function () {
              scope.$apply(function () {
                model.assign(scope, element[0].files[0]);
              });
            });
          }
        };
      }
    ]
  );

  // 企画リストコントローラ
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
            width: "8%",
            cellClass: 'ui-grid-vcenter',
            enableHiding: false,
            cellTemplate: '<div ng-bind-html="grid.appScope.__getPgid'
                        + '(row.entity.regpgid, row.entity.subno)"></div>'
          },
          { name : '企画名称', field: 'pgid',
            headerCellClass: 'gridheader',
            cellClass: 'ui-grid-vcenter',
            enableHiding: false,
            cellTemplate: '<div ng-bind-html="grid.appScope.__getPgname'
                        + '(row.entity.pgid, row.entity.name)"></div>'
          },
          { name : '短縮名', field: 'sname',
            headerCellClass: 'gridheader',
            width: "12%",
            cellClass: 'ui-grid-vcenter',
            enableHiding: false,
          },
          { name : '担当スタッフ', field: 'staff',
            headerCellClass: 'gridheader',
            cellClass: 'ui-grid-vcenter',
            width: "12%",
            enableHiding: false,
            visible: allprg,
          },
          { name : '実行ステータス', field: 'status',
            headerCellClass: 'gridheader',
            cellClass: 'ui-grid-vcenter',
            width: "12%",
            enableHiding: false,
          },
          { name : '事前公開', field: 'contentpub',
            headerCellClass: 'gridheader',
            cellClass: 'ui-grid-vcenter',
            width: "8%",
            enableHiding: false,
          },
          { name : '最終更新日時', field: 'repdatetime',
            headerCellClass: 'gridheader',
            cellClass: 'ui-grid-vcenter',
            width: "15%",
            enableHiding: false,
          },
        ];
        var url = '/program/listget' + ( allprg ? '_a' : '_r' );
        $http.get(uriprefix + url)
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.proggrid.data = data.json;
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } );
        // 企画追加ダイアログ
        $scope.openRegPgAddForm = function( pgid ) {
          $uibModal.open({
            templateUrl : 'T_add_regprog',
            backdrop    : 'static',
            size        : 'lg',
          });
        };
      }
    ]
  );
})();  
// -- EOF --
