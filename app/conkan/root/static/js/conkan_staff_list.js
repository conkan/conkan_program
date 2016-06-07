// conkan_staff_list.js --- スタッフ一覧用 JS ---
/*esLint-env jquery, prototypejs */
(function() {
  var storage = sessionStorage;
  var needreload = false;
  angular.element(document).ready(function(){
    angular.element(document).scrollTop( storage.getItem( 'sctop' ) );
    storage.clear();
  });

  angular.element('#editStaff').on('show.bs.modal', function (event) {
    var staffid = angular.element(event.relatedTarget).data('whatever');
    var role = angular.element(event.relatedTarget).data('whatrole');
    var content = angular.element('#editStaffContent');
    needreload = false;
    angular.element(content).load(staffid + '/ FORM', '', function() {
      angular.element('#' + role).prop('selected', true);
    });
    angular.element('#dobtn').show();
    angular.element('#dodel').show();
  });

  angular.element('#editStaff').on('hide.bs.modal', function (event) {
    storage.setItem( 'sctop', angular.element(document).scrollTop() );
    if ( needreload ) {
      location.reload(true);
    }
  });

  angular.element('#dobtn').click(function(event) {
    if (!angular.element('#account').val()) {
      angular.element('#valerr').text('アカウントは必須です');
      return;
    }
    if ( angular.element('#passwd').val() ) {
      if ( angular.element('#passwd').val()
             != angular.element('#passwd2').val() ) {
        angular.element('#valerr').text(
          'パスワードとパスワード(確認)が一致しません');
        return;
      }
    }
    var content = angular.element('#editStaffContent');
    var data = angular.element('#profform').serializeArray();
    var staffid = angular.element('#staffid').val();
    angular.element('#dobtn').hide();
    angular.element('#dodel').hide();
    angular.element(content).load(staffid + '/edit/ FORM', data );
    needreload = true;
  });

  angular.element('#dodel').click(function(event) {
    var content = angular.element('#editStaffContent');
    var data = angular.element('#profform').serializeArray();
    var staffid = angular.element('#staffid').val();
    angular.element('#dobtn').hide();
    angular.element('#dodel').hide();
    angular.element(content).load(staffid + '/del/ FORM', data );
    needreload = true;
  });

  // conkanStaffListモジュールの生成
  var ConkanAppModule = angular.module('conkanStaffList',
    ['ui.grid', 'ui.grid.resizeColumns', 'ui.bootstrap'] );

  // スタッフリストコントローラ
  ConkanAppModule.controller( 'staffListController',
    [ '$scope', '$sce', '$http', '$uibModal',
      function( $scope, $sce, $http, $uibModal ) {
        $scope.__getRoll = function( role ) {
          var cont;
          switch (role) {
          case 'NORM':
            cont = '企画スタッフ';
            break;
          case 'PG':
            cont = '企画管理スタッフ';
            break;
          case 'ROOT':
            cont = 'システム管理者';
            break;
          }
          var wkstr = $sce.trustAsHtml( cont );
          return wkstr;
        };

        $scope.__getEditbtn = function( rmdate, staffid, role ) {
          var cont = uiGetEditbtn( rmdate, '#editStaff',
                    [ { 'key' : 'whatever', 'val' : staffid },
                      { 'key' : 'whatrole', 'val' : role } ] );
          var wkstr = $sce.trustAsHtml( cont );
          return wkstr;
        };

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
            cellTemplate: '<div ng-bind-html="grid.appScope.__getRoll'
                        + '(row.entity.role)"></div>'
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
                        +   '<span ng-bind-html="grid.appScope.__getEditbtn'
                        +     '(row.entity.rmdate, row.entity.staffid, '
                        +      'row.entity.role)">'
                        + '</span></div>'
          },
        ];
        $http.get('/config/staff/listget')
        .success(function(data) {
          if ( data.status === 'ok' ) {
            $scope.staffgrid.data = data.json;
          }
          else {
            openDialog( data.status );
          }
        })
        .error( function() { httpfailDlg( $uibModal ); } );
      }
    ]
  );
})();  
// -- EOF --
