// conkan_staff_list.js --- スタッフ一覧用 JS ---
var storage = sessionStorage;
var needreload = false;
$(document).ready(function(){
  $(document).scrollTop( storage.getItem( 'sctop' ) );
  storage.clear();
});

$('#editStaff').on('show.bs.modal', function (event) {
  var staffid = $(event.relatedTarget).data('whatever');
  var role = $(event.relatedTarget).data('whatrole');
  var content = $('#editStaffContent');
  needreload = false;
  $(content).load(staffid + '/ FORM', '', function() {
      $('#' + role).prop('selected', true);
    }
  );
  $('#dobtn').show();
  $('#dodel').show();
} );

$('#editStaff').on('hide.bs.modal', function (event) {
  storage.setItem( 'sctop', $(document).scrollTop() );
  if ( needreload ) {
    location.reload(true);
  }
} );

$('#dobtn').click(function(event) {
  if (!$('#account').val()) {
      $('#valerr').text('アカウントは必須です');
      return;
  }
  if ( $('#passwd').val() ) {
      if ( $('#passwd').val() != $('#passwd2').val() ) {
          $('#valerr').text('パスワードとパスワード(確認)が一致しません');
          return;
      }
  }
  var content = $('#editStaffContent');
  var data = $('#profform').serializeArray();
  var staffid = $('#staffid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(staffid + '/edit/ FORM', data );
  needreload = true;
} );

$('#dodel').click(function(event) {
  var content = $('#editStaffContent');
  var data = $('#profform').serializeArray();
  var staffid = $('#staffid').val();
  $('#dobtn').hide();
  $('#dodel').hide();
  $(content).load(staffid + '/del/ FORM', data );
  needreload = true;
} );

// conkanStaffListモジュールの生成(グローバル変数)
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
            }

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
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '役割', field: 'role',
                    headerCellClass: 'gridheader',
                    width: "23%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                    cellTemplate: '<div ng-bind-html="grid.appScope.__getRoll(row.entity.role)"></div>'
                },
                { name : '担当名', field: 'tname',
                    headerCellClass: 'gridheader',
                    width: "23%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '最終ログイン日時', field: 'llogin',
                    headerCellClass: 'gridheader',
                    width: "23%",
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableHiding: false,
                },
                { name : '', field: 'staffid',
                    headerCellClass: 'gridheader nogridmenu',
                    cellClass: function(grid, row)
                        { return uiGetCellCls(row.entity.rmdate); },
                    enableSorting: false,
                    enableHiding: false,
                    cellTemplate: '<div class="gridcelbtn"><span ng-bind-html="grid.appScope.__getEditbtn(row.entity.rmdate, row.entity.staffid, row.entity.role)"></span></div>'
                },
            ];
            $http.get('/config/staff/listget')
            .success(function(data) {
                $scope.staffgrid.data = data.json;
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

// -- EOF --
