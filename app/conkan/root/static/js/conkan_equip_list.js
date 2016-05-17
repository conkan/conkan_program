// conkan_equip_list.js --- 機材一覧用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  var storage = sessionStorage;
  var needreload = false;
  angular.element(document).ready(function(){
    angular.element(document).scrollTop( storage.getItem( 'sctop' ) );
    storage.clear();
  });
  // モーダルダイアログ表示
  angular.element('#editEquip').on('show.bs.modal', function (event) {
    var equipid = angular.element(event.relatedTarget).data('whatever');
    var content = angular.element('#editEquipContent');
    needreload = false;
    angular.element(content).load(equipid + '/ FORM');
    if ( angular.element(event.relatedTarget).data('rmcol') ) {
      angular.element('#dobtn').hide();
      angular.element('#dodel').hide();
    }
    else {
      angular.element('#dobtn').show();
      angular.element('#dodel').show();
    }
  } );
  // モーダルダイアログ非表示
  angular.element('#editEquip').on('hide.bs.modal', function (event) {
    storage.setItem( 'sctop', angular.element(document).scrollTop() );
    if ( needreload ) {
      location.reload(true);
    }
  } );
  // 更新
  angular.element('#dobtn').click(function(event) {
    if (!angular.element('#name').val()) {
      angular.element('#valerr').text('名称は必須です');
      return false;
    }
    if (!angular.element('#equipno').val()) {
      angular.element('#valerr').text('機材番号は必須です');
      return false;
    }
    var content = angular.element('#editEquipContent');
    var data = angular.element('#equipform').serializeArray();
    var equipid = angular.element('#equipid').val();
    angular.element('#dobtn').hide();
    angular.element('#dodel').hide();
    angular.element(content).load(equipid + '/edit/ FORM', data );
    needreload = true;
  } );
  // 削除
  angular.element('#dodel').click(function(event) {
    var content = angular.element('#editEquipContent');
    var data = angular.element('#equipform').serializeArray();
    var equipid = angular.element('#equipid').val();
    angular.element('#dobtn').hide();
    angular.element('#dodel').hide();
    angular.element(content).load(equipid + '/del/ FORM', data );
    needreload = true;
  } );

  // conkanEquipListモジュールの生成(グローバル変数)
  var conkanAppModule = angular.module('conkanEquipList',
      ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

  // 機材リストコントローラ
  conkanAppModule.controller( 'equipListController',
    [ '$scope', '$sce', '$http', '$uibModal',
      function( $scope, $sce, $http, $uibModal ) {
        $scope.__getEditbtn = function( rmdate, equipid ) {
          var cont = uiGetEditbtn( rmdate, '#editEquip',
                  [ { 'key' : 'whatever', 'val' : equipid },
                    { 'key' : 'rmcol', 'val' : rmdate } ] );
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
              cellTemplate: '<div class="gridcelbtn"><span ng-bind-html="grid.appScope.__getEditbtn(row.entity.rmdate, row.entity.equipid)"></span></div>'
          },
        ];
        $http.get('/config/equip/listget')
        .success(function(data) {
          $scope.equipgrid.data = data.json;
        })
        .error(function(data) {
          var modalinstance = $uibModal.open(
            { templateUrl : 'T_httpget_fail' }
          );
          modalinstance.result.then( function() {} );
        });
      }
    ]
  );
})();
// -- EOF --
